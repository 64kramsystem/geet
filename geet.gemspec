# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'geet/version'

Gem::Specification.new do |s|
  s.name        = 'geet'
  s.version     = Geet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.3.0'
  s.authors     = ['Saverio Miroddi']
  s.date        = '2021-07-26'
  s.email       = ['saverio.pub2@gmail.com']
  s.homepage    = 'https://github.com/saveriomiroddi/geet'
  s.summary     = 'Commandline interface for performing SCM host operations, eg. create a PR on GitHub'
  s.description = 'Commandline interface for performing SCM host operations, eg. create a PR on GitHub, with support for multiple hosts.'
  s.license     = 'GPL-3.0'

  s.add_runtime_dependency 'simple_scripting', '~> 0.11.0'
  s.add_runtime_dependency 'tty-prompt', '~> 0.15.0'

  s.add_development_dependency 'rake', '~> 12.3'

  s.files         = `git ls-files`.split("\n")
  s.executables   << 'geet'
  s.require_paths = ['lib']
end
