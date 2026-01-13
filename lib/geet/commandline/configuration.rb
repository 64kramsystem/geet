# frozen_string_literal: true

require 'simple_scripting/argv'

module Geet
  module Commandline
    class Configuration
      include Commands

      # Command options

      GIST_CREATE_OPTIONS = [
        ['-p', '--public'],
        ['-s', '--stdin',     "Read content from stdin"],
        ['-o', '--open-browser', "Open the gist link in the browser after creation"],
        'filename',
        '[description]'
      ].freeze

      # SimpleScripting 0.9.3 doesn't allow frozen arrays when hash options are present.
      #
      # rubocop:disable Style/MutableConstant
      ISSUE_CREATE_OPTIONS = [
        ['-o', '--open-browser',                            "Don't open the issue link in the browser after creation"],
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
        ['-a', '--assignee john',                           'Assignee login'],
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      LABEL_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      MILESTONE_CLOSE_OPTIONS = [
        long_help: 'Close milestones.'
      ]

      MILESTONE_CREATE_OPTIONS = [
        'title',
        long_help: 'Create a milestone.'
      ]

      MILESTONE_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      PR_COMMENT_OPTIONS = [
        ['-o', '--open-browser',                            "Don't open the PR link in the browser after creation"],
        ['-u', '--upstream',                                'Comment on the upstream repository'],
        'comment',
        long_help: 'Add a comment to the PR for the current branch.'
      ]

      PR_CREATE_OPTIONS = [
        ['-o', '--open-browser',                            "Don't open the PR link in the browser after creation"],
        ['-b', '--base develop',                            "Specify the base branch; defaults to the main branch"],
        ['-d', '--draft',                                   "Create as draft"],
        ['-l', '--labels "legacy,code review"',             'Labels'],
        ['-m', '--milestone 1.5.0',                         'Milestone title pattern'],
        ['-r', '--reviewers john,tom,adrian,kevin',         'Reviewer logins'],
        ['-s', '--summary title_and_description',           'Set the summary (title and optionally description'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        long_help: <<~STR
          The default editor will be opened for editing title and description; if the PR adds one commit only, the content will be prepopulated with the commit description.

          The operation is aborted if the current tree is dirty.

          Before creating the PR, the local branch is pushed; if the remote branch is not present, it is created.
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
        ['-s', '--squash',                                  'Squash merge'],
        ['-u', '--upstream',                                'List on the upstream repository'],
        long_help: 'Merge the PR for the current branch'
      ]

      PR_OPEN_OPTIONS = [
        ['-u', '--upstream',                                'Open on the upstream repository'],
        long_help: 'Open in the browser the PR for the current branch'
      ]

      REPO_ADD_UPSTREAM_OPTIONS = [
        long_help: 'Add the upstream repository to the current repository (configuration).'
      ]

      REPO_OPEN_OPTIONS = [
        ['-u', '--upstream',                                'Open the upstream repository'],
        long_help: 'Open the current repository in the browser'
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
          'close' => MILESTONE_CLOSE_OPTIONS,
          'create' => MILESTONE_CREATE_OPTIONS,
          'list' => MILESTONE_LIST_OPTIONS,
        },
        'pr' => {
          'comment' => PR_COMMENT_OPTIONS,
          'create' => PR_CREATE_OPTIONS,
          'list' => PR_LIST_OPTIONS,
          'merge' => PR_MERGE_OPTIONS,
          'open' => PR_OPEN_OPTIONS,
        },
        'repo' => {
          'add_upstream' => REPO_ADD_UPSTREAM_OPTIONS,
          'open' => REPO_OPEN_OPTIONS,
        },
      }

      # Public interface

      def decode_argv
        SimpleScripting::Argv.decode(COMMANDS_DECODING_TABLE)
      end
    end
  end
end
