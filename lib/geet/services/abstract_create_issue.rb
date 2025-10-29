# frozen_string_literal: true
# typed: strict

require 'stringio'
require 'tmpdir'
require 'sorbet-runtime'

require_relative '../helpers/os_helper'
require_relative '../utils/attributes_selection_manager'
require_relative '../utils/manual_list_selection'
require_relative '../utils/string_matching_selection'

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
