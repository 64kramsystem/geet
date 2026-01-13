# frozen_string_literal: true
# typed: strict

require 'stringio'
require 'tmpdir'

module Geet
  module Services
    class AbstractCreateIssue
      extend T::Sig

      include Geet::Helpers::OsHelper

      sig { params(repository: T.untyped, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end
    end
  end
end
