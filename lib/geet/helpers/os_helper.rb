# frozen_string_literal: true
# typed: true

require 'English'
require 'open3'
require 'shellwords'
require 'sorbet-runtime'

module Geet
  module Helpers
    module OsHelper
      extend T::Sig

      include Kernel # for Sorbet compatibility

      sig { params(file_or_url: T.untyped).void }
      def open_file_with_default_application(file_or_url)
        open_command = case
        when ENV["WSL_DISTRO_NAME"]
          "wslview"
        when `uname`.strip == 'Darwin'
          "open"
        else
          "xdg-open"
        end

        command = "#{open_command} #{file_or_url.shellescape}"

        system(command, exception: true)
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
      # allow_error:   don't raise error on failure
      #
      def execute_command(command, description: nil, interactive: false, silent_stderr: false, allow_error: false)
        description_message = " on #{description}" if description

        if interactive
          system(command)

          if !$CHILD_STATUS.success? && !allow_error
            raise "Error#{description_message} (exit status: #{$CHILD_STATUS.exitstatus})"
          end
        else
          Open3.popen3(command) do |_, stdout, stderr, wait_thread|
            stdout_content = stdout.read
            stderr_content = stderr.read

            puts stderr_content if stderr_content != '' && !silent_stderr

            if !wait_thread.value.success? && !allow_error
              error_message = stderr_content.lines.first&.strip || "Error running command #{command.inspect}"
              raise "Error#{description_message}: #{error_message}"
            end

            stdout_content.strip
          end
        end
      end
    end
  end
end
