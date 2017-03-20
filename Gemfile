source 'https://rubygems.org'

group :development do
  gem 'rake'
end

group :test do
  gem 'guard-rspec'
  require 'rbconfig'
  if RbConfig::CONFIG['target_os'] =~ /darwin(1[0-3])/i
    gem 'rb-fsevent', '<= 0.9.4'
  end
  gem 'webmock'
end

gem 'morph', '>= 0.5.1'
gem 'rest-client', '>= 2.0.1'
