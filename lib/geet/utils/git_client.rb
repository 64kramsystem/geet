# frozen_string_literal: true

require 'English'
require 'shellwords'
require_relative '../helpers/os_helper'

module Geet
  module Utils
    # Represents the git program interface; used for performing git operations.
    #
    class GitClient
      include Geet::Helpers::OsHelper

      ORIGIN_NAME = 'origin'
      UPSTREAM_NAME = 'upstream'

      # Simplified, but good enough, pattern.
      #
      # Relevant matches:
      #
      #   1: protocol + suffix
      #   2: domain
      #   3: domain<>path separator
      #   4: path (repo, project)
      #   5: suffix
      #
      REMOTE_URL_REGEX = %r{
        \A
        (https://|git@)
        (.+?)
        ([/:])
        (.+/.+?)
        (\.git)?
        \Z
      }x

      UPSTREAM_BRANCH_REGEX = %r{\A[^/]+/([^/]+)\Z}

      CLEAN_TREE_MESSAGE_REGEX = /^nothing to commit, working tree clean$/

      def initialize(location: nil)
        @location = location
      end

      ##########################################################################
      # BRANCH/TREE APIS
      ##########################################################################

      # Return the commit shas between HEAD and `limit`, excluding the already applied commits
      # (which start with `-`)
      #
      def cherry(limit)
        raw_commits = execute_git_command("cherry #{limit.shellescape}")

        raw_commits.split("\n").grep(/^\+/).map { |line| line[3..-1] }
      end

      def current_branch
        branch = execute_git_command("rev-parse --abbrev-ref HEAD")

        raise "Couldn't find current branch" if branch == 'HEAD'

        branch
      end

      # Not to be confused with `upstream` repository!
      #
      # This API doesn't reveal if the remote branch is gone.
      #
      # return: nil, if the upstream branch is not configured.
      #
      def upstream_branch
        head_symbolic_ref = execute_git_command("symbolic-ref -q HEAD")

        raw_upstream_branch = execute_git_command("for-each-ref --format='%(upstream:short)' #{head_symbolic_ref.shellescape}").strip

        if raw_upstream_branch != ''
          raw_upstream_branch[UPSTREAM_BRANCH_REGEX, 1] || raise("Unexpected upstream format: #{raw_upstream_branch}")
        else
          nil
        end
      end

      # TODO: May be merged with :upstream_branch, although it would require designing how a gone
      # remote branch is expressed.
      #
      # Sample command output:
      #
      #     ## add_milestone_closing...origin/add_milestone_closing [gone]
      #      M spec/integration/merge_pr_spec.rb
      #
      def upstream_branch_gone?
        git_command = "status -b --porcelain"
        status_output = execute_git_command(git_command)

        # Simplified branch naming pattern. The exact one (see https://stackoverflow.com/a/3651867)
        # is not worth implementing.
        #
        if status_output =~ %r(^## .+\.\.\..+?( \[gone\])?$)
          !!$LAST_MATCH_INFO[1]
        else
          raise "Unexpected git command #{git_command.inspect} output: #{status_output}"
        end
      end

      def working_tree_clean?
        git_message = execute_git_command("status")

        !!(git_message =~ CLEAN_TREE_MESSAGE_REGEX)
      end

      ##########################################################################
      # COMMIT/OBJECT APIS
      ##########################################################################

      # Show the description ("<subject>\n\n<body>") for the given git object.
      #
      def show_description(object)
        execute_git_command("show --quiet --format='%s\n\n%b' #{object.shellescape}")
      end

      ##########################################################################
      # REPOSITORY/REMOTE QUERYING APIS
      ##########################################################################

      # Return the components of the remote, according to REMOTE_URL_REGEX; doesn't include the full
      # match.
      #
      def remote_components(name: nil)
        remote.match(REMOTE_URL_REGEX)[1..]
      end

      # Example: `donaldduck/geet`
      #
      def path(upstream: false)
        remote_name_option = upstream ? {name: UPSTREAM_NAME} : {}

        remote(**remote_name_option)[REMOTE_URL_REGEX, 4]
      end

      def owner
        path.split('/')[0]
      end

      def provider_domain
        # We assume that it's not possible to have origin and upstream on different providers.

        domain = remote()[REMOTE_URL_REGEX, 2]

        raise "Can't identify domain in the provider domain string: #{domain}" if domain !~ /\w+\.\w+/

        domain
      end

      # Returns the URL of the remote with the given name.
      # Sanity checks are performed.
      #
      # The result is in the format `git@github.com:donaldduck/geet.git`
      #
      # options
      #   :name:           remote name; if unspecified, the default remote is used.
      #
      def remote(name: nil)
        remote_url = execute_git_command("ls-remote --get-url #{name}")

        if !remote_defined?(name)
          raise "Remote #{name.inspect} not found!"
        elsif remote_url !~ REMOTE_URL_REGEX
          raise "Unexpected remote reference format: #{remote_url.inspect}"
        end

        remote_url
      end

      # Doesn't sanity check for the remote url format; this action is for querying
      # purposes, any any action that needs to work with the remote, uses #remote.
      #
      def remote_defined?(name)
        remote_url = execute_git_command("ls-remote --get-url #{name}")

        # If the remote is not defined, `git ls-remote` will return the passed value.
        #
        remote_url != name
      end

      ##########################################################################
      # OPERATION APIS
      ##########################################################################

      def checkout(branch)
        execute_git_command("checkout #{branch.shellescape}")
      end

      # Unforced deletion.
      #
      def delete_branch(branch)
        execute_git_command("branch --delete #{branch.shellescape}")
      end

      def rebase
        execute_git_command("rebase")
      end

      # upstream_branch: create an upstream branch.
      #
      def push(upstream_branch: nil)
        upstream_branch_option = "-u #{ORIGIN_NAME} #{upstream_branch.shellescape}" if upstream_branch

        execute_git_command("push #{upstream_branch_option}")
      end

      # Performs pruning.
      #
      def fetch
        execute_git_command("fetch --prune")
      end

      def add_remote(name, url)
        execute_git_command("remote add #{name.shellescape} #{url}")
      end

      ##########################################################################
      # INTERNAL HELPERS
      ##########################################################################

      private

      # If executing a git command without calling this API, don't forget to split `gitdir_option`
      # and use it!
      #
      # options (passed to :execute_command):
      # - allow_error
      # - (others)
      #
      def execute_git_command(command, **options)
        gitdir_option = "-C #{@location.shellescape}" if @location

        execute_command("git #{gitdir_option} #{command}", **options)
      end
    end
  end
end
