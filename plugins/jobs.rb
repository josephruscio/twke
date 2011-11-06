
class Plugin::Jobs < Plugin
  def add_routes(rp, opts)
    rp.jobs do
      rp.route 'list' do |act|
        jobs = Twke::JobManager.list
        if jobs.length == 0
          act.say "No active jobs"
          next
        end

        str = jobs.inject("") do |out, job|
          out += "ID: %d Cmd: '%s' Start time: %s\n" %
            [job.pid, job.command, job.start_time.to_s]
        end
        act.paste str
      end

      rp.route /kill (?<jobid>[0-9]+)$/ do |act|
        result = Twke::JobManager.killjob(act.jobid.to_i)
      end
    end
  end
end
