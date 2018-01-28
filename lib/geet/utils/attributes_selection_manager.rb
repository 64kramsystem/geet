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

      # Initialize the instance, and starts the background threads.
      #
      def initialize(repository, output)
        @repository = repository
        @selections_data = []
        @output = output
      end

      def add_attribute(repository_call, description, pattern, selection_type, name_method: nil)
        raise "Unrecognized selection type #{selection_type.inspect}" if ![:single, :multiple].include?(selection_type)

        finder_thread = find_attribute_entries(repository_call)

        @selections_data << [finder_thread, description, pattern, selection_type, name_method]
      end

      # Select and return the attributes, in the same order they've been added.
      #
      def select_attributes
        @selections_data.map do |finder_thread, description, pattern, selection_type, name_method|
          entries = finder_thread.value

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
        @output.puts "Finding #{repository_call}..."

        Thread.new do
          entries = @repository.send(repository_call)

          raise "No #{repository_call} found!" if entries.empty?

          entries
        end
      end

      # Sample call:
      #
      #   select_entry('milestone', all_milestones, milestone, :title)
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
