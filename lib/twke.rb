module Twke
  require 'scamp'
  require 'twke/plugin.rb'

  def self.plugin(plgn)
    puts "Registering plugin #{plgn.plugin_name}"
  end
end

Dir["#{File.dirname(__FILE__)}/../plugins/**/*.rb"].each { |plugin|
  load plugin
}
