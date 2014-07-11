require 'cgi'
require 'papertrail'

class Plugin::PaperTrail < Plugin
  #
  # Config variables:
  #
  #  papertrail.token
  #

  # Add routes
  def add_routes(rp, opts)
    rp.log do

      # Need to figure out how to avoid matching help in the main
      # regex
=begin
      rp.route 'help' do |act|
        help = <<-HELP
        I support searching your papertrail logs using the same syntax
        as the native Papertrail viewer e.g.:
          twke log "POST /v1/" AND " 500 "
        HELP

        act.paste help
      end
=end

      rp.route /(?<search>.+)/ do |act|
        formatted_events = ""

        begin
          papertrail(act.search) do |event|

            # We want the most recent events at the top
            formatted_events = event + "\n" + formatted_events
          end

          act.say "https://papertrailapp.com/events?q=#{CGI.escape(act.search)}"

          if "" == formatted_events
            act.paste "No matching events."
          else
            act.paste formatted_events
          end
        rescue => e
          act.say "Error: " + e.message
        end

      end
    end
  end

private

  def papertrail(search_string)
    token = Twke::Conf.get('papertrail.token')

    unless token
      raise "Papertrail token not configured!"
    end

    connection = Papertrail::Connection.new(:token => token)
    search_query = connection.query(search_string)
    events = search_query.search.events

    events.each do |event|
      yield event.to_s
    end
  end
end
