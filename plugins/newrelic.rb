require 'httpi'
require 'nokogiri'

class Plugin::Newrelic < Plugin

  def add_routes(rp, opts)

    rp.route 'newrelic' do |act|
      metrics = get_newrelic
      act.say "Here is how we do: #{metrics['Response Time']} at #{metrics['Throughput']} with an error rate of #{metrics['Error Rate']}. That gives us an Apdex score of #{metrics['Apdex']}."
    end

    rp.route /(?<action>start|stop|check) error watcher/ do |act|
      send("newrelic_#{act.action}", act)
    end

  end

  private

  def get_newrelic
    account_id                   = Twke::Conf.get('newrelic.account')
    application_id               = Twke::Conf.get('newrelic.application')
    api_key                      = Twke::Conf.get('newrelic.api-key')

    request                      = HTTPI::Request.new "https://api.newrelic.com/accounts/#{account_id}/applications/#{application_id}/threshold_values.xml"
    request.headers["x-api-key"] = api_key
    html                         = HTTPI.get(request).body
    xml                          = Nokogiri::XML.parse html

    metrics = {}
    ["Throughput", "Response Time", "Apdex", "Error Rate"].each do |measure|
      metrics[measure] = xml.at_css("threshold_value[name='#{measure}']")["formatted_metric_value"]
    end
    metrics
  end

  def newrelic_check act
    act.say "Error watcher is #{@error_watcher && @error_watcher.status}"
  end

  def newrelic_start act
    act.say "Starting error watcher"
    @error_watcher && Thread.kill(@error_watcher)
    Thread.abort_on_exception = true
    @error_watcher = Thread.new do
      told_em_at = 0
      loop do
        if told_em_at < Time.now.to_i - 1800
          measures = get_newrelic
          error_rate = measures["Error Rate"]
          response_time = measures["Response Time"]
          if error_rate.to_f > Twke::Conf.get('newrelic.threshold.error_rate') || response_time.to_i > Twke::Conf.get('newrelic.threshold.response_time')
            act.say "Sorry to interrupt but our error rate is at #{error_rate} and our response time is at #{response_time}. Do something!"
            told_em_at = Time.now.to_i
          end
        end
        sleep 300
      end
    end
  end

  def newrelic_stop act
    @error_watcher && Thread.kill(@error_watcher)
    act.say "Killed it!"
  end

end
