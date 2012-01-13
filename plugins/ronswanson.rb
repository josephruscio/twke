require 'hpricot'
require 'open-uri'

class Plugin::RonSwanson < Plugin

  def add_routes(rp, opts)
    rp.route /ron swanson/ do |act|
      act.say get_ron
    end
  end

  private

  def get_ron

    html = Hpricot(open('http://www.buzzfeed.com/jpmoore/the-15-best-ron-swanson-gifs'))
    img = html.search("a[@href]").search("img[@src*=anigif]")

    num = rand(14) - 1

    img[num].to_html.match(/http:.*?\.gif/)[0]

  end

end
