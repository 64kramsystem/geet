# frozen_string_literal: true

require 'English'
require 'open3'
require 'shellwords'

module Geet
  module Helpers
    module OsHelper
      def open_file_with_default_application(file_or_url)
        if `uname`.strip == 'Darwin'
          exec "open #{file_or_url.shellescape}"
        else
          exec "xdg-open #{file_or_url.shellescape}"
        end
      end

      # Executes the command.
      #
      # If the command doesn't execute successfully, it will raise an error.
      #
      # On non-interactive runs, the stdout content is returned, stripped of the surrounding
      # whitespaces.
      #
      # description:   optional string, to make the error clearer.
      # interactive:   set when required; in this case, a different API will be used (`system()`
      #                instead of `popen3`).
      # silent_stderr: don't print the stderr output
      #
      def execute_command(command, description: nil, interactive: false, silent_stderr: false)
        description_message = " on #{description}" if description

        if interactive
          system(command)

          if !$CHILD_STATUS.success?
            raise "Error#{description_message} (exit status: #{$CHILD_STATUS.exitstatus})"
          end
        else
          Open3.popen3(command) do |_, stdout, stderr, wait_thread|
            stdout_content = stdout.read
            stderr_content = stderr.read

            puts stderr_content if stderr_content != '' && !silent_stderr

            if !wait_thread.value.success?
              error_message = stderr_content.lines.first.strip
              raise "Error#{description_message}: #{error_message}"
            end

            stdout_content.strip
          end
        end
      end
    end
  end
end
