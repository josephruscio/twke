module Twke
  require 'scamp'

  $:.unshift File.join(File.dirname(__FILE__), 'twke')

  require 'conf'
  require 'routes'
  require 'plugin'

  def self.version
    File.read(File.join(File.dirname(__FILE__), '../VERSION')).chomp
  end

  def self.plugin(plgn)
    puts "Registering plugin #{plgn.plugin_name}"
  end

  def self.shutdown
    exit 0
  end
end

Dir["#{File.dirname(__FILE__)}/../plugins/**/*.rb"].each { |plugin|
  load plugin
}
