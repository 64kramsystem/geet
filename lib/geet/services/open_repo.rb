# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    # Open in the browser the current repository.
    #
    class OpenRepo
      extend T::Sig

      include Helpers::OsHelper

      DEFAULT_GIT_CLIENT = Utils::GitClient.new

      sig { params(repository: Git::Repository, out: IO, git_client: Utils::GitClient).void }
      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      sig { params(upstream: T::Boolean).returns(String) }
      def execute(upstream: false)
        remote_options = upstream ? {name: Utils::GitClient::UPSTREAM_NAME} : {}

        repo_url = @git_client.remote(**remote_options)
        repo_url = convert_repo_url_to_http_protocol(repo_url)

        open_file_with_default_application(repo_url)

        repo_url
      end

      private

      # The repository URL may be in any of the git/http protocols.
      #
      sig { params(repo_url: String).returns(String) }
      def convert_repo_url_to_http_protocol(repo_url)
        case repo_url
        when /https:/
        when /git@/
        else
          # Minimal error, due to match guaranteed by GitClient#remote.
          raise
        end

        domain, _, path = T.must(repo_url.match(Utils::GitClient::REMOTE_URL_REGEX))[2..4]

        "https://#{domain}/#{path}"
      end
    end
  end
end
