#
# Provides access to the configuration system via chat commands.
#
class Plugin::Config < Plugin
  # Invoked to define routes.
  def add_routes(rp, opts)
    # XXX: scope problems
    me = self

    rp.route /set (?<var>[^ ]+)[ ]+(?<value>.*[^ ])[ ]*$/ do
      varstr = var
      valstr = value

      # "value" or 'value' implies string
      if valstr =~ /^".*"$/ || valstr =~ /^'.*'$/
        valstr = valstr[1, valstr.length - 2]
        me.set_var(varstr, valstr) or
          say "Can't set #{varstr} to #{valstr}"
        next
      end

      # Try as an integer
      as_int = Integer(valstr) rescue nil
      unless as_int.nil?
        me.set_var(varstr, as_int) or
          say "Can't set #{varstr} to #{valstr}"
        next
      end

      # Try as a float
      as_float = Float(valstr) rescue nil
      unless as_float.nil?
        me.set_var(varstr, as_float) or
          say "Can't set #{varstr} to #{valstr}"
        next
      end

      # Try to eval it
      begin
        as_eval = eval(valstr)
        me.set_var(varstr, as_eval) or
          say "Can't set #{varstr} to #{valstr}"
      rescue
        # Fall back to just a string
        me.set_var(varstr, valstr) or
          say "Can't set #{varstr} to #{valstr}"
      end
    end

    rp.route /get (?<var>[^ ]+)[ ]*$/ do
      if Twke::Conf::exists?(var)
        say "#{var} = #{Twke::Conf::get(var).inspect}"
      else
        say "#{var} is not set!"
      end
    end

    rp.route /list (?<var>[^ ]+)[ ]*$/ do
      l = Twke::Conf::list(var)
      if l.length == 0
        say "#{var} is empty"
      else
        say "#{var} = #{l.inspect}"
      end
    end
  end

  # XXX: really should be private but scoping problems require this
  def set_var(var, value)
    begin
      Twke::Conf::set(var, value)
      return true
    rescue => err
      puts "Failure setting variable #{var}=#{value}: #{err.inspect}"
      return false
    end
  end
end
