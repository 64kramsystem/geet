# frozen_string_literal: true
# typed: strict

module Geet
  module Utils
    class StringMatchingSelection
      extend T::Sig

      sig {
        type_parameters(:T).params(
          entry_type: String,
          entries: T::Array[T.type_parameter(:T)],
          pattern: String,
          name_method: T.nilable(Symbol)
        )
        .returns(T.type_parameter(:T))
      }
      def select_entry(entry_type, entries, pattern, name_method: nil)
        entries_found = entries.select do |entry|
          compared_entry = name_method ? T.unsafe(entry).send(name_method) : entry
          T.unsafe(compared_entry).downcase == pattern.downcase
        end

        case entries_found.size
        when 1
          T.must(entries_found.first)
        when 0
          raise "No entry found for #{entry_type} pattern: #{pattern.inspect}"
        else
          raise "Multiple entries found for #{entry_type} pattern #{pattern.inspect}: #{entries_found}"
        end
      end

      sig {
        type_parameters(:T).params(
          entry_type: String,
          entries: T::Array[T.type_parameter(:T)],
          raw_patterns: String,
          name_method: T.nilable(Symbol)
        )
        .returns(T::Array[T.type_parameter(:T)])
      }
      def select_entries(entry_type, entries, raw_patterns, name_method: nil)
        patterns = raw_patterns.split(",")

        patterns.map do |pattern|
          # Haha.
          select_entry(entry_type, entries, pattern, name_method: name_method)
        end
      end
    end
  end
end
