require 'yaml'

#
# Simple configuration system.
#
# Variable names are dot-separated, similar to how sysctl(8) names
# work.
#
# For example, a 'heroku' module could prefix all variables with
# "heroku.":
#
#    heroku.sites.metrics-prod.giturl
#    heroku.sites.metrics-prod.token
#
# The conf system can also lookup all the sub-variables rooted at a
# single prefix. So for example, assume the following variables are
# also set:
#
#    heroku.sites.metrics-stg.giturl
#    heroku.sites.metrics-stg.token
#
#   A list command on 'heroku.sites' would return:
#          ['metrics-prod', 'metrics-stg']
#
######

module Twke
  module Conf
    class << self
      attr_accessor :conf

      def conf
        @conf ||= {}
      end

      # Everytime a value is modified the config DB is written
      def set(varname, value)
        if varname =~ /^\./ || varname =~ /\.$/ || varname.length == 0
          raise "Invalid variable name"
        end

        conf[varname.to_s] = value

        save
      end

      def get(varname)
        conf[varname.to_s]
      end

      def exists?(varname)
        conf.has_key?(varname)
      end

      #
      # This will return a list of the unique commands that begin with
      # the varpfx prefix assumed to be a sub-command prefix.
      #
      # For example, assume the following variables are set:
      #
      #    net.tcp.foobar => 1
      #    net.tcp.barbar => 2
      #
      # So:
      #   list('net.tcp') would return: ["barbar", "foobar"]
      #   list('net') would return: ["tcp"]
      #
      #   list('net.tc') would return: []
      #        Because there are no sub-commands with 'net.tc.' as
      #        their prefix
      #
      def list(varpfx)
        # Strip leading/trailing periods
        varpfx = varpfx[1, varpfx.length] if varpfx =~ /^\./
        varpfx = varpfx[0, varpfx.length - 1] if varpfx =~ /\.$/

        # XXX: Really need a tree structure to do this efficiently
        conf.keys.inject([]) do |ar, k|
          if k =~ /^#{varpfx}\./
            ar << k.gsub(/^#{varpfx}\./, '').split(".")[0]
          end
          ar
        end.sort.uniq
      end

      def load
        begin
          yml = YAML.load_file(config_file)
          @conf = yml
        rescue Errno::ENOENT => err
          @conf = {}
        rescue => err
          raise "Unknown error reading config file: #{err.message}"
        end
      end

      #
      # Files are saved atomically.
      #
      def save
        unless File.exist?(config_dir)
          FileUtils.mkdir_p(config_dir, :mode => 0700)
        end

        tmpfile = File.join(config_dir, "tmpconfig_#{rand 999999}")
        File.open(tmpfile, "w") do |f|
          YAML.dump(conf, f )
        end

        FileUtils.mv(tmpfile, config_file)
      end

      def config_dir
        File.join(ENV['HOME'], '.twke')
      end

      def config_file
        File.join(config_dir, 'config.yml')
      end
    end
  end
end
