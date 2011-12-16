class Plugin::Jenkins < Plugin
  DefaultSuccess = 'secret'
  DefaultFail = 'drama'

  def add_routes(rp, opts)
    rp.route /^[-\w.]+ #\d+ ".*?": (FAILURE|UNSTABLE) \(.*?\)$/, :noprefix => true do |act|
      fail_sound = Twke::Conf.get('jenkins.sounds.fail')

      act.play (fail_sound) ? fail_sound : DefaultFail
    end

    rp.route /^[-\w.]+ #\d+ ".*?": success$/, :noprefix => true do |act|
      success_sound = Twke::Conf.get('jenkins.sounds.success')

      act.play (success_sound) ? success_sound : DefaultSuccess
    end
  end
end
