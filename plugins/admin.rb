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

      rp.route /join (?<room>.+)$/ do
        # Convert to an integer if possible
        roomname = room
        begin
          id = Integer(roomname)
        rescue
          id = rp.cmd { room_id_from_room_name(roomname) }
        end

        if !id
          say "No room by the name/ID: #{roomname}"
        else
          rp.cmd { join(id) }
        end
      end
    end
  end
end
