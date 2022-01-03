# frozen_string_literal: true

require_relative 'manual_list_selection'
require_relative 'string_matching_selection'
require_relative '../shared/selection'

module Geet
  module Utils
    # Manages the retrieval and selection of attributes.
    #
    # Selecting an attribute happens in two steps: retrieval and selection.
    #
    # With this structure, the retrieval happens in parallel, cutting the time considerably when
    # multiple attributes are required (typically, three).
    #
    class AttributesSelectionManager
      include Geet::Shared::Selection

      # Workaround for VCR not supporting multithreading; see https://github.com/vcr/vcr/issues/200.
      #
      class << self
        attr_accessor :serialize_requests
      end

      # Initialize the instance, and starts the background threads.
      #
      def initialize(repository, out: output)
        @repository = repository
        @out = out
        @selections_data = []
      end

      # selection_type: SELECTION_SINGLE or SELECTION_MULTIPLE
      #
      def add_attribute(repository_call, description, pattern, selection_type, name_method: nil, &pre_selection_hook)
        raise "Unrecognized selection type #{selection_type.inspect}" if ![SELECTION_SINGLE, SELECTION_MULTIPLE].include?(selection_type)

        finder_thread = find_attribute_entries(repository_call)

        @selections_data << [finder_thread, description, pattern, selection_type, name_method, pre_selection_hook]
      end

      # Select and return the attributes, in the same order they've been added.
      #
      def select_attributes
        @selections_data.map do |finder_thread, description, pattern, selection_type, name_method, pre_selection_hook|
          entries = finder_thread.value

          entries = pre_selection_hook.(entries) if pre_selection_hook

          case selection_type
          when SELECTION_SINGLE
            select_entry(description, entries, pattern, name_method)
          when SELECTION_MULTIPLE
            select_entries(description, entries, pattern, name_method)
          end
        end
      end

      private

      def find_attribute_entries(repository_call)
        @out.puts "Finding #{repository_call}..."

        finder_thread = Thread.new do
          @repository.send(repository_call)
        end

        finder_thread.join if self.class.serialize_requests

        finder_thread
      end

      # Sample call:
      #
      #   select_entry('milestone', all_milestones, '0.1.0', :title)
      #
      def select_entry(entry_type, entries, pattern, name_method)
        case pattern
        when MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entry(entry_type, entries, name_method: name_method)
        when SKIP_LIST_SELECTION_FLAG
          nil
        else
          Geet::Utils::StringMatchingSelection.new.select_entry(entry_type, entries, pattern, name_method: name_method)
        end
      end

      # Sample call:
      #
      #   select_entries('reviewer', all_collaborators, 'donaldduck', nil)
      #
      def select_entries(entry_type, entries, pattern, name_method)
        # Support both formats Array and String.
        # It seems that at some point, SimpleScripting started splitting arrays automatically, so until
        # the code is adjusted accordingly, this accommodates both the CLI and the test suite.
        # Tracked here: https://github.com/saveriomiroddi/geet/issues/171.
        #
        pattern = pattern.join(',') if pattern.is_a?(Array)

        case pattern
        when MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entries(entry_type, entries, name_method: name_method)
        when SKIP_LIST_SELECTION_FLAG
          []
        else
          Geet::Utils::StringMatchingSelection.new.select_entries(entry_type, entries, pattern, name_method: name_method)
        end
      end
    end
  end
end
