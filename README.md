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
        rp.route 'foo' do
          say 'bar'
        end
        
        rp.route 'hello' do
          say "Hello World!"
        end
      end
    end
    ```
1. Commit and push until you are happy with your contribution
1. Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
1. Submit a pull request from your fork to josephruscio/twke

## Colophon

twke is named after the [ambuquad designated
TWKE-4](https://secure.wikimedia.org/wikipedia/en/wiki/Twiki) who
faithfully accompanied Buck Rogers in the 25th Century. His
voice has been described as a cross between Yosemite Sam and Porky Pig,
and he usually prefixed any speech with a low-pitched "bidi-bidi-bidi".

### Copyright

Copyright (c) 2011 Joseph Ruscio. See LICENSE.txt for
further details.
