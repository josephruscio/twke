class Plugin::Admin < Plugin
  # Invoked to define routes.
  def add_routes(rp)
    rp.admin do
      rp.route 'respawn' do
        say "Initiating respawn"
        EM::Timer.new(2) do
          Twke::shutdown
        end
      end
    end
  end
end
