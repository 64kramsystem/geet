# frozen_string_literal: true

require 'temp-fork-tp-filter'

module Geet
  module Utils
    class ManualListSelection
      PAGER_SIZE = 16

      PROMPT_METHODS = {
        single: :select,
        multiple: :multi_select,
      }

      # selection_type: :single or :multiple
      def select(entry_type, entries, selection_type, instance_method: nil)
        raise "No #{entry_type} provided!" if entries.empty?

        prompt_method = find_prompt_method(selection_type)
        prompt_title = "Please select the #{entry_type}(s):"

        if instance_method
          entries = entries.each_with_object({}) do |entry, current_map|
            current_map[entry.send(instance_method)] = entry
          end
        end

        selected_entries = TTY::Prompt.new.send(prompt_method, prompt_title, entries, filter: true, per_page: PAGER_SIZE)

        if selected_entries.is_a?(Array)
          raise "No #{entry_type} selected!" if selected_entries.empty?
        else
          raise "No #{entry_type} selected!" if selected_entries.nil?
        end

        selected_entries
      end

      private

      def find_prompt_method(selection_type)
        PROMPT_METHODS[selection_type] || raise("Unrecognized selection_type: #{selection_type}")
      end
    end
  end
end
