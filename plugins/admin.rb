
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
    load_plugins(rp, opts)
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

  def load_plugins(rp, opts)
    plugins = Twke::Conf.list('admin.load_plugins')
    plugins.each do |plugin|
      repo = Twke::Conf.get("admin.load_plugins.#{plugin}.repo")
      path = Twke::Conf.get("admin.load_plugins.#{plugin}.path")

      unless repo || path
        puts "ERROR: Plugin %s does not have a repo or path set" % [plugin]
        next
      end

      if repo
        # Dir is a relative directory under the plugin to look for
        # plugins from.
        #
        dir = Twke::Conf.get("admin.load_plugins.#{plugin}.dir")
        dir = "plugins" unless dir

        clone_plugin_repo(repo, dir)
      else
        load_plugin_dir(path, ".")
      end
    end
  end

  def clone_plugin_repo(repo, dir)
    tmpdir = ENV['TMPDIR'] || "/tmp"
    rdir = "#{tmpdir}/repo_#{rand 999999}"

    d = Twke::JobManager.spawn("git clone -q #{repo} #{rdir}")
    d.errback do |job|
      puts "Failed to clone plugin repo #{repo} to #{rdir}:"
      puts job.output
    end

    d.callback do
      # Load plugins from the repo.
      #
      # TODO: Provide an after-checkout method to perform setup
      # steps for the repo (e.g., bundle install)
      #
      load_plugin_dir(rdir, dir)
    end
  end

  def load_plugin_dir(rdir, dir)
    Dir["#{rdir}/#{dir}/*.rb"].each do |plugin|
      puts "Loading plugin #{plugin}"
      EM::next_tick do
        load plugin
      end
    end
  end
end
