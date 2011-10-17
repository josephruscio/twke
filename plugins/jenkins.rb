class Plugin::Jenkins < Plugin
  def add_routes(rp, opts)
    rp.route /^[\w-]+ #\d+ ".*?": (FAILURE|UNSTABLE) \(.*?\)$/, :noprefix => true do |act|
      act.play "drama"
    end

    rp.route /^[\w-]+ #\d+ ".*?": success$/, :noprefix => true do |act|
      act.play "yeah"
    end
  end
end
