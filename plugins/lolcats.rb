require 'can-has-lolcat'

class Plugin::Lolcats < Plugin
  # Invoked to define routes.
  def add_routes(rp, opts)
    rp.route 'meow' do
      say Lolcat.can_haz
    end
  end
end
