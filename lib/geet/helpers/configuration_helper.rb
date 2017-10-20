# frozen_string_literal: true

require 'simple_scripting/argv'

module Geet
  module Helpers
    class ConfigurationHelper
      # Commands

      GIST_CREATE_COMMAND = 'gist.create'
      ISSUE_CREATE_COMMAND = 'issue.create'
      ISSUE_LIST_COMMAND = 'issue.list'
      PR_CREATE_COMMAND = 'pr.create'
      PR_LIST_COMMAND = 'pr.list'

      # Command options

      GIST_CREATE_OPTIONS = [
        ['-p', '--public'],
        ['-B', '--no-browse', "Don't open the gist link in the browser after creation"],
        'filename',
        '[description]'
      ]

      ISSUE_CREATE_OPTIONS = [
        ['-n', '--no-open-issue',                           "Don't open the issue link in the browser after creation"],
        ['-l', '--label-patterns "bug,help wanted"',        'Label patterns'],
        ['-a', '--assignee-patterns john,tom,adrian,kevin', 'Assignee login patterns. Defaults to authenticated user'],
        'title',
        'description'
      ].freeze

      ISSUE_LIST_OPTIONS = [
      ].freeze

      PR_CREATE_OPTIONS = [
        ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
        ['-l', '--label-patterns "legacy,code review"',     'Label patterns'],
        ['-r', '--reviewer-patterns john,tom,adrian,kevin', 'Reviewer login patterns'],
        'title',
        'description'
      ].freeze

      PR_LIST_OPTIONS = [
      ].freeze

      # Public interface

      def decode_argv
        SimpleScripting::Argv.decode(
          'gist' => {
            'create' => GIST_CREATE_OPTIONS,
          },
          'issue' => {
            'create' => ISSUE_CREATE_OPTIONS,
            'list' => ISSUE_LIST_OPTIONS,
          },
          'pr' => {
            'create' => PR_CREATE_OPTIONS,
            'list' => PR_LIST_OPTIONS,
          },
        )
      end

      def api_token
        ENV['GITHUB_API_TOKEN'] || raise('Missing $GITHUB_API_TOKEN')
      end
    end
  end
end
