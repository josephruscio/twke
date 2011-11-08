module Twke
  class Job < EventMachine::Connection
    def initialize(params)
      @output = ""
      @opts = params
      @dfr = EM::DefaultDeferrable.new
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
      @output
    end

    def kill!
      # Kill the process group
      Process.kill("-TERM", self.pid)
    end

    def notify_readable
      begin
        result = @io.read_nonblock(1024)
        @output += result
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
    end
  end
end
