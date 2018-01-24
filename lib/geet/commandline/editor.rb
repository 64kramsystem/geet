# frozen_string_literal: true

require 'tempfile'

require_relative '../helpers/os_helper.rb'

module Geet
  module Commandline
    class Editor
      # Liberally ripp..., ahem, inspired from git.
      SUMMARY_TEMPLATE = File.expand_path('../resources/templates/edit_summary.md', __dir__)
      SUMMARY_TEMPLATE_SEPARATOR = '------------------------ >8 ------------------------'

      include Geet::Helpers::OsHelper

      # Edits a summary in the default editor, providing the SUMMARY_TEMPLATE.
      #
      # A summary is a composition with a title and an optional description;
      # if the description is not found, a blank string is returned.
      #
      # It's possible to append extra text to the help, by passing :extra_help.
      #
      def edit_summary(summary: nil, extra_help: nil)
        full_summary = summary.to_s + IO.read(SUMMARY_TEMPLATE) + extra_help.to_s

        raw_summary = edit_content_in_default_editor(full_summary)

        split_raw_summary(raw_summary)
      end

      private

      # MAIN STEPS #######################################################################

      # The gem `tty-editor` does this, although it requires in turn other 7/8 gems.
      # Interestingly, the API `TTY::Editor.open(content: 'text')` is not very useful,
      # as it doesn't return the filename (!).
      #
      def edit_content_in_default_editor(content)
        tempfile = Tempfile.open(['geet_editor', '.md']) { |file| file << content }.path
        command = "#{system_editor} #{tempfile.shellescape}"

        execute_command(command, description: 'editing', interactive: true)

        content = IO.read(tempfile)

        File.unlink(tempfile)

        content
      end

      def split_raw_summary(raw_summary)
        raw_summary, _ = raw_summary.strip.split(SUMMARY_TEMPLATE_SEPARATOR, 2)

        raise "Missing title!" if raw_summary.empty?

        title, description = raw_summary.split(/\r|\n/, 2)

        # The title may have a residual newline char; the description may not be present,
        # or have multiple blank lines.
        [title.strip, description.to_s.strip]
      end

      # HELPERS ##########################################################################

      def system_editor
        ENV['EDITOR'] || ENV['VISUAL'] || 'vi'
      end
    end
  end
end
