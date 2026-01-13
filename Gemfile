# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'sorbet-runtime'

group :development do
  gem 'sorbet', '= 0.6.12883', require: false
  gem 'byebug'
  gem 'rubocop', '~> 1.35.0', require: false
  gem 'spoom', require: false
  gem 'tapioca', '>= 0.17.10', require: false
end

group :test do
  gem 'rspec', '~> 3.13.0'
  gem 'vcr', '~> 6.1.0'
  gem 'webmock', '~> 3.1.1'
end
