# frozen_string_literal: true

require 'shellwords'
require_relative '../helpers/os_helper.rb'

module Geet
  module Utils
    # Represents the git program interface; used for performing git operations.
    #
    class GitClient
      include Geet::Helpers::OsHelper

      ORIGIN_NAME   = 'origin'
      UPSTREAM_NAME = 'upstream'

      # For simplicity, we match any character except the ones the separators.
      REMOTE_ORIGIN_REGEX = %r{
        \A
        (?:https://(.+?)/|git@(.+?):)
        ([^/]+/.*?)
        (?:\.git)?
        \Z
      }x

      def initialize(location: nil)
        @location = location
      end

      # Return the commit shas between HEAD and `limit`, excluding the already applied commits
      # (which start with `-`)
      #
      def cherry(limit)
        raw_commits = execute_command("git cherry #{limit.shellescape}")

        raw_commits.split("\n").grep(/^\+/).map { |line| line[3..-1] }
      end

      def current_branch
        gitdir_option = "--git-dir #{@location.shellescape}/.git" if @location
        branch = execute_command("git #{gitdir_option} rev-parse --abbrev-ref HEAD")

        raise "Couldn't find current branch" if branch == 'HEAD'

        branch
      end

      # Example: `donaldduck/geet`
      #
      def path(upstream: false)
        remote_name = upstream ? UPSTREAM_NAME : ORIGIN_NAME

        remote(remote_name)[REMOTE_ORIGIN_REGEX, 3]
      end

      def provider_domain
        # We assume that it's not possible to have origin and upstream on different providers.
        #
        remote_url = remote(ORIGIN_NAME)

        domain = remote_url[REMOTE_ORIGIN_REGEX, 1] || remote_url[REMOTE_ORIGIN_REGEX, 2]

        raise "Can't identify domain in the provider domain string: #{domain}" if domain !~ /(.*)\.\w+/

        domain
      end

      # Returns the URL of the remote with the given name.
      # Sanity checks are performed.
      #
      # The result is in the format `git@github.com:donaldduck/geet.git`
      #
      def remote(name)
        gitdir_option = "--git-dir #{@location.shellescape}/.git" if @location
        remote_url = execute_command("git #{gitdir_option} ls-remote --get-url #{name}")

        if remote_url == name
          raise "Remote #{name.inspect} not found!"
        elsif remote_url !~ REMOTE_ORIGIN_REGEX
          raise "Unexpected remote reference format: #{remote_url.inspect}"
        end

        remote_url
      end

      # Doesn't sanity check for the remote url format; this action is for querying
      # purposes, any any action that needs to work with the remote, uses #remote.
      #
      def remote_defined?(name)
        gitdir_option = "--git-dir #{@location.shellescape}/.git" if @location
        remote_url = execute_command("git #{gitdir_option} ls-remote --get-url #{name}")

        # If the remote is not define, `git ls-remote` will return the passed value.
        remote_url != name
      end

      # Show the description ("<subject>\n\n<body>") for the given git object.
      #
      def show_description(object)
        execute_command("git show --quiet --format='%s\n\n%b' #{object.shellescape}")
      end
    end
  end
end
