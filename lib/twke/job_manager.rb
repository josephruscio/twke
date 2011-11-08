module Twke
  module JobManager
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
      def initialize
        @procs = {}

        rd, wr = IO::pipe

        @watched_pids_fd = {:rd => rd, :wr => wr}
      end

      def start
        conn = EM::watch(@watched_pids_fd[:rd], ProcessPipeWatch, self)
        conn.notify_readable = true
      end

      # Watch the PID and notify the spawned job
      def watch_pid(pid, sj)
        @procs[pid] = sj
      end

      def jobs
        @procs.values
      end

      def job(id)
        @procs[id]
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
            proc = @procs.delete(pid)
            proc.finished(status) if proc
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
        return @process_watcher ? @process_watcher.jobs : []
      end

      def killjob(jid)
        return nil unless @process_watcher

        job = @process_watcher.job(jid)
        return nil unless job

        job.kill!
      end

      #
      # When invoked, will spawn the command in 'cmdstr' using
      # exec. Returns an EM:Deferrable and the success callback will
      # be invoked if the command succeeds or else the errback will be
      # invoked. Both callbacks are passed the program output.
      #
      def spawn(cmdstr, opts = {})
        self.init

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

          # Tie stdout and stderr together
          $stdout.reopen wr
          $stderr.reopen wr

          # Set environs if specified
          opts[:environ].each_pair do |k, v|
            ENV[k] = v
          end if opts[:environ]

          dir = opts[:dir] || ENV['PWD']

          Dir.chdir(dir) do
            exec(cmdstr)
          end

          # Shouldn't get here unless the exec fails
          exit 127
        end

        wr.close

        params = {
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
