#
# Squirrel: Ship all the things!
#
# Provides a set of twke commands for continuous integration
# shipping. Translates shipping commands into CLI arguments that are
# passed to the configured ship command. It will track shipping status
# and output success/fail messages. Supports a 'staging' and
# 'production' environment for all commands.
#
# Commands are designed around the model of capistrano.
#
# Configuration:
#
#   squirrel.apps = ['app1', 'app2']
#
#     An array of applications that can be shipped.
#
#   squirrel.cmd = "/path/to/shipit.sh"
#
#     Program that is invoked to actually ship.
#
#   squirrel.environ = {"MYVAR" => "MYVAL"}
#
#     Hash of environment variables to pass to ship command.
#
# Help:
#  For a list of supported shipping commands, run `ship help`.
####

class Plugin::Squirrel < Plugin
  ShippedSquirrelPNG = 'https://img.skitch.com/20111130-j6bnpys1jgtm59ya63k33mgj1g.png'

  def initialize
    super
  end

  def add_routes(rp, opts)
    @shipping = {}

    rp.ship do
      # 'ship help'
      #
      rp.route "help" do |act|
        act.say "Ship commands:"
        act.paste <<EOS
I support the following ship commands:
  (Supported applications: #{get_apps.join(",")})
  (Environment always defaults to staging)

> ship <app> [staging|production]

  Ships 'master' to <app> with environment staging or production.

> ship <branch> to <app> [staging|production]

  Ships <branch> to <app> with environment staging or production.

> ship <branch> to <app> (staging|production) force

  Ships <branch> to <app> with environment staging or production.
  If <branch> is determined to be too old, this will force ship
  the branch.

> ship <app> environ [staging|production]

  Ships the latest app environment to <app> and restarts the app.

> ship <app> migrate [staging|production]

  Runs the migration for the specified <app> using the previously
  deployed code.

> ship <app> maintenance:(on|off) [staging|production]

  Put the application into maintenance mode (maintenance:on) or
  disable maintenance mode (maintenance:off) for <app>.

> ship <app> revision [staging|production]

  Show the deployed revision.
EOS
      end

      # 'ship <app> [staging|production]'
      #
      # Ship the 'master' branch for 'app'. Environment defaults to staging.
      #
      rp.route /(?<app>[^ ]+)(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        next if act.app == 'help' # This can match above

        shipit(act, 'deploy')
      end

      # 'ship <branch> to <app> [staging|production]'
      #
      # Ships the 'branch' for 'app'. Environment default to staging.
      #
      rp.route /(?<branch>[^ ]+)[ ]{1,}to[ ]{1,}(?<app>[^ ]+)(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        shipit(act, 'deploy', :branch => act.branch)
      end

      # 'ship <branch> to <app> (staging|production) force'
      #
      # Ships the 'branch' for 'app' to the particular
      # environment. This enables a "forced" ship meaning branch age
      # will not be checked.
      #
      rp.route /(?<branch>[^ ]+)[ ]{1,}to[ ]{1,}(?<app>[^ ]+)(?<env>([ ]{1,}(staging|production)))[ ]{1,}force$/ do |act|
        shipit(act, 'deploy', :branch => act.branch, :force => true)
      end

      # 'ship <app> environ [staging|production]'
      rp.route /(?<app>[^ ]+)[ ]{1,}environ(ment|)(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        shipit(act, 'environ')
      end

      # 'ship <app> migrate [staging|production]'
      rp.route /(?<app>[^ ]+)[ ]{1,}migrate(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        shipit(act, 'migrate')
      end

      # 'ship <app> maintenance:(on|off) [staging|production]'
      #
      # Turns maintenance mode on or off.
      #
      rp.route /(?<app>[^ ]+)[ ]{1,}maintenance:(?<mode>(on|off))(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        shipit(act, 'maintenance', :mode => act.mode.to_sym)
      end

      # 'ship <app> revision [staging|production]'
      #
      # Display the current revision.
      #
      rp.route /(?<app>[^ ]+)[ ]{1,}revision(?<env>([ ]{1,}(staging|production)){0,1})$/ do |act|
        shipit(act, 'revision')
      end
    end
  end

  def on_connect(rp, opts)
  end

private

  def get_apps
    Twke::Conf.get('squirrel.apps') || []
  end

  def shipping_key(app, env)
    "%s::%s" % [app, env]
  end

  def is_shipping?(app, env)
    @shipping[shipping_key(app, env)]
  end

  def start_shipping(app, env)
    @shipping[shipping_key(app, env)]
  end

  def finish_shipping(app, env)
    @shipping.delete(shipping_key(app, env))
  end

  #
  # This function invokes squirrel to run the deployment command.
  #
  def shipit(act, cmd, opts = {})
    apps = get_apps
    runcmd = Twke::Conf.get('squirrel.cmd')

    unless runcmd
      act.say "ERR: There is no shipping command set. Please set 'squirrel.cmd'"
      return
    end

    app = act.app.strip
    unless apps.include?(app)
      act.say "Sorry, I don't know the app name '%s'. I support: %s" %
        [app, apps.join(",")]
      return
    end

    env = act.env.chomp.strip
    env = 'staging' unless env.length > 0

    if is_shipping?(app, env)
      act.say "I can only ship to '#{app}::#{env}' one at a time! Check `jobs list` for pending jobs."
      return
    end

    params = {
      :application => app,
      :environment => env,
      :branch => opts[:branch] || 'master'
    }

    params[:force] = "" if opts[:force]

    if Twke::Conf.get('squirrel.max_age_secs')
      params[:max_age_secs] = Twke::Conf.get('squirrel.max_age_secs').to_i
    end

    # Check if there is additional environment variables.
    environ = Twke::Conf.get('squirrel.environ')
    if environ && !environ.respond_to?(:keys)
      act.say "ERR: Unknown type for squirrel.environ, must be a Hash"
      return
    end

    environ ||= {}

    args = params.map{ |p| "--#{p[0]} #{p[1]}" }.join(" ")
    extra_args = "#{opts[:mode]}" if cmd == "maintenance"

    start_shipping(app, env)
    d = Twke::JobManager.spawn("#{runcmd} #{args} #{cmd} #{extra_args}",
                               :environ => environ)
    d.callback do |job|
      secs = job.end_time - job.start_time

      case cmd
      when 'environ'
        act.say "Successfully refreshed environment for %s %s (%d seconds)" %
          [app, env, secs]
      when 'migrate'
        act.say "Successfully ran migrations for %s %s (%d seconds)" %
          [app, env, secs]
        act.paste job.output
      when 'maintenance'
        act.say "Successfully set maintenance mode to %s for %s %s (%d seconds)" %
          [opts[:mode].to_s, app, env, secs]
      when 'revision'
        lines = job.output.split("\n")
        rev = nil
        lines.each do |line|
          l = line.chomp
          if l =~ /^Current revision:/
            rev = l.split(" ").last
            break
          end
        end
        # TODO: Lookup revision in project
        if rev
          act.say "The app %s (%s) is currently at revision: %s" %
            [app, env, rev]
        else
          act.say "Can't find revision for app %s (%s)" %
            [app, env]
        end
      when 'deploy'
        act.say "Successfully shipped %s to %s %s (%d seconds)" %
          [params[:branch], app, env, secs]

        act.say ShippedSquirrelPNG if params[:environment] == 'production'
      else
        act.say "Successfully finished the command: %s for %s %s (%d seconds)" %
          [cmd, app, env, secs]
      end

      finish_shipping(app, env)
    end

    d.errback do |job|
      act.say "Failed to ship %s(%s):" % [app, env]
      act.paste job.output
      act.play 'trombone'
      finish_shipping(app, env)
    end

    jid = "[jid: #{d.jid}]"

    case cmd
    when 'deploy'
      act.say "Shipping branch/tag '%s' to %s (%s). %s" %
        [params[:branch], params[:application], params[:environment], jid]
    when 'environ'
      act.say "Refreshing application environment for %s (%s) %s" %
        [params[:application], params[:environment], jid]
    when 'migrate'
      act.say "Running migrations for %s (%s) %s" %
        [params[:application], params[:environment], jid]
    when 'revision'
      act.say "Checking revision for %s (%s) %s" %
        [params[:application], params[:environment], jid]
    when 'maintenance'
      act.say "%s maintenance mode for %s (%s) %s" %
        [opts[:mode] == :on ? "Enabling" : "Disabling",
         params[:application], params[:environment], jid]
    end

    act.say 'Fire in the hole!' if params[:environment] == 'production'

  end
end
