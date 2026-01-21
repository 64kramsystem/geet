# frozen_string_literal: true
# typed: strict

require "tty-prompt"

module Geet
  module Utils
    class ManualListSelection
      extend T::Sig

      NO_SELECTION_KEY = "(none)"

      PAGER_SIZE = 16

      # Shows a prompt for selecting an entry from a list.
      #
      sig {
        type_parameters(:T).params(
          entry_type: String,                        # description of the entries type.
          entries: T::Array[T.type_parameter(:T)],   # array of objects; if they're not strings, must also pass :name_method.
          name_method: T.nilable(Symbol)             # required when non-string objects are passed as entries; its invocation
                                                     # on each object must return a string, which is used as key.
        ).returns(T.nilable(T.type_parameter(:T)))   # selected entry. nil is returned if the null entry (NO_SELECTION_KEY) is
                                                     # selected, or if there are no entries.
      }
      def select_entry(entry_type, entries, name_method: nil)
        return nil if entries.empty?

        check_entries(entries, entry_type)

        entries = create_entries_map(entries, name_method)
        entries = add_no_selection_entry(entries)

        chosen_entry = show_prompt(:select, entry_type, entries)

        no_selection?(chosen_entry) ? nil : chosen_entry
      end

      # Shows a prompt for selecting an entry from a list.
      #
      # See #select_entry for the parameters.
      #
      # returns: array of entries.
      #
      sig {
        type_parameters(:T).params(
          entry_type: String,
          entries: T::Array[T.type_parameter(:T)],
          name_method: T.nilable(Symbol)
        ).returns(T::Array[T.type_parameter(:T)])   # empty array, without showing the prompt, if there are no entries.
      }
      def select_entries(entry_type, entries, name_method: nil)
        return [] if entries.empty?

        check_entries(entries, entry_type)

        entries_map = create_entries_map(entries, name_method)

        T.cast(show_prompt(:multi_select, entry_type, entries_map), T::Array[T.type_parameter(:T)])
      end

      private

      sig {
        type_parameters(:T).params(
          entries: T::Array[T.type_parameter(:T)],
          entry_type: String
        )
        .void
      }
      def check_entries(entries, entry_type)
        raise "No #{entry_type} provided!" if entries.empty?
      end

      sig {
        type_parameters(:T).params(
          entries: T::Array[T.type_parameter(:T)],
          name_method: T.nilable(Symbol)
        )
        .returns(T::Hash[String, T.type_parameter(:T)])
      }
      def create_entries_map(entries, name_method)
        entries.each_with_object({}) do |entry, current_map|
          key = name_method ? T.unsafe(entry).send(name_method) : entry
          current_map[key] = entry
        end
      end

      sig {
        type_parameters(:T).params(entries: T::Hash[String, T.type_parameter(:T)]
        ).returns(T::Hash[String, T.type_parameter(:T)])
      }
      def add_no_selection_entry(entries)
        {NO_SELECTION_KEY => nil}.merge(entries)
      end

      sig {
        type_parameters(:T).params(
          invocation_method: Symbol,
          entry_type: String,
          entries: T::Hash[String, T.type_parameter(:T)]
        ).returns(T.type_parameter(:T))
      }
      def show_prompt(invocation_method, entry_type, entries)
        # Arguably inexact phrasing for avoiding language complexities.
        prompt_title = "Please select the #{entry_type}(s):"

        ::TTY::Prompt.new.send(invocation_method, prompt_title, entries, filter: true, per_page: PAGER_SIZE)
      end

      sig {
        params(
          entry: T.anything
        )
        .returns(T::Boolean)
      }
      def no_selection?(entry)
        T.unsafe(entry) == NO_SELECTION_KEY
      end
    end
  end
end
