# frozen_string_literal: true

require_relative '../utils/manual_list_selection.rb'
require_relative '../utils/string_matching_selection.rb'

module Geet
  module Helpers
    module SelectionHelper
      MANUAL_LIST_SELECTION_FLAG = '-'.freeze

      # Sample call:
      #
      #   select_entry('milestone', all_milestones, milestone_pattern, :title)
      #
      def select_entry(entry_type, entries, pattern, instance_method)
        if pattern == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entry(entry_type, entries, instance_method: instance_method)
        else
          Geet::Utils::StringMatchingSelection.new.select_entry(entry_type, entries, pattern, instance_method: instance_method)
        end
      end

      # Sample call:
      #
      #   select_entries('reviewer', all_collaborators, reviewers, nil)
      #
      def select_entries(entry_type, entries, pattern, instance_method)
        if pattern == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entries(entry_type, entries, instance_method: instance_method)
        else
          Geet::Utils::StringMatchingSelection.new.select_entries(entry_type, entries, pattern, instance_method: instance_method)
        end
      end
    end
  end
end
