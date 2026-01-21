# frozen_string_literal: true
# typed: strict

require "tempfile"

module Geet
  module Commandline
    class Editor
      extend T::Sig

      include Geet::Helpers::OsHelper

      # Git style!
      HELP_SEPARATOR = "------------------------ >8 ------------------------"

      # Edits a content in the default editor, optionally providing help.
      #
      # When the help is provided, it's appended to the bottom, separated by HELP_SEPARATOR.
      # The help is stripped after the content if edited.
      #
      sig { params(content: String, help: T.nilable(String)).returns(String) }
      def edit_content(content: "", help: nil)
        content += "\n\n" + HELP_SEPARATOR + "\n" + help if help

        edited_content = edit_content_in_default_editor(content)

        edited_content = edited_content.split(HELP_SEPARATOR, 2).first if help

        T.must(edited_content).strip
      end

      private

      # MAIN STEPS #######################################################################

      # The gem `tty-editor` does this, although it requires in turn other 7/8 gems.
      # Interestingly, the API `TTY::Editor.open(content: 'text')` is not very useful,
      # as it doesn't return the filename (!).
      #
      sig { params(content: String).returns(String) }
      def edit_content_in_default_editor(content)
        tempfile = T.must(Tempfile.open(["geet_editor", ".md"]) { |file| file << content }.path)
        command = "#{system_editor} #{tempfile.shellescape}"

        execute_command(command, description: "editing", interactive: true)

        content = IO.read(tempfile)

        File.unlink(tempfile)

        content
      end

      # HELPERS ##########################################################################

      sig { returns(String) }
      def system_editor
        ENV["EDITOR"] || ENV["VISUAL"] || "vi"
      end
    end
  end
end
