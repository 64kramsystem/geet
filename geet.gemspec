# frozen_string_literal: true

require_relative "lib/geet/version"

Gem::Specification.new do |s|
  s.name        = "geet"
  s.version     = Geet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = ">= 3.2.0"
  s.authors     = ["Saverio Miroddi"]
  s.date        = "2026-02-20"
  s.email       = ["saverio.pub2@gmail.com"]
  s.homepage    = "https://github.com/saveriomiroddi/geet"
  s.summary     = "Commandline interface for performing SCM host operations, eg. create a PR on GitHub"
  s.description = "Commandline interface for performing SCM host operations, eg. create a PR on GitHub, with support for multiple hosts."
  s.license     = "GPL-3.0-only"

  s.add_runtime_dependency "base64", "~> 0.3.0"
  s.add_runtime_dependency "ostruct", "~> 0.6.3"
  s.add_runtime_dependency "simple_scripting", "~> 0.14.0"
  s.add_runtime_dependency "sorbet-runtime", "= 0.6.12883"
  s.add_runtime_dependency "tty-prompt", "~> 0.23.1"
  s.add_runtime_dependency "zeitwerk", "~> 2.7"

  s.add_development_dependency "rake", "~> 12.3"

  s.files         = `git ls-files`.split("\n")
  s.executables   << "geet"
  s.require_paths = ["lib"]
end
