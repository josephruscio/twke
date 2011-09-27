# Fun with twke
#
class Plugin::Twiki < Plugin
  # Invoked to define routes.
  def add_routes(rp)
    rp.route 'bidi' do
      say 'bidi-bidi-bidi!'
    end

    rp.route 'version' do
      say "Twke version: #{Twke.version}"
    end
  end
end
