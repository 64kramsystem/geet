# frozen_string_literal: true

module Geet
  module Services
    class CreateGist
      include Geet::Helpers::OsHelper

      API_TOKEN_KEY = 'GITHUB_API_TOKEN'
      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      def initialize(out: $stdout)
        @out = out

        api_token = extract_env_api_token
        @api_interface = Geet::Github::ApiInterface.new(api_token)
      end

      # options:
      #   :description
      #   :publik:      defaults to false
      #   :open_browser defaults to true
      #
      def execute(full_filename, stdin: false, description: nil, publik: false, open_browser: false)
        content = stdin ? $stdin.read : IO.read(full_filename)

        gist_access = publik ? 'public' : 'private'
        @out.puts "Creating a #{gist_access} gist..."

        filename = File.basename(full_filename)
        gist = Geet::Github::Gist.create(filename, content, @api_interface, description:, publik:)

        if open_browser
          open_file_with_default_application(gist.link)
        else
          @out.puts "Gist address: #{gist.link}"
        end
      end

      private

      def extract_env_api_token
        ENV[API_TOKEN_KEY] || raise("#{API_TOKEN_KEY} not set!")
      end
    end
  end
end
