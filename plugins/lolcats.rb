require 'can-has-lolcat'

class Plugin::Lolcats < Plugin
  def add_routes(rp, opts)
    rp.route 'meow' do |act|
      act.say Lolcat.can_haz
    end

    rp.route 'woof' do |act|
      act.say Lolcat.can_haz(:url, :dog)
    end
  end
end
