module Twke
  class Job < EventMachine::Connection
    def initialize(params)
      @output = ""
      @dfr = params[:deferrable]
      @opts = params
      super
    end

    def pid
      @opts[:pid]
    end

    def start_time
      @opts[:start_time]
    end

    def command
      @opts[:command]
    end

    def kill!
      Process.kill("TERM", self.pid)
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
      return unless @dfr
      if status.success?
        @dfr.succeed(@output)
      else
        @dfr.fail(@output)
      end
    end

    def unbind
      @io.close
    end
  end
end
