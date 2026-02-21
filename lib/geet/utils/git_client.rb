# frozen_string_literal: true
# typed: strict

require "English"
require "shellwords"

module Geet
  module Utils
    # Represents the git program interface; used for performing git operations.
    #
    class GitClient
      extend T::Sig

      include Geet::Helpers::OsHelper

      ORIGIN_NAME = "origin"
      UPSTREAM_NAME = "upstream"

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

      REMOTE_BRANCH_REGEX = %r{\A[^/]+/(.+)\Z}

      MAIN_BRANCH_CONFIG_ENTRY = "custom.development-branch"

      CLEAN_TREE_MESSAGE_REGEX = /^nothing to commit, working tree clean$/

      sig { params(location: T.nilable(String)).void }
      def initialize(location: nil)
        @location = location
      end

      ##########################################################################
      # BRANCH/TREE APIS
      ##########################################################################

      # Return the commit SHAs between :head and :upstream, excluding the already applied commits
      # (which start with `-`)
      #
      sig {
        params(
          upstream: T.any(String, Symbol),       # pass :main_branch to use the main branch
          head: T.nilable(T.any(String, Symbol)) # pass :main_branch to use the main branch
        )
        .returns(T::Array[String])
      }
      def cherry(upstream, head: nil)
        upstream = main_branch if upstream == :main_branch
        head = main_branch if head == :main_branch

        git_params = [upstream, head].compact.map { |param| param.to_s.shellescape }

        raw_commits = execute_git_command("cherry #{git_params.join(' ')}")

        raw_commits.split("\n").grep(/^\+/).map { |line| T.must(line[3..-1]) }
      end

      sig { returns(String) }
      def current_branch
        branch = execute_git_command("rev-parse --abbrev-ref HEAD")

        raise "Couldn't find current branch" if branch == "HEAD"

        branch
      end

      # This API doesn't reveal if the remote branch is gone.
      #
      # return: nil, if the remote branch is not configured.
      #
      sig {
        params(
          qualify: T::Boolean # include the remote if true, don't otherwise
        )
        .returns(T.nilable(String))
      }
      def remote_branch(qualify: false)
        head_symbolic_ref = execute_git_command("symbolic-ref -q HEAD")

        raw_remote_branch = execute_git_command("for-each-ref --format='%(upstream:short)' #{head_symbolic_ref.shellescape}").strip

        if raw_remote_branch != ""
          if qualify
            raw_remote_branch
          else
            raw_remote_branch[REMOTE_BRANCH_REGEX, 1] || raise("Unexpected remote branch format: #{raw_remote_branch}")
          end
        else
          nil
        end
      end

      # TODO: May be merged with :remote_branch, although it would require designing how a gone
      # remote branch is expressed.
      #
      # Sample command output:
      #
      #     ## add_milestone_closing...origin/add_milestone_closing [gone]
      #      M spec/integration/merge_pr_spec.rb
      #
      sig { returns(T::Boolean) }
      def remote_branch_gone?
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

      # See https://saveriomiroddi.github.io/Conveniently-Handling-non-master-development-default-branches-in-git-hub
      #
      sig { returns(String) }
      def main_branch
        branch_name = execute_git_command("config --get #{MAIN_BRANCH_CONFIG_ENTRY}", allow_error: true)

        if branch_name.empty?
          full_branch_name = execute_git_command("rev-parse --abbrev-ref #{ORIGIN_NAME}/HEAD")
          T.must(full_branch_name.split("/").last)
        else
          branch_name
        end
      end

      # List of different commits between local and corresponding remote branch.
      #
      sig { returns(String) }
      def remote_branch_diff_commits
        remote_branch = T.must(remote_branch(qualify: true))

        execute_git_command("rev-list #{remote_branch.shellescape}..HEAD")
      end

      sig { returns(String) }
      def remote_branch_diff
        remote_branch = T.must(remote_branch(qualify: true))

        execute_git_command("diff #{remote_branch.shellescape}")
      end

      sig { returns(T::Boolean) }
      def working_tree_clean?
        git_message = execute_git_command("status")

        !!(git_message =~ CLEAN_TREE_MESSAGE_REGEX)
      end

      ##########################################################################
      # COMMIT/OBJECT APIS
      ##########################################################################

      # Show the description ("<subject>\n\n<body>") for the given git object.
      #
      sig { params(object: String).returns(String) }
      def show_description(object)
        execute_git_command("show --quiet --format='%s\n\n%b' #{object.shellescape}")
      end

      ##########################################################################
      # REPOSITORY/REMOTE QUERYING APIS
      ##########################################################################

      # Return the components of the remote, according to REMOTE_URL_REGEX; doesn't include the full
      # match.
      #
      sig {
        params(
          name: T.nilable(String) # remote name
        )
        .returns(T::Array[T.nilable(String)])
      }
      def remote_components(name: nil)
        T.must(remote.match(REMOTE_URL_REGEX))[1..]
      end

      # Example: `donaldduck/geet`
      #
      sig { params(upstream: T::Boolean).returns(String) }
      def path(upstream: false)
        remote_name_option = upstream ? {name: UPSTREAM_NAME} : {}

        T.must(remote(**remote_name_option)[REMOTE_URL_REGEX, 4])
      end

      sig { returns(String) }
      def owner
        T.must(path.split("/")[0])
      end

      # Returns the URL of the remote with the given name.
      # Sanity checks are performed.
      #
      # The result is in the format `git@github.com:donaldduck/geet.git`
      #
      sig {
        params(
          name: T.nilable(String) # remote name; if unspecified, the default remote is used
        )
        .returns(String)
      }
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
      sig { params(name: T.nilable(String)).returns(T::Boolean) }
      def remote_defined?(name)
        remote_url = execute_git_command("ls-remote --get-url #{name}")

        # If the remote is not defined, `git ls-remote` will return the passed value.
        #
        remote_url != name
      end

      ##########################################################################
      # OPERATION APIS
      ##########################################################################

      sig { params(branch: String).returns(String) }
      def checkout(branch)
        execute_git_command("checkout #{branch.shellescape}")
      end

      sig { params(branch: String, force: T::Boolean).returns(String) }
      def delete_branch(branch, force:)
        force_option = "--force" if force

        execute_git_command("branch --delete #{force_option} #{branch.shellescape}")
      end

      sig { returns(String) }
      def rebase
        execute_git_command("rebase")
      end

      sig {
        params(
          remote_branch: T.nilable(String), # create an upstream branch
          force: T::Boolean
        )
        .returns(String)
      }
      def push(remote_branch: nil, force: false)
        remote_branch_option = "-u #{ORIGIN_NAME} #{remote_branch.shellescape}" if remote_branch

        execute_git_command("push #{"--force" if force} #{remote_branch_option}")
      end

      # Performs pruning.
      #
      sig { returns(String) }
      def fetch
        execute_git_command("fetch --prune")
      end

      sig { params(name: String, url: String).returns(String) }
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
      sig {
        params(
          command: String,
          options: T.untyped # passed to :execute_command (e.g., allow_error)
        )
        .returns(String)
      }
      def execute_git_command(command, **options)
        gitdir_option = "-C #{@location.shellescape}" if @location

        T.must(execute_command("git #{gitdir_option} #{command}", **options))
      end
    end
  end
end
