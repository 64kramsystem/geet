# frozen_string_literal: true

require 'simple_scripting/argv'

module Geet
  module Helpers
    class ConfigurationHelper
      def decode_argv
        SimpleScripting::Argv.decode(
          'pr' => [
            ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
            ['-l', '--label-patterns "legacy,code review"',     'Label patterns'],
            ['-r', '--reviewer-patterns john,tom,adrian,kevin', 'Reviewer login patterns'],
            'title',
            'description'
          ],
        )
      end

      def api_token
        ENV['GITHUB_API_TOKEN'] || raise('Missing $GITHUB_API_TOKEN')
      end
    end
  end
end
