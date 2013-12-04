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

    rp.rollout do

      # Query the current status of a feature
      rp.route /info (?<feature>.+)/ do |act|
        act.paste rollout.get(act.feature.to_sym).to_hash.to_s
      end

      # Activate/Deactivate groups
      rp.route /activate_group (?<feature>.+) (?<group>.+)/ do |act|
        rollout_op(act){rollout.activate_group(act.feature.to_sym, act.group.to_sym)}
      end

      rp.route /deactivate_group (?<feature>.+) (?<group>.+)/ do |act|
        rollout_op(act){rollout.deactivate_group(act.feature.to_sym, act.group.to_sym)}
      end

      # Activate/Deactivate users
      rp.route /activate_user (?<feature>.+) (?<user_id>.+)/ do |act|
        rollout_op(act){rollout.activate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
      end

      rp.route /deactivate_user (?<feature>.+) (?<user_id>.+)/ do |act|
        rollout_op(act){rollout.deactivate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
      end

      rp.route /percentage (?<feature>.+) (?<percentage>.+)/ do |act|
        rollout_op(act){ rollout.activate_percentage(act.feature.to_sym, Integer(act.percentage)) }
      end
    end

  end

private

  def rollout!
    if Twke::Conf.get("rollout.zookeeper.enabled")
      rollout_zk!
    else
      rollout_redis!
    end
  end

  def rollout_zk!
    zk_hosts = Twke::Conf.get("rollout.zookeeper.hosts")
    zk_node = Twke::Conf.get("rollout.zookeeper.node") || "/rollout/users"

    if zk_hosts
      zookeeper = ZK.new(zk_hosts)
    else
      zookeeper = ZK.new
    end

    storage = ::Rollout::Zookeeper::Storage.new(zookeeper, zk_node)
    @rollout = ::Rollout.new(storage)
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

  def rollout
    @rollout ||= rollout!
  end

  def rollout_op(act)
    if yield
      act.say "Succeeded."
    else
      act.say "Failed!"
    end
  end

end
