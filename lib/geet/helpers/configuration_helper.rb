# frozen_string_literal: true

require 'simple_scripting/argv'

module Geet
  module Helpers
    class ConfigurationHelper
      ISSUE_OPTIONS = [
        ['-n', '--no-open-issue',                           "Don't open the issue link in the browser after creation"],
        ['-l', '--label-patterns "bug,help wanted"',        'Label patterns'],
        ['-a', '--assignee-patterns john,tom,adrian,kevin', 'Assignee login patterns. Defaults to authenticated user'],
        'title',
        'description'
      ].freeze

      PR_OPTIONS = [
        ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
        ['-l', '--label-patterns "legacy,code review"',     'Label patterns'],
        ['-r', '--reviewer-patterns john,tom,adrian,kevin', 'Reviewer login patterns'],
        'title',
        'description'
      ].freeze

      def decode_argv
        SimpleScripting::Argv.decode(
          'issue' => ISSUE_OPTIONS,
          'pr' => PR_OPTIONS,
        )
      end

      def api_token
        ENV['GITHUB_API_TOKEN'] || raise('Missing $GITHUB_API_TOKEN')
      end
    end
  end
end
