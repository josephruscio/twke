#
# Provides access to the configuration system via chat commands.
#
class Plugin::Config < Plugin
  # Invoked to define routes.
  def add_routes(rp, opts)
    rp.route /set (?<var>[^ ]+)[ ]+(?<value>.*[^ ])[ ]*$/ do |act|
      varstr = act.var
      valstr = act.value

      # "value" or 'value' implies string
      if valstr =~ /^".*"$/ || valstr =~ /^'.*'$/
        valstr = valstr[1, valstr.length - 2]
        set_var(act, varstr, valstr)
        next
      end

      # Try as an integer
      as_int = Integer(valstr) rescue nil
      unless as_int.nil?
        set_var(act, varstr, as_int)
        next
      end

      # Try as a float
      as_float = Float(valstr) rescue nil
      unless as_float.nil?
        set_var(act, varstr, as_float)
        next
      end

      # Try to eval it
      begin
        as_eval = eval(valstr)
        set_var(act, varstr, as_eval)
      rescue Exception, SyntaxError
        # Fall back to just a string
        set_var(act, varstr, valstr)
      end
    end

    rp.route /get (?<var>[^ ]+)[ ]*$/ do |act|
      if Twke::Conf::exists?(act.var)
        act.say "#{act.var} = #{Twke::Conf::get(act.var).inspect}"
      else
        act.say "#{act.var} is not set!"
      end
    end

    rp.route /list (?<var>[^ ]+)[ ]*$/ do |act|
      l = Twke::Conf::list(act.var)
      if l.length == 0
        act.say "#{act.var} is empty"
      else
        act.say "#{act.var} = #{l.inspect}"
      end
    end
  end

private

  # XXX: really should be private but scoping problems require this
  def set_var(act, var, value)
    begin
      Twke::Conf::set(var, value)
    rescue => err
      act.say "Failure setting variable #{var}=#{value}: #{err.inspect}"
    end
  end
end
