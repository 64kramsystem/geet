# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'sorbet-runtime'

group :development do
  gem 'sorbet'
  gem 'byebug'
  gem 'rubocop', '~> 1.35.0', require: :false
  gem 'spoom', require: false
  gem 'tapioca', require: false
end

group :test do
  gem 'rspec', '~> 3.7.0'
  gem 'vcr', '~> 6.1.0'
  gem 'webmock', '~> 3.1.1'
end
