# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'sorbet-runtime'

group :development do
  gem 'sorbet'
  gem 'tapioca', require: false
end

group :test do
  gem 'rspec', '~> 3.7.0'
  gem 'vcr', '~> 3.0.3'
  gem 'webmock', '~> 3.1.1'
end

group :tools do
  gem 'byebug', '~> 9.1.0'
  gem 'rubocop', '~> 1.35.0'
end
