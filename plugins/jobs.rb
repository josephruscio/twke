
class Plugin::Jobs < Plugin
  def add_routes(rp, opts)
    rp.jobs do
      rp.route 'list' do |act|
        jobs = Twke::JobManager.list

        if jobs[:active].length == 0 && jobs[:finished].length == 0
          act.say "No active or finished jobs."
          next
        end

        str = ""
        if jobs[:active].length > 0
          str += "> Active Jobs:\n"
          jobs[:active].each do |job|
            str += "   ID: %d Cmd: '%s' Started: %s\n" %
              [job.pid, job.command, job.start_time.to_s]
          end
          str += "\n"
        end

        if jobs[:finished].length > 0
          str += "> Finished Jobs:\n"
          jobs[:finished].each do |job|
            str += "   ID: %d Cmd: '%s' Started: %s, Finished: %s\n" %
              [job.pid, job.command, job.start_time.to_s, job.end_time.to_s]
          end
        end

        act.paste str
      end

      rp.route /kill (?<jobid>[0-9]+)$/ do |act|
        job = Twke::JobManager.getjob(act.jobid.to_i)
        unless job
          act.say "No such job: #{act.jobid}"
          next
        end

        job.kill!
      end

      rp.route /tail (?<jobid>[0-9]+)$/ do |act|
        job = Twke::JobManager.getjob(act.jobid.to_i)
        unless job
          act.say "No such job: #{act.jobid}"
          next
        end

        out = job.output_tail
        act.paste out
      end

      rp.route /out(put|) (?<jobid>[0-9]+)$/ do |act|
        job = Twke::JobManager.getjob(act.jobid.to_i)
        unless job
          act.say "No such job: #{act.jobid}"
          next
        end

        out = job.output
        act.paste out
      end
    end
  end
end
