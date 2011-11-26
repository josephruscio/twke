source "http://rubygems.org"

gem 'rack', '1.3.3'

gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]

gem 'faraday', '~> 0.7.5'
gem "nokogiri", "~> 1.5.0"

#gem "scamp", "~> 0.1.1"
#gem "scamp", :path => ENV['HOME'] + "/git/clones/Scamp"
gem "scamp", :git => 'https://github.com/mheffner/Scamp.git', :branch => 'feature/pass_action_context'

#gem "can-has-lolcat", "~> 1.1.0"
#gem "can-has-lolcat", :path => "../can-has-lolcat"
gem "can-has-lolcat", :git => 'https://github.com/josephruscio/can-has-lolcat.git', :branch => 'feature/add-puppeh-support'

gem "papertrail-cli", "~> 0.8.2"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "shoulda", ">= 0"
  gem "bundler", "~> 1.0.0"
  gem "jeweler", "~> 1.6.4"
  gem "rcov", ">= 0"
end
