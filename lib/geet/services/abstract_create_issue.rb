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

      SUMMARY_BACKUP_FILENAME = File.join(Dir.tmpdir, 'last_geet_edited_summary.md')

      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      private

      def save_summary(title, description)
        summary = "#{title}\n\n#{description}".strip + "\n"

        IO.write(SUMMARY_BACKUP_FILENAME, summary)

        @out.puts "Error! Saved summary to #{SUMMARY_BACKUP_FILENAME}"
      end
    end
  end
end
