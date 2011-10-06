# twke

twke (pronounced *twee-kee*) is an extensible Campfire bot inspired by
Hubot and created by the [Librato team](http://librato.com) 
with the [Scamp framework](https://github.com/wjessop/Scamp).
His primary mission is to assist in the day-to-day DevOps activities of
a team building and operating a *SaaS* platform.

## Contributing to twke
twke's plugin system is modeled after
[Github-Services](https://github.com/github/github-services) and
creating a new plugin is extremely straightforward:

1. Fork the project
1. Start a feature branch
1. Create a new file in `/plugins` called `plugin_name.rb`, using the
following template:

    ```ruby
    class Plugin::PluginName < Plugin
      def add_routes(rp, opts)
        rp.route 'foo' do |act|
          act.say 'bar'
        end
        
        rp.route /hello (?<person>.+)$/ do |act|
          act.say "Hello #{act.person}!"
        end
      end
    end
    ```
1. Commit and push until you are happy with your contribution
1. Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
1. Submit a pull request from your fork to josephruscio/twke

## More examples

```ruby
def add_routes(rp, opts)
  #
  # Create command scopes.
  #
  #  Example, listen for the following:
  #   <bot> admin version
  #   <bot> admin quit
  #

  rp.admin do
    rp.route 'version' do |act|
      act.say "Version is 0.1.2"
    end

    rp.route 'quit' do |act|
      act.say "Leaving"
      exit 0
    end
  end

  #
  # Don't require the <bot> string prefix.
  #
  #  Example, listen for the following:
  #
  #    admin version
  #

  rp.admin(:noprefix => true) do
    rp.route 'version' do |act|
      act.say "Version cmd without <bot> prefix!"
    end
  end

  #
  # Top-level route without <bot> prefix
  #
  #  Example, listen for the following:
  #
  #    bark
  #

  rp.route 'bark', :noprefix => true do |act|
    act.play 'barking'
  end
end
```

## Colophon

twke is named after the [ambuquad designated
TWKE-4](https://secure.wikimedia.org/wikipedia/en/wiki/Twiki) who
faithfully accompanied Buck Rogers in the 25th Century. His
voice has been described as a cross between Yosemite Sam and Porky Pig,
and he usually prefixed any speech with a low-pitched "bidi-bidi-bidi".

### Copyright

Copyright (c) 2011 Joseph Ruscio. See LICENSE.txt for
further details.
