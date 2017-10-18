# encoding: UTF-8

$LOAD_PATH << File.expand_path("lib", __dir__)

require "geet/version"

Gem::Specification.new do |s|
  s.name        = "geet"
  s.version     = Geet::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Saverio Miroddi"]
  s.date        = "2017-10-18"
  s.email       = ["saverio.pub2@gmail.com"]
  s.homepage    = "https://github.com/saveriomiroddi/geet"
  s.summary     = "Commandline interface for performing SCM (eg. GitHub) operations (eg. PR creation)."
  s.description = "Commandline interface for performing SCM (eg. GitHub) operations (eg. PR creation)."
  s.license     = "GPL-3.0"

  s.add_runtime_dependency "simple_scripting", "~> 0.9.3"

  s.files         = `git ls-files`.split("\n")
  s.executables   << "geet"
  s.require_paths = ["lib"]
end
