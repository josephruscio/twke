require 'open-uri'

class Plugin::PugMe < Plugin

  def add_routes(rp, opts)
    rp.pug do
      rp.route 'me' do |act|
        act.say get_pug
      end
    end
  end

  private

  def get_pug
    JSON(open("http://pugme.herokuapp.com/random").read).first[1]
  end

end
