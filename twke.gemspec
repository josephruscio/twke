# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{twke}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joseph Ruscio", "Mike Heffner"]
  s.date = %q{2011-11-08}
  s.default_executable = %q{twke}
  s.description = %q{The ambuquad that has your back.}
  s.email = %q{joe@ruscio.org}
  s.executables = ["twke"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/twke",
    "dot.rvmrc",
    "lib/twke.rb",
    "lib/twke/conf.rb",
    "lib/twke/job.rb",
    "lib/twke/job_manager.rb",
    "lib/twke/plugin.rb",
    "lib/twke/plugin_manager.rb",
    "lib/twke/routes.rb",
    "plugins/admin.rb",
    "plugins/config.rb",
    "plugins/github.rb",
    "plugins/jenkins.rb",
    "plugins/jobs.rb",
    "plugins/run.rb",
    "plugins/twiki.rb",
    "test/helper.rb",
    "test/test_conf.rb",
    "twke.gemspec"
  ]
  s.homepage = %q{http://github.com/josephruscio/twke}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Bidi-Bidi-Bidi!}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, ["= 1.3.3"])
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<faraday>, ["~> 0.7.5"])
      s.add_runtime_dependency(%q<scamp>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<rack>, ["= 1.3.3"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<faraday>, ["~> 0.7.5"])
      s.add_dependency(%q<scamp>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, ["= 1.3.3"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<faraday>, ["~> 0.7.5"])
    s.add_dependency(%q<scamp>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

