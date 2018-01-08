# frozen_string_literal: true

require 'shellwords'

module Geet
  module Utils
    # Represents the git program interface; used for performing git operations.
    #
    class Git
      def initialize(repository)
        @repository = repository
      end

      # Return the commit shas between HEAD and `limit`, excluding the already applied commits
      # (which start with `-`)
      #
      def cherry(limit)
        raw_commits = `git cherry #{limit.shellescape}`.strip

        raw_commits.split("\n").grep(/^\+/).map { |line| line[3..-1] }
      end

      # Show the description ("<subject>\n\n<body>") for the given git object.
      #
      def show_description(object)
        `git show --quiet --format='%s\n\n%b' #{object.shellescape}`.strip
      end
    end
  end
end
