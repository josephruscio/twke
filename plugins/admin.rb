
class Plugin::Admin < Plugin
  #
  # Plugin methods
  #

  # Add routes
  def add_routes(rp, opts)
    rp.admin do
      rp.route 'respawn' do |act|
        act.say "Initiating respawn"
        EM::Timer.new(2) do
          Twke::shutdown
        end
      end

      rp.route /join (?<room>.+)$/ do |act|
        # Convert to an integer if possible
        id = get_room_id(rp, act.room)

        if !id
          act.say "No room by the name/ID: #{act.room}"
        else
          join_room(rp, id)

          # Save this room so we rejoin on startup
          rooms = (Twke::Conf.get('admin.join_rooms') || []) + [act.room]
          Twke::Conf.set('admin.join_rooms', rooms.sort.uniq)
        end
      end
    end
  end

  # On connection
  def on_connect(rp, opts)
    join_rooms(rp, opts)
  end

private

  #
  # Helper routines
  #
  def get_room_id(rp, room)
    begin
      id = Integer(room)
    rescue
      id = rp.cmd { room_id_from_room_name(room) }
    end
  end

  def join_room(rp, id)
    rp.cmd { join_and_stream(id) }
  end

  # Automatically join saved rooms on startup
  def join_rooms(rp, opts)
    rooms = Twke::Conf.get('admin.join_rooms') || []

    rooms << opts[:rooms] if opts[:rooms]

    rooms.sort.uniq.each do |room|
      id = get_room_id(rp, room)
      if id
        join_room(rp, id)
      else
        puts "ERROR: Unable to find autojoin room #{room}(id: #{id})"
      end
    end
  end
end
