# frozen_string_literal: true

require 'tmpdir'

require_relative '../helpers/os_helper'
require_relative '../helpers/selection_helper'
require_relative '../utils/manual_list_selection'
require_relative '../utils/string_matching_selection'

module Geet
  module Services
    class AbstractCreateIssue
      include Geet::Helpers::OsHelper
      include Geet::Helpers::SelectionHelper

      SUMMARY_BACKUP_FILENAME = File.join(Dir.tmpdir, 'last_geet_edited_summary.md')

      def initialize(repository)
        @repository = repository
      end

      private

      def find_attribute_entries(repository_call, output)
        output.puts "Finding #{repository_call}..."

        Thread.new do
          entries = @repository.send(repository_call)

          raise "No #{repository_call} found!" if entries.empty?

          entries
        end
      end

      def save_summary(title, description, output)
        summary = "#{title}\n\n#{description}".strip + "\n"

        IO.write(SUMMARY_BACKUP_FILENAME, summary)

        output.puts "Error! Saved summary to #{SUMMARY_BACKUP_FILENAME}"
      end
    end
  end
end
