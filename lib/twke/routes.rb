module Twke
  module Routes
    class RoutePrefix
      def initialize(str = nil)
        @levels = []
        @levels.push(str) if str
      end

      def route(trigger, *opts, &blk)
        if trigger.class == Regexp
          pfx = prefix.length
          if prefix.length > 0
            trigger = Regexp.new("#{prefix} #{trigger.to_s}")
          end

          Routes.add(trigger, *opts, &blk)
        else
          @levels.push(trigger)
          Routes.add(prefix, *opts, &blk)
          @levels.pop
        end
      end

      # Run a raw command and the connection scope level
      def cmd(&blk)
        Routes.cmd(&blk)
      end

      def method_missing(name, &blk)
        @levels.push(name)
        yield
        @levels.pop
      end

    private

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
          match(trigger, *opts, &blk)
        end
      end

      # Run a raw command
      def cmd(&blk)
        @@conn.behaviour(&blk)
      end
    end
  end
end
