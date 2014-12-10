# encoding: utf-8
require 'redis'
require 'rollout'

# Rollout requires a "user object"
class FakeUser < Struct.new(:id); end

class Plugin::Rollout < Plugin
  #
  # Config variables:
  #
  # rollout.redis.host - The redis instance we should connect to. Defaults
  # to Redis.new i.e. localhost
  #

  # Add routes
  def add_routes(rp, opts)

    # ░░░░░░░▄▄▄▄█████████████▄▄▄░░░░░░░ #
    # ████▄▀████████▀▀▀▀▀▀████████▀▄████ #
    # ▀████░▀██████▄▄░░░░▄▄██████▀░████▀ #
    # ░███▀▀█▄▄░▀▀██████████▀▀░▄▄█▀▀███░ #
    # ░████▄▄▄▀▀█▄░░░▀▀▀▀░░░▄█▀▀▄▄▄████░ #
    # ░░██▄▄░▀▀████░██▄▄██░████▀▀░▄▄██░░ #
    # ░░░▀████▄▄▄██░██████░██▄▄▄████▀░░░ #
    # ░░██▄▀▀▀▀▀▀▀▀░░████░░▀▀▀▀▀▀▀▀▄██░░ #
    # ░░░██░░░░░░░░░░████░░░░░░░░░░██░░░ #
    # ░░░███▄▄░░░░▄█░████░█▄░░░░▄▄███░░░ #
    # ░░░███████░███░████░███░███████░░░ #
    # ░░░███████░███░████░███░███████░░░ #
    # ░░░███████░███░▀▀▀▀░███░███████░░░ #
    # ░░░███████░████████████░███████░░░ #
    # ░░░░▀█████░███░▄▄▄▄░███░█████▀░░░░ #
    # ░░░░░░░░▀▀░██▀▄████▄░██░▀▀░░░░░░░░ #
    # ░░░░░░░░░░░░▀░██████░▀░░░░░░░░░░░░ #
    # AUTOBOTS - ROLL OUT!               #
    rollout!

    rp.rollout do

      rollouts = {:production => @rollout, :staging => @rollout_staging}

      # Query the current status of a feature
      rp.route /info (?<feature>\w+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end

      # Activate/Deactivate groups
      rp.route /activate_group (?<feature>\w+) (?<group>[\w\.@]+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          rollout_op(act){ro.activate_group(act.feature.to_sym, act.group.to_sym)}
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end

      rp.route /deactivate_group (?<feature>\w+) (?<group>[\w\.@]+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          rollout_op(act){ro.deactivate_group(act.feature.to_sym, act.group.to_sym)}
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end

      # Activate/Deactivate users
      rp.route /activate_user (?<feature>\w+) (?<user_id>\d+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          rollout_op(act){ro.activate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end

      rp.route /deactivate_user (?<feature>\w+) (?<user_id>\d+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          rollout_op(act){ro.deactivate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end

      rp.route /percentage (?<feature>\w+) (?<percentage>\d+)\s*(?<env>\w+)?$/ do |act|
        with_rollout(act) do |ro|
          pct = Integer(act.percentage)
          if pct < 0 or pct > 100
            act.say "#{pct} is an invalid percentage"
            break
          end
          rollout_op(act){ ro.activate_percentage(act.feature.to_sym, pct) }
          act.paste ro.get(act.feature.to_sym).to_hash.to_s
        end
      end
    end

  end

private

  def with_rollout(act)
    env = (act.env == nil ? :production : act.env.to_sym)
    ro = @rollouts[env]
    if !ro
      act.paste "No rollout for environment #{env} found. Known environments: #{@rollouts.keys.inspect}"
      return
    end
    yield ro if block_given?
  end


  def rollout!
    if Twke::Conf.get("rollout.zookeeper.enabled")
      rollout_zk!
    else
      rollout_redis!
    end
  end

  def rollout_zk!
    @rollouts = {}
    @rollouts[:production] = make_rollout(Twke::Conf.get("rollout.zookeeper.hosts"))
    Twke::Conf.list("rollout.zookeeper.hosts").each do |suffix|
      @rollouts[suffix.to_sym] = make_rollout(Twke::Conf.get("rollout.zookeeper.hosts.#{suffix}"))
    end
  end

  # makes a new rollout and returns it
  def make_rollout(zk_hosts)
    zk_node = Twke::Conf.get("rollout.zookeeper.node") || "/rollout/users"

    if zk_hosts
      zookeeper = ZK.new(zk_hosts)
    else
      zookeeper = ZK.new
    end

    storage = ::Rollout::Zookeeper::Storage.new(zookeeper, zk_node)
    ::Rollout.new(storage)
  end

  def rollout_redis!
    redis_host = Twke::Conf.get("rollout.redis.host")

    if redis_host
      host, port = redis_host.split(':')
      @redis = Redis.new(:host => host, :port => port, :driver => :synchrony)
    else
      @redis = Redis.new
    end

    @rollout = ::Rollout.new(@redis)
  end

  def rollout_op(act)
    if yield
      act.say "Succeeded."
    else
      act.say "Failed!"
    end
  end

end
