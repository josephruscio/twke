# Given the name of a Ski/Snowboard Resort, replies with
# the 5 day snow potential report as predicted by http://www.snowforecast.com/
#
require 'nokogiri'
require 'open-uri'
require 'date'

class Plugin::SnowForecast < Plugin
  DefaultMountain = "HeavenlyMountainResort"

  Aliases = {
    'heavenly' => 'HeavenlyMountainResort',
    'telluride' => 'TellurideResort'
  }

  def forecast_xml(mtn)
    uri = "http://www.snowforecast.com/#{mtn}.xml"

    begin
      Nokogiri::XML(open(uri))
    rescue OpenURI::HTTPError
      nil
    end
  end

  def snowforecast(mtn)
    mtn = Aliases[mtn] if Aliases[mtn]

    xml = forecast_xml(mtn)

    return "Don't recognize that mountain." unless xml

    fc = ""

    xml.xpath('/weather/FORECAST').each do |day|
      d = DateTime.strptime(day.attributes['PROCESS_DATE'].to_s, '%m/%d/%Y')
      fc += DateTime::ABBR_DAYNAMES[d.wday]
      fc += ": " + day.xpath('SNOWPOT').text
      fc += "\n"
    end

    fc += "\n"
  end

  def add_routes(rp, opts)
    rp.route 'snow' do |act|
      act.say snowforecast(DefaultMountain)
    end

    rp.snow do
      rp.route /(?<mountain>\w+)/ do |act|
        act.say snowforecast(act.mountain)
      end
    end
  end
end
