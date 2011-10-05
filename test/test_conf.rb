require 'helper'

class TestConf < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf(Conf::config_file)
  end

  def teardown
    FileUtils.rm_rf(Conf::config_file)
  end

  def validate_settings
    assert_equal(1, Conf::get('net.tcp.foobar'))
    assert_equal('blah', Conf::get('net.tcp.barbar'))
    assert(Conf::exists?('net.tcp.foobar'))
    assert(Conf::exists?('net.tcp.barbar'))
    assert(!Conf::exists?('net.tcp'))

    assert_equal(['barbar', 'foobar'].sort, Conf::list('net.tcp'))
    assert_equal(['tcp'].sort, Conf::list('net'))

    assert_equal([], Conf::list(''))
    assert_equal([], Conf::list('net.tc'))
  end

  def test_config
    Conf::set('net.tcp.foobar', 1)
    Conf::set('net.tcp.barbar', "blah")

    validate_settings

    ['.sys.blah', 'sys.blah.', ''].each do |bad|
      begin
        Conf::set(bad, rand(5))
      rescue
        # Should throw exception
      else
        assert(false, "Did not throw exception setting: #{bad}")
      end
    end

    assert(File.exist?(Conf::config_file), "Conf file doesn't exist")

    # Now reload
    #
    Conf::load

    # retest after reload
    validate_settings
  end
end
