# frozen_string_literal: true

require_relative 'manual_list_selection'
require_relative 'string_matching_selection'
require_relative '../shared/constants'

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
      include Geet::Shared::Constants

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

      def add_attribute(repository_call, description, pattern, selection_type, name_method: nil, &pre_selection_hook)
        raise "Unrecognized selection type #{selection_type.inspect}" if ![:single, :multiple].include?(selection_type)

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
          when :single
            select_entry(description, entries, pattern, name_method)
          when :multiple
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
        if pattern == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entry(entry_type, entries, name_method: name_method)
        else
          Geet::Utils::StringMatchingSelection.new.select_entry(entry_type, entries, pattern, name_method: name_method)
        end
      end

      # Sample call:
      #
      #   select_entries('reviewer', all_collaborators, 'donaldduck', nil)
      #
      def select_entries(entry_type, entries, pattern, name_method)
        if pattern == MANUAL_LIST_SELECTION_FLAG
          Geet::Utils::ManualListSelection.new.select_entries(entry_type, entries, name_method: name_method)
        else
          Geet::Utils::StringMatchingSelection.new.select_entries(entry_type, entries, pattern, name_method: name_method)
        end
      end
    end
  end
end
