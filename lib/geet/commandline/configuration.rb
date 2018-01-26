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

      # SimpleScripting 0.9.3 doesn't allow frozen arrays when hash options are present.
      #
      # rubocop:disable Style/MutableConstant
      ISSUE_CREATE_OPTIONS = [
        ['-n', '--no-open-issue',                           "Don't open the issue link in the browser after creation"],
        ['-l', '--labels "bug,help wanted"',                'Labels'],
        ['-m', '--milestone 1.5.0',                         'Milestone title pattern'],
        ['-a', '--assignees john,tom,adrian,kevin',         'Assignee logins'],
        ['-s', '--summary title_and_description',           'Set the summary (title and optionally description'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        long_help: 'The default editor will be opened for editing title and description.'
      ]

      LABEL_CREATE_OPTIONS = [
        ['-c', '--color color',                             '6-digits hex color; if not specified, a random one is created'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        'name',
      ].freeze

      ISSUE_LIST_OPTIONS = [
        ['-a', '--assignee-pattern john',                   'Assignee pattern'],
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      LABEL_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      MILESTONE_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      PR_CREATE_OPTIONS = [
        ['-A', '--automated-mode',                          "Automate the branch operations (see long help)"],
        ['-n', '--no-open-pr',                              "Don't open the PR link in the browser after creation"],
        ['-l', '--labels "legacy,code review"',             'Labels'],
        ['-m', '--milestone 1.5.0',                         'Milestone title pattern'],
        ['-r', '--reviewers john,tom,adrian,kevin',         'Reviewer logins'],
        ['-s', '--summary title_and_description',           'Set the summary (title and optionally description'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        long_help: <<~STR
          The default editor will be opened for editing title and description; if the PR adds one commit only, the content will be prepopulated with the commit description.

          The "automated mode" will automate branch operations:
          - raise an error if the current tree is dirty;
          - if the upstream branch is not present, it will create it, otherwise, it will perform a push.
        STR
      ]

      PR_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      # SimpleScripting 0.9.3 doesn't allow frozen arrays when hash options are present.
      #
      # rubocop:disable Style/MutableConstant
      PR_MERGE_OPTIONS = [
        ['-d', '--delete-branch',                           'Delete the branch after merging'],
        long_help: 'Merge the PR for the current branch'
      ]

      # Commands decoding table

      COMMANDS_DECODING_TABLE = {
        'gist' => {
          'create' => GIST_CREATE_OPTIONS,
        },
        'issue' => {
          'create' => ISSUE_CREATE_OPTIONS,
          'list' => ISSUE_LIST_OPTIONS,
        },
        'label' => {
          'create' => LABEL_CREATE_OPTIONS,
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
      }

      # Public interface

      def decode_argv
        SimpleScripting::Argv.decode(COMMANDS_DECODING_TABLE)
      end
    end
  end
end
