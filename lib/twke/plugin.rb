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

  def http_get(url = nil, params = nil, headers = nil)
    http.get do |req|
      req.url(url)                if url
      req.params.update(params)   if params
      req.headers.update(headers) if headers
      yield req if block_given?
    end
  end

  def http_post(url = nil, body = nil, headers = nil)
    http.post do |req|
      req.url(url)                if url
      req.headers.update(headers) if headers
      req.body = body             if body
      yield req if block_given?
    end
  end

  def http_method(method, url = nil, body = nil, headers = nil)
    http.send(method) do |req|
      req.url(url)                if url
      req.headers.update(headers) if headers
      req.body = body             if body
      yield req if block_given?
    end
  end

  def faraday_options
    options = {
      :timeout => 6,
    }
  end

  def http(options = {})
    @http ||= begin
        Faraday.new(faraday_options.merge(options)) do |b|
          # TODO: Switch to EventMachine
          b.adapter :net_http
        end
    end
  end

  def json_decode(value)
    Yajl::Parser.parse(value, :check_utf8 => false)
  end

  def json_encode(value)
    Yajl::Encoder.encode(value)
  end
end
