module Twke
  require 'bundler'

  Bundler.require

  $:.unshift File.join(File.dirname(__FILE__), 'twke')

  require 'conf'
  require 'routes'
  require 'plugin'
  require 'spawner'

  def self.version
    File.read(File.join(File.dirname(__FILE__), '../VERSION')).chomp
  end

  def self.plugin(plgn)
    puts "Registering plugin #{plgn.plugin_name}"
  end

  def self.start(scamp)
    Twke::Conf.load
    Twke::Routes.load(scamp)

    # XXX: Scamp needs an on_connect callback, fake one with a timer
    # here.
    # EM::Timer.new(5) do
    #   Twke::Routes.on_connect
    # end

    # Any rooms configured to join via the CLI will be done in the
    # on_connect CB.
    #
    scamp.connect!([]) do
      Twke::Routes.on_connect
    end
  end

  def self.shutdown
    exit 0
  end
end

Dir["#{File.dirname(__FILE__)}/../plugins/**/*.rb"].each { |plugin|
  load plugin
}
