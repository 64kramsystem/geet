# frozen_string_literal: true

require 'English'
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

      def execute_command(description, *command_tokens)
        system(*command_tokens.map(&:shellescape))

        raise "Error during #{description} (exit status: #{$CHILD_STATUS.exitstatus})" if !$CHILD_STATUS.success?
      end
    end
  end
end
