source "http://rubygems.org"

gem 'rack', '1.3.3'

gem 'yajl-ruby', :require => [ 'yajl', 'yajl/json_gem' ]

gem 'faraday', '~> 0.7.5'
gem "nokogiri", "~> 1.5.0"

gem "scamp", "~> 1.0.1"
#gem "scamp", :path => ENV['HOME'] + "/git/clones/Scamp"
#gem "scamp", :git => 'https://github.com/wjessop/Scamp.git', :branch => 'master'

#gem "can-has-lolcat", "~> 1.1.0"
#gem "can-has-lolcat", :path => "../can-has-lolcat"
gem "can-has-lolcat", :git => 'https://github.com/josephruscio/can-has-lolcat.git', :branch => 'feature/add-puppeh-support'

gem "papertrail-cli", "~> 0.8.2"

gem 'hpricot', "~> 0.8.5"

# rollout
gem "redis", "~> 2.2.2"
gem "hiredis", "~> 0.4.5"
gem "em-synchrony"
gem "rollout", "~> 1.1.0"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "shoulda", ">= 0"
  gem "jeweler", "~> 1.6.4"
  gem "rcov", ">= 0"
  gem "pry", "~> 0.9.9.4"
end
