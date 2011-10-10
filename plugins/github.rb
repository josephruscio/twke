class Plugin::Github < Plugin
  #
  # Plugin methods
  #

  #
  # Config variables:
  #
  #  github.user.name
  #  github.user.password
  #
  #

  # Add routes
  def add_routes(rp, opts)
    rp.github do
      rp.route /(pulls|pull|pullrequest|pullrequests) (?<user>.+) (?<repo>.+)$/ do |act|
        github(act, "repos/#{act.user}/#{act.repo}/pulls", :get) do |msg|
          if msg.length == 0
            act.say "No open pull requests for #{act.user}/#{act.repo}"
            break
          end

          act.say "Open pull requests for https://github.com/#{act.user}/#{act.repo}:"
          msg.each do |pr|
            # Lookup additional details
            github(act, "repos/#{act.user}/#{act.repo}/pulls/#{pr['number']}", :get) do |msg|
              act.say "[%s] %s%s%s%s" %
                [msg['user']['login'], msg['title'],
                 msg['mergeable'] ? " (mergeable)" : "",
                 msg['comments'] > 0 ? " (#{msg['comments']} comments)" : "",
                 " " + msg['html_url']]
            end
          end
        end
      end
    end
  end

private

  def github(act, cmd, verb)
    user = Twke::Conf.get('github.user.name')
    passwd = Twke::Conf.get('github.user.password')

    unless user && passwd
      act.say "Github plugin not configured!"
      return
    end

    url = "https://api.github.com/#{cmd}"

    user = {:name => "#{user}", :password => passwd}

    http(verb, url, :user => user) do |header, msg|
      unless header
        act.say "Github request failed -- timed out??"
        break
      end

      if (header.status / 100) != 2
        act.say "Failed to run github command. (Status: %d, Resp: %s)" %
          [header.status, msg]
      else
        yield(json_decode(msg))
      end
    end
  end
end
