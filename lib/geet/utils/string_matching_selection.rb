# frozen_string_literal: true

module Geet
  module Utils
    class StringMatchingSelection
      def select_entry(entry_type, entries, pattern, name_method: nil)
        entries_found = entries.select do |entry|
          entry = entry.send(name_method) if name_method
          entry.downcase == pattern.downcase
        end

        case entries_found.size
        when 1
          entries_found.first
        when 0
          raise "No entry found for #{entry_type} pattern: #{pattern.inspect}"
        else
          raise "Multiple entries found for #{entry_type} pattern #{pattern.inspect}: #{entries_found}"
        end
      end

      def select_entries(entry_type, entries, raw_patterns, name_method: nil)
        patterns = raw_patterns.split(',')

        patterns.map do |pattern|
          # Haha.
          select_entry(entry_type, entries, pattern, name_method: name_method)
        end
      end
    end
  end
end
