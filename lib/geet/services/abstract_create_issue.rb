# frozen_string_literal: true

require 'tmpdir'

require_relative '../helpers/os_helper'
require_relative '../utils/attributes_selection_manager'
require_relative '../utils/manual_list_selection'
require_relative '../utils/string_matching_selection'

module Geet
  module Services
    class AbstractCreateIssue
      include Geet::Helpers::OsHelper

      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end
    end
  end
end
