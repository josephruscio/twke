module Twke
  require 'scamp'

  require 'twke/routes.rb'
  require 'twke/plugin.rb'

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
