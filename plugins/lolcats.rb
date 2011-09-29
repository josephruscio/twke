# Fun with twke
#
class Plugin::Lolcats < Plugin
  # Invoked to define routes.
  def add_routes(rp)
    rp.route 'meow' do
      lolcat = Lolcat.can_haz
      say lolcat
    end
  end
end
