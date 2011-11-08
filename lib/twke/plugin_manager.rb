# Track all plugins.
#
module Twke
  module PluginManager
    class << self

      # Invoked when a plugin file is loaded. Immediately registers
      # (instantiates) the plugin.
      #
      # TODO: Allow configurable plugin lists.
      #
      def register(klass)
        plgin = klass.new()

        if events.length > 0
          # We have to wait until this class is fully loaded before
          # we can invoke events on it, so wait until we return to EM.
          #
          EM.next_tick do
            # Invoke each registered event for the plugin
            events.each do |evt|
              invoke_event(plgin, evt)
            end
          end
        end

        loaded << plgin
      end

      #
      # Invoke the event type on all loaded plugins and save the event
      # for future plugins that register.
      #
      # TODO: Abstract arguments
      #
      def add_event(type, rp, opts)
        event = {
          :type => type,
          :rp => rp,
          :opts => opts
        }
        events << event

        # Invoke event for each plugin
        loaded.each do |plgin|
          invoke_event(plgin, event)
        end
      end

      def invoke_event(plgin, evt)
        plgin.event(evt[:type].to_sym, evt[:rp], evt[:opts])
      end

      def events
        @events ||= []
      end

      def loaded
        @loaded ||= []
      end
    end
  end
end
