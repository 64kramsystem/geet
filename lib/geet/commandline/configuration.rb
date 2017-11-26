# frozen_string_literal: true

require 'simple_scripting/argv'
require_relative 'commands'

module Geet
  module Commandline
    class Configuration
      include Commands

      # Command options

      GIST_CREATE_OPTIONS = [
        ['-p', '--public'],
        ['-B', '--no-browse', "Don't open the gist link in the browser after creation"],
        'filename',
        '[description]'
      ].freeze

      ISSUE_CREATE_OPTIONS = [
        ['-n', '--no-open-issue',                           "Don't open the issue link in the browser after creation"],
        ['-l', '--label-patterns "bug,help wanted"',        'Label patterns'],
        ['-m', '--milestone number_or_pattern',             'Milestone number or description pattern'],
        ['-a', '--assignee-patterns john,tom,adrian,kevin', 'Assignee login patterns. Defaults to authenticated user'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        'title',
        'description'
      ].freeze

      ISSUE_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      LABEL_LIST_OPTIONS = [
      ].freeze

      MILESTONE_LIST_OPTIONS = [
      ].freeze

      PR_CREATE_OPTIONS = [
        ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
        ['-l', '--label-patterns "legacy,code review"',     'Label patterns'],
        ['-m', '--milestone number_or_pattern',             'Milestone number or description pattern'],
        ['-r', '--reviewer-patterns john,tom,adrian,kevin', 'Reviewer login patterns'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        'title',
        'description'
      ].freeze

      PR_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      # rubocop:disable Style/MutableConstant
      PR_MERGE_OPTIONS = [
        long_help: 'Merge the PR for the current branch'
      ]

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
          'label' => {
            'list' => LABEL_LIST_OPTIONS,
          },
          'milestone' => {
            'list' => MILESTONE_LIST_OPTIONS,
          },
          'pr' => {
            'create' => PR_CREATE_OPTIONS,
            'list' => PR_LIST_OPTIONS,
            'merge' => PR_MERGE_OPTIONS,
          },
        )
      end
    end
  end
end
