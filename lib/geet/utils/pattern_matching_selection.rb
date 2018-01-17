# frozen_string_literal: true

module Geet
  module Utils
    class PatternMatchingSelection
      def select(entry_type, entries, raw_patterns, instance_method: nil)
        patterns = raw_patterns.split(',')

        patterns.map do |pattern|
          entries_found = entries.select do |entry|
            entry = entry.send(instance_method) if instance_method
            entry =~ /#{pattern}/i
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
      end
    end
  end
end
