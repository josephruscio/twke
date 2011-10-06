module Twke
  module Routes
    class RoutePrefix
      def initialize(str = nil)
        @levels = []
        @levels.push(str) if str
      end

      def route(trigger, *opts, &blk)
        if trigger.class == Regexp
          if prefix.length > 0 && !no_prefix?(*opts)
            trigger = Regexp.new("#{prefix} #{trigger.to_s}")
          end

          Routes.add(trigger, *opts, &blk)
        else
          # Send trigger as a prefix
          self.send(trigger, *opts) do
            Routes.add(prefix, *opts, &blk)
          end
        end
      end

      # Run a raw command and the connection scope level
      def cmd(&blk)
        Routes.cmd(&blk)
      end

      def method_missing(name, *opts, &blk)
        if no_prefix?(*opts)
          # If they requested no prefix, save the current prefix
          # and execute the block starting with the current prefix
          save_levels = @levels.dup
          @levels = [name]
          yield
          @levels = save_levels
        else
          @levels.push(name)
          yield
          @levels.pop
        end
      end

    private

      def no_prefix?(options = {})
        options[:noprefix]
      end

      def prefix
        @levels.join(" ")
      end
    end

    class << self
      attr_accessor :conn

      def load(scamp)
        @@conn = scamp

        # TODO: Only load the configured plugins.
        # XXX: doesn't feel right to do this in routes...
        Plugin.plugins.each do |plgin|
          plgin.load_plugin
        end

        # Now ask all loaded plugins to add routes
        Plugin.loaded_plugins.each do |plgin|
          plgin.event(:add_routes, RoutePrefix.new($options[:name]), $options)
        end
      end

      # Invoked (in theory) after we're connected to campfire
      def on_connect
        Plugin.loaded_plugins.each do |plgin|
          plgin.event(:on_connect, RoutePrefix.new($options[:name]), $options)
        end
      end

      def add(trigger, *opts, &blk)
        cmd do
          match(trigger, *opts) do
            # This yields the action (ie, room) context to the
            # callback. All actions that could be done in the Scamp
            # 'match' context can be performed on the yielded
            # object. This lets you pass the context to an EM context
            # later.
            #

            yield(self)
          end
        end
      end

      # Run a raw command
      def cmd(&blk)
        @@conn.behaviour(&blk)
      end
    end
  end
end
