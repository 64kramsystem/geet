# frozen_string_literal: true
# typed: strict

require 'simple_scripting/argv'

module Geet
  module Commandline
    class Configuration
      extend T::Sig

      include Commands

      # Command options

      GIST_CREATE_OPTIONS = [
        ['-p', '--public'],
        ['-s', '--stdin',     "Read content from stdin"],
        ['-o', '--open-browser', "Open the gist link in the browser after creation"],
        'filename',
        '[description]',
      ].freeze

      # SimpleScripting 0.9.3 doesn't allow frozen arrays when hash options are present.
      #
      # rubocop:disable Style/MutableConstant
      ISSUE_CREATE_OPTIONS = T.let([
        ['-o', '--open-browser',                            "Don't open the issue link in the browser after creation"],
        ['-l', '--labels "bug,help wanted"',                'Labels'],
        ['-m', '--milestone 1.5.0',                         'Milestone title pattern'],
        ['-a', '--assignees john,tom,adrian,kevin',         'Assignee logins'],
        ['-s', '--summary title_and_description',           'Set the summary (title and optionally description'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        long_help: 'The default editor will be opened for editing title and description.'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

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

      MILESTONE_CLOSE_OPTIONS = T.let([
        long_help: 'Close milestones.'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      MILESTONE_CREATE_OPTIONS = T.let([
        'title',
        long_help: 'Create a milestone.'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], String)])

      MILESTONE_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      PR_COMMENT_OPTIONS = T.let([
        ['-o', '--open-browser',                            "Don't open the PR link in the browser after creation"],
        ['-u', '--upstream',                                'Comment on the upstream repository'],
        'comment',
        long_help: 'Add a comment to the PR for the current branch.'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String], String)])

      PR_CREATE_OPTIONS = T.let([
        ['-a', '--automerge',                               "Enable automerge (with default strategy)"],
        ['-o', '--open-browser',                            "Don't open the PR link in the browser after creation"],
        ['-b', '--base develop',                            "Specify the base branch; defaults to the main branch"],
        ['-d', '--draft',                                   "Create as draft"],
        ['-l', '--labels "legacy,code review"',             'Labels'],
        ['-m', '--milestone 1.5.0',                         'Milestone title pattern'],
        ['-r', '--reviewers john,tom,adrian,kevin',         'Reviewer logins'],
        ['-s', '--summary title_and_description',           'Set the summary (title and optionally description'],
        ['-u', '--upstream',                                'Create on the upstream repository'],
        long_help: <<~STR,
          The default editor will be opened for editing title and description; if the PR adds one commit only, the content will be prepopulated with the commit description.

          The operation is aborted if the current tree is dirty.

          Before creating the PR, the local branch is pushed; if the remote branch is not present, it is created.
        STR
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      PR_LIST_OPTIONS = [
        ['-u', '--upstream',                                'List on the upstream repository'],
      ].freeze

      # SimpleScripting 0.9.3 doesn't allow frozen arrays when hash options are present.
      #
      # rubocop:disable Style/MutableConstant
      PR_MERGE_OPTIONS = T.let([
        ['-d', '--delete-branch',                           'Delete the branch after merging'],
        ['-s', '--squash',                                  'Squash merge'],
        ['-u', '--upstream',                                'List on the upstream repository'],
        long_help: 'Merge the PR for the current branch'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      PR_OPEN_OPTIONS = T.let([
        ['-u', '--upstream',                                'Open on the upstream repository'],
        long_help: 'Open in the browser the PR for the current branch'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      REPO_ADD_UPSTREAM_OPTIONS = T.let([
        long_help: 'Add the upstream repository to the current repository (configuration).'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      REPO_OPEN_OPTIONS = T.let([
        ['-u', '--upstream',                                'Open the upstream repository'],
        long_help: 'Open the current repository in the browser'
      ], T::Array[T.any(T::Hash[T.untyped, T.untyped], T::Array[String])])

      # Commands decoding table

      COMMANDS_DECODING_TABLE = T.let({
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
      }, T::Hash[T.untyped, T.untyped])

      # Public interface

      sig { returns(T::Array[T.untyped]) }
      def decode_argv
        T.unsafe(SimpleScripting::Argv).decode(COMMANDS_DECODING_TABLE)
      end
    end
  end
end
