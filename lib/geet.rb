# frozen_string_literal: true

require 'sorbet-runtime'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("pr" => "PR")
loader.setup

module Geet
end
