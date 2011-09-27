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
