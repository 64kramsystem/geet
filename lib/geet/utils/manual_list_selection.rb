# frozen_string_literal: true

require 'temp-fork-tp-filter'

module Geet
  module Utils
    class ManualListSelection
      NO_SELECTION_KEY = '(none)'

      PAGER_SIZE = 16

      # entry_type:      description of the entries type.
      # entries:         array of objects; if they're not strings, must also pass :instance_method.
      #                  this value must not be empty.
      # selection_type:  :single or :multiple
      # instance_method: required when non-string objects are passed as entries; its invocation on
      #                  each object must return a string, which is used as key.
      #
      # returns: the selected entry or array of entries. for single selection, if no entries are
      #          chosen, nil is returned.
      #
      def select(entry_type, entries, selection_type, instance_method: nil)
        check_entries(entries)

        entries = create_entries_map(entries, instance_method)

        result = show_prompt(entry_type, selection_type, entries)

        result
      end

      private

      def check_entries(entries)
        raise "No #{entry_type} provided!" if entries.empty?
      end

      def create_entries_map(entries, instance_method)
        entries.each_with_object({}) do |entry, current_map|
          key = instance_method ? entry.send(instance_method) : entry
          current_map[key] = entry
        end
      end

      def show_prompt(entry_type, selection_type, entries)
        prompt_title = "Please select the #{entry_type}(s):"

        case selection_type
        when :single
          entries = add_no_selection_entry(entries)
          TTY::Prompt.new.select(prompt_title, entries, filter: true, per_page: PAGER_SIZE)
        when :multiple
          TTY::Prompt.new.multi_select(prompt_title, entries, filter: true, per_page: PAGER_SIZE)
        else
          raise "Unexpected selection type: #{selection_type.inspect}"
        end
      end

      def add_no_selection_entry(entries)
        {NO_SELECTION_KEY => nil}.merge(entries)
      end
    end
  end
end
