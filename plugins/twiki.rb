# Fun with twke
#
class Plugin::Twiki < Plugin
  # Invoked to define routes.
  def add_routes(rp, opts)
    rp.route 'bidi' do |act|
      act.say 'bidi-bidi-bidi!'
    end

    rp.route 'version' do |act|
      act.say "Twke version: #{Twke.version}"
    end
  end
end
