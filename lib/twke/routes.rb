module Twke
  module Routes
    class RoutePrefix
      def initialize(str = nil)
        @levels = []
        @levels.push(str) if str
      end

      def route(str, *opts, &blk)
        @levels.push(str)
        Routes.add(@levels.join(" "), *opts, &blk)
        @levels.pop
      end

      def method_missing(name, &blk)
        @levels.push(name)
        yield
        @levels.pop
      end
    end

    class << self
      attr_accessor :conn

      def load(scamp)
        @@conn = scamp

        # TODO: Only load the configured plugins
        Plugin.plugins.each do |plgin|
          plgin.routes(RoutePrefix.new($options[:name]))
        end
      end

      def add(str, *opts, &blk)
        @@conn.behaviour do
          match(str, *opts, &blk)
        end
      end
    end
  end
end
