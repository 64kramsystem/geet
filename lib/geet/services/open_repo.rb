# frozen_string_literal: true

require_relative '../helpers/os_helper'

module Geet
  module Services
    # Open in the browser the current repository.
    #
    class OpenRepo
      include Helpers::OsHelper

      DEFAULT_GIT_CLIENT = Utils::GitClient.new

      def initialize(repository, out: $stdout, git_client: DEFAULT_GIT_CLIENT)
        @repository = repository
        @out = out
        @git_client = git_client
      end

      def execute
        repo_url = @git_client.remote
        repo_url = convert_repo_url_to_http_protocol(repo_url)

        open_file_with_default_application(repo_url)

        repo_url
      end

      private

      # The repository URL may be in any of the git/http protocols.
      #
      def convert_repo_url_to_http_protocol(repo_url)
        case repo_url
        when /https:/
        when /git@/
        else
          # Minimal error, due to match guaranteed by GitClient#remote.
          raise
        end

        domain, _, path = repo_url.match(Utils::GitClient::REMOTE_URL_REGEX)[2..4]

        "https://#{domain}/#{path}"
      end
    end
  end
end
