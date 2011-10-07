class Plugin::Jenkins < Plugin
  def add_routes(rp, opts)
    rp.route /^\w+ #\d+ ".*?": (FAILURE|UNSTABLE) \(.*?\)$/, :noprefix => true do |act|
      act.play "drama"
    end
  end
end
