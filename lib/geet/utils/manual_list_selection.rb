# frozen_string_literal: true

require 'temp-fork-tp-filter'

module Geet
  module Utils
    class ManualListSelection
      NO_SELECTION_KEY = '(none)'

      PAGER_SIZE = 16

      # Shows a prompt for selecting an entry from a list.
      #
      # Returns nil, without showing the prompt, if there are no entries.
      #
      # entry_type:      description of the entries type.
      # entries:         array of objects; if they're not strings, must also pass :instance_method.
      #                  this value must not be empty.
      # instance_method: required when non-string objects are passed as entries; its invocation on
      #                  each object must return a string, which is used as key.
      #
      # returns: the selected entry. if no entries are nil is returned.
      #
      def select_entry(entry_type, entries, instance_method: nil)
        return nil if entries.empty?

        check_entries(entries, entry_type)

        entries = create_entries_map(entries, instance_method)
        entries = add_no_selection_entry(entries)

        show_prompt(:select, entry_type, entries)
      end

      # Shows a prompt for selecting an entry from a list.
      #
      # Returns an empty array, without showing the prompt, if there are no entries.
      #
      # See #selecte_entry for the parameters.
      #
      # returns: array of entries.
      #
      def select_entries(entry_type, entries, instance_method: nil)
        return [] if entries.empty?

        check_entries(entries, entry_type)

        entries = create_entries_map(entries, instance_method)

        show_prompt(:multi_select, entry_type, entries)
      end

      private

      def check_entries(entries, entry_type)
        raise "No #{entry_type} provided!" if entries.empty?
      end

      def create_entries_map(entries, instance_method)
        entries.each_with_object({}) do |entry, current_map|
          key = instance_method ? entry.send(instance_method) : entry
          current_map[key] = entry
        end
      end

      def add_no_selection_entry(entries)
        {NO_SELECTION_KEY => nil}.merge(entries)
      end

      def show_prompt(invocation_method, entry_type, entries)
        # Arguably inexact phrasing for avoiding language complexities.
        prompt_title = "Please select the #{entry_type}(s):"

        TTY::Prompt.new.send(invocation_method, prompt_title, entries, filter: true, per_page: PAGER_SIZE)
      end
    end
  end
end
