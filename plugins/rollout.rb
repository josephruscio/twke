require 'redis'
require 'rollout'

require 'pry'

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

    # initialize things
    rollout!

    rp.rollout do

      rollouts = [{prefix: "", rollout: @rollout}]
      if @rollout_staging
        rollouts << {prefix: "staging ", rollout: @rollout_staging}
      end

      rollouts.each do |conf|

        # Query the current status of a feature
        rp.route /#{conf[:prefix]}info (?<feature>.+)/ do |act|
          act.paste conf[:rollout].get(act.feature.to_sym).to_hash.to_s
        end

        # Activate/Deactivate groups
        rp.route /#{conf[:prefix]}activate_group (?<feature>.+) (?<group>.+)/ do |act|
          rollout_op(act){conf[:rollout].activate_group(act.feature.to_sym, act.group.to_sym)}
          act.paste conf[:rollout].get(act.feature.to_sym).to_hash.to_s
        end

        rp.route /#{conf[:prefix]}deactivate_group (?<feature>.+) (?<group>.+)/ do |act|
          rollout_op(act){conf[:rollout].deactivate_group(act.feature.to_sym, act.group.to_sym)}
          act.paste conf[:rollout].get(act.feature.to_sym).to_hash.to_s
        end

        # Activate/Deactivate users
        rp.route /#{conf[:prefix]}activate_user (?<feature>.+) (?<user_id>.+)/ do |act|
          rollout_op(act){conf[:rollout].activate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
          act.paste conf[:rollout].get(act.feature.to_sym).to_hash.to_s
        end

        rp.route /#{conf[:prefix]}deactivate_user (?<feature>.+) (?<user_id>.+)/ do |act|
          rollout_op(act){conf[:rollout].deactivate_user(act.feature.to_sym, FakeUser.new(act.user_id))}
          act.paste conf[:rollout].get(act.feature.to_sym).to_hash.to_s
        end

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
    @rollout = make_rollout(Twke::Conf.get("rollout.zookeeper.hosts"))
    @rollout_staging = make_rollout(Twke::Conf.get("rollout.staging.zookeeper.hosts"))
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
