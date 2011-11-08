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

## External Plugins

By default, all plugins listed under the `plugins/` directory will be
loaded at startup time. You can also specify additional external
plugins to load at startup time using the `admin.load_plugins`
configuration setting. External plugins can be loaded from a directory
path on the file system or even from an external git repo.

There are a couple limitations for external plugins. These may be
addressed in the future:

 * Plugins can not have any external dependencies are not listed in the
   twke Gemfile.
 * There is no support for post-clone operations (like bundle install)
   when using an external GIT repo.

### Loading external plugins from a directory

For example:

```
set admin.load_plugins.darius.path "/home/albert/darius/plugins"
```

Will load all plugin files named `/home/albert/darius/plugins/*.rb` on
startup.

### Loading external plugins from a git repo

For example:

```
set admin.load_plugins.darius.repo "https://github.com/albert/darius.git"
set admin.load_plugins.darius.dir "plugins"
```

Will clone the git repo to a temporary directory and then load all
plugin files named `*.rb` in the directory `plugins` of the git
repo.


## Job Control

One of the main methods by which a plugin can perform a task is to
spawn some external application. To assist this common pattern, Twke
provides a fairly full-featured Job Control system.

### Job Control Plugin Use

The following example demonstrates how to use the job control system
from your plugin:

```
# Run /usr/bin/myapp
#
job = Twke::JobManager.spawn("/usr/bin/myapp --help", 
                             { :dir => "/tmp/workdir",
                               :environ => {
                                  "MYVAR" => "MY_VALUE"
                               }})

# Set a callback when the job succeeds
job.callback do
  puts "Job succeeded!"
end

# Set a callback for job failure (non-zero exit code or signaled)
job.errback do
  puts "Job failed! See output:"

  # Output can be retrieved with the job method 'output'
  puts job.output
end

# Send a SIGTERM to the job:
job.kill!

# Get the last 20 lines of output from the job
puts job.output_tail
```

### Job Control Plugin

The jobs plugin also provides a number of helpful commands:

 * `jobs list`: List all active and finished jobs. Jobs persist for 30
   minutes after completion to allow for checking outputs.
 * `jobs kill <JID>`: Send a SIGTERM to the job ID JID.
 * `jobs tail <JID>`: Print as a CF paste the last 20 lines of output
   from the job ID JID.

## Colophon

twke is named after the [ambuquad designated
TWKE-4](https://secure.wikimedia.org/wikipedia/en/wiki/Twiki) who
faithfully accompanied Buck Rogers in the 25th Century. His
voice has been described as a cross between Yosemite Sam and Porky Pig,
and he usually prefixed any speech with a low-pitched "bidi-bidi-bidi".

### Copyright

Copyright (c) 2011 Joseph Ruscio. See LICENSE.txt for
further details.
