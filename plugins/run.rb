#
# Run saved commands.
#
# How to construct commands from variables:
#
#    set run.prog.foobar "uname -s"
#
#    run prog foobar ==> "Linux"
#
# TODO:
#
#    set run.prog.bar.cmd = "bin/bar"
#    set run.prog.bar.repo = "git@github.com:librato/myrepo.git"
#
#    run prog bar ==> Will checkout the repo and run bin/bar relative in
#                     the repo
#####

class Plugin::Run < Plugin
  def add_routes(rp, opts)
    rp.run do
      rp.route(/prog(ram|) (?<cmdname>.+)$/) do |act|
        c = Twke::Conf.get("run.prog.#{act.cmdname}")
        unless c
          act.say "No such program named #{act.cmdname}"
          next
        end

        if c && c.class == String
          run_command(act.cmdname, c, act)
        end
      end
    end
  end

private

  def run_command(cmdname, cmd, act)
    d = Twke::Spawner.popen(cmd)

    d.callback do |output|
      out = output.chomp
      act.say "Successfully ran #{cmdname}"
      act.paste output if out.length > 0
    end

    d.errback do |output|
      out = output.chomp
      act.say "Failed to run #{cmdname}"
      act.paste output if out.length > 0
    end
  end
end
