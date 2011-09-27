class Plugin
  class << self

    # Returns a short name for the plugin
    #
    def plugin_name
      @plugin_name ||= begin
        str = name.dup
        str.downcase!
        str.sub! /.*:/, ''
        str
      end
    end

    # Track all the available plugins
    #
    def plugins
      @plugins ||= []
    end

    # Invoked when adding routes. Pass in params here. Could expand
    # this to receive a number of events.
    #
    def routes(rp)
      plgin = new()

      if plgin.respond_to?(:add_routes)
        plgin.add_routes(rp)
      end
    end

    # Registers the current plugin with the system.
    #
    # Returns nothing.
    def inherited(plgn)
      Plugin.plugins << plgn
      Twke.plugin(plgn)
      super
    end
  end
end
