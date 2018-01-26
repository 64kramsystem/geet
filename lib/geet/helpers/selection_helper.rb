# frozen_string_literal: true

require_relative '../utils/manual_list_selection.rb'
require_relative '../utils/pattern_matching_selection.rb'

module Geet
  module Helpers
    module SelectionHelper
      MANUAL_LIST_SELECTION_FLAG = '-'.freeze

      # Sample calls:
      #
      #   select_entries('milestone', all_milestones, milestone_pattern, :single, :title)
      #   select_entries('reviewer', all_collaborators, reviewer_patterns, :multiple, nil)
      #
      def select_entries(entry_type, entries, raw_patterns, selection_type, instance_method)
        if raw_patterns == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select(entry_type, entries, selection_type, instance_method: instance_method)
        else
          Geet::Utils::PatternMatchingSelection.new.select(entry_type, entries, raw_patterns, instance_method: instance_method)
        end
      end
    end
  end
end
