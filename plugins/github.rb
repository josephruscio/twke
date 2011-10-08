class Plugin::Github < Plugin
  #
  # Plugin methods
  #

  #
  # Config variables:
  #
  #  github.user.name
  #  github.user.token
  #
  #

  # Add routes
  def add_routes(rp, opts)
    rp.github do
      rp.route /(pulls|pull|pullrequest|pullrequests) (?<user>.+) (?<repo>.+)$/ do |act|
        github(act, "pulls/#{act.user}/#{act.repo}", :get) do |msg|
          pulls = msg['pulls'].sort { |a, b|
            a['issue_updated_at'] <=> b['issue_updated_at']
          }

          if pulls.length == 0
            act.say "No open pull requests for #{act.user}/#{act.repo}"
            break
          end

          act.say "Open pull requests for https://github.com/#{act.user}/#{act.repo}"
          pulls.each do |pr|
            act.say "[%s] %s: (%s)" %
              [pr['user']['name'], pr['title'], pr['html_url']]
          end
        end
      end
    end
  end

private

  def github(act, cmd, verb)
    user = Twke::Conf.get('github.user.name')
    token = Twke::Conf.get('github.user.token')

    unless user && token
      act.say "Github plugin not configured!"
      return
    end

    url = "https://github.com/api/v2/json/#{cmd}"
    http.basic_auth "#{user}/token", token

    resp = http_method(verb, url)

    if !resp.success?
      act.say "Failed to run github command. [Status #{resp.status}: #{resp.body}]"
    else
      yield(json_decode(resp.body))
    end
  end
end
