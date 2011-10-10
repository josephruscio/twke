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

  #
  # HTTP Helpers
  #

  def http(verb, url, opts = {}, &blk)
    header = {
      'accept' => 'application/json',
    }

    header['authorization'] = build_auth(opts[:user]) if opts[:user]
    opts.delete(:user)

    params = opts.merge(:head => header,
                        :connect_timeout => 5)

    cb = EventMachine::HttpRequest.new(url).send(verb, params)
    cb.errback do
      yield(nil, nil)
    end
    cb.callback do
      yield(cb.response_header, cb.response)
    end
  end

private

  #
  # XXX: em-http-request supports basic authentication, but it can
  # include a newline in the encoded authorization string. Since
  # heroku can't handle a wrapped authorization string, we must
  # generate it ourselves and guarantee there is no newline.
  #
  # We send it to em-http-request as if it were a custom auth string.
  #
  def build_auth(creds)
    creds = [creds[:name].chomp, creds[:password].chomp]
    "Basic " + Base64.encode64(creds.join(":")).gsub("\n", "")
  end

  def json_decode(value)
    Yajl::Parser.parse(value, :check_utf8 => false)
  end

  def json_encode(value)
    Yajl::Encoder.encode(value)
  end
end
