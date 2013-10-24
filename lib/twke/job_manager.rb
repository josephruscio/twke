require 'fileutils'

module Twke
  module JobManager
    MAX_FD_CLOSE = 1024

    # Watch the read end of the SIGCLD notication pipe
    class ProcessPipeWatch < EM::Connection
      def initialize(procwatch)
        @procwatch = procwatch
      end

      def notify_readable
        @procwatch.handle_process_exit
      rescue EOFError
        detach
      end

      def unbind
        @io.close
      end
    end

    class ProcessWatch
      # How long do we keep finished jobs around?
      FINISHED_JOB_WAIT_SECS = 1800

      def initialize
        # Active running jobs
        @active = {}

        # Finished queue -- entries are evicted after an hour
        @finished = {}

        rd, wr = IO::pipe

        rd.close_on_exec = true
        wr.close_on_exec = true

        @watched_pids_fd = {:rd => rd, :wr => wr}
      end

      def start
        conn = EM::watch(@watched_pids_fd[:rd], ProcessPipeWatch, self)
        conn.notify_readable = true

        EM::PeriodicTimer.new(300) do
          purge_finished_jobs
        end
      end

      def purge_finished_jobs
        now = Time.now
        @finished.delete_if do |pid, job|
          done = (now - job.end_time) > FINISHED_JOB_WAIT_SECS
          job.cleanup if done
          done
        end
      end

      # Watch the PID and notify the spawned job
      def watch_pid(pid, sj)
        @active[pid] = sj
      end

      def active_jobs
        @active.values.sort{|a, b| a.start_time <=> b.start_time }
      end

      def finished_jobs
        @finished.values.sort{|a, b| a.end_time <=> b.end_time }
      end

      def job(id)
        @active[id] || @finished[id]
      end

      def alert_exit
        # Don't handle signal, just wake up the reactor
        @watched_pids_fd[:wr].write_nonblock("1")
      end

      # Invoked when a SIGCLD occurs
      def handle_process_exit
        begin
          # Drain the pipe
          begin
            result = @watched_pids_fd[:rd].read_nonblock(1024)
          rescue IO::WaitReadable
            result = nil
          end
        end while result

        # Check all processes waiting.
        begin
          begin
            pid, status = Process.waitpid2(-1, Process::WNOHANG)
          rescue Errno::ECHILD => err
            pid = nil
          end

          if pid
            # If there is a callback, invoke it. The process may
            # not belong to us.
            #
            proc = @active.delete(pid)
            if proc
              proc.finished(status)
              @finished[proc.pid] = proc
            end
          end
        end while pid
      end
    end

    class << self

      def init
        return if @process_watcher

        @process_watcher = ProcessWatch.new
        @process_watcher.start

        trap("CHLD") do
          # Alert the process watcher that a process exited.
          @process_watcher.alert_exit
        end
      end

      def list
        # Return a list of the jobs
        jobs = { :active => [], :finished => [] }
        return jobs unless @process_watcher

        jobs[:active] = @process_watcher.active_jobs
        jobs[:finished] = @process_watcher.finished_jobs
        jobs
      end

      def getjob(jid)
        return nil unless @process_watcher

        @process_watcher.job(jid)
      end

      #
      # When invoked, will spawn the command in 'cmdstr' using
      # exec. Returns an EM:Deferrable and the success callback will
      # be invoked if the command succeeds or else the errback will be
      # invoked. Both callbacks are passed the program output.
      #
      def spawn(cmdstr, opts = {})
        self.init

        # All jobs have a temporary directory.
        tmproot = ENV['TMPDIR'] || "/tmp"
        jobtmpdir = File.join(tmproot, "jobs/job_#{rand 9999999}")

        FileUtils.mkdir_p(jobtmpdir)

        rd, wr = IO::pipe
        start_time = Time.now
        pid = fork do
          rd.close

          # Job control
          #
          Process.setpgid(Process.pid, Process.pid)

          # Reset signals
          trap("INT", "DEFAULT")
          trap("QUIT", "DEFAULT")
          trap("TSTP", "DEFAULT")
          trap("TTIN", "DEFAULT")
          trap("TTOU", "DEFAULT")
          trap("CHLD", "DEFAULT")

          # Fix lack of close-on-exec use
          3.upto(MAX_FD_CLOSE) do |fd|
            next if fd == wr.fileno

            begin
              f = IO.new(fd)
              f.close
            rescue
            end
          end

          # Tie stdout and stderr together
          $stdout.reopen wr
          $stderr.reopen wr

          # Set environs if specified
          opts[:environ].each_pair do |k, v|
            ENV[k] = v
          end if opts[:environ]

          dir = opts[:dir] || jobtmpdir

          Dir.chdir(dir) do
            ENV.each {|k, v| puts "#{k} = #{v}"}
            exec(cmdstr)
          end

          # Shouldn't get here unless the exec fails
          exit 127
        end

        wr.close
        rd.close_on_exec = true

        params = {
          :chdir => opts[:dir] || jobtmpdir,
          :tmpdir => jobtmpdir,
          :pid => pid,
          :command => cmdstr,
          :start_time => start_time,
        }

        d = EM::watch(rd, Job, params)
        d.notify_readable = true

        # Watch the process to notify when it completes
        @process_watcher.watch_pid(pid, d)

        return d
      end
    end
  end
end
