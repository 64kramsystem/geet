# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    # Add the upstream repository to the current repository (configuration).
    #
    class AddUpstreamRepo
      extend T::Sig

      DEFAULT_GIT_CLIENT = Utils::GitClient.new

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO), git_client: Utils::GitClient).void }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      sig { void }
      def execute
        raise "Upstream remote already existing!" if @git_client.remote_defined?(Utils::GitClient::UPSTREAM_NAME)

        parent_path = @repository.parent_path

        if parent_path
          parent_url = compose_parent_url(parent_path)

          @git_client.add_remote(Utils::GitClient::UPSTREAM_NAME, parent_url)
        else
          raise "The repository has no upstream!"
        end
      end

      private

      # Use the same protocol as the main repository.
      #
      sig { params(parent_path: String).returns((String)) }
      def compose_parent_url(parent_path)
        protocol, domain, separator, _, suffix = @git_client.remote_components

        "#{protocol}#{domain}#{separator}#{parent_path}#{suffix}"
      end
    end
  end
end
