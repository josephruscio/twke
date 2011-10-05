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

    def loaded_plugins
      @loaded_plugins ||= []
    end

    # Invoked to load this plugin. Will initialize and add to the
    # loaded plugins list.
    # TODO: Add initialization parameters here??
    def load_plugin
      Plugin.loaded_plugins << new()
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

  # Invoked to send an event to this plugin. Checks if plugins
  # responds to the event. All events take a routing prefix and
  # the CLI options.
  #
  def event(name, rp, opts)
    if self.respond_to?(name.to_sym)
      self.send(name.to_sym, rp, opts)
    end
  end

end
