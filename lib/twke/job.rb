require 'fileutils'

module Twke
  class Job < EventMachine::Connection
    def initialize(params)
      @output = ""
      @opts = params
      @dfr = EM::DefaultDeferrable.new

      # All output is sent immediately to disk
      @out_filename = File.join(@opts[:tmpdir], "output.txt")
      @out_file = File.open(@out_filename, "w+")
      @out_file.sync = true
      @out_file.close_on_exec = true
      super
    end

    def pid
      @opts[:pid]
    end

    alias_method :jid, :pid

    def start_time
      @opts[:start_time]
    end

    def command
      @opts[:command]
    end

    def callback(&blk)
      @dfr.callback(&blk)
    end

    def errback(&blk)
      @dfr.errback(&blk)
    end

    def output
      File.read(@out_filename)
    end

    def kill!
      # Kill the process group
      Process.kill("-TERM", self.pid) rescue 0
    end

    def notify_readable
      begin
        result = @io.read_nonblock(1024)
        @out_file.write(result)
      rescue IO::WaitReadable
      rescue EOFError
        detach
      end
    end

    # Invoked when the process completes and is passed the status
    #
    def finished(status)
      if status.success?
        @dfr.succeed(self)
      else
        @dfr.fail(self)
      end
    end

    def unbind
      @io.close
      @out_file.fsync
      @out_file.close
      @out_file = nil
    end

    # Remove any temporary files
    def cleanup
      FileUtils.rm(@out_filename)

      # XXX: could be rm-rf, but be safe for now. Might have
      # problems if app creates files in $PWD
      FileUtils.rmdir(@opts[:tmpdir])
    end
  end
end
