# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    class CreateGist
      extend T::Sig

      include Geet::Helpers::OsHelper

      API_TOKEN_KEY = "GITHUB_API_TOKEN"
      DEFAULT_GIT_CLIENT = Geet::Utils::GitClient.new

      sig { params(out: T.any(IO, StringIO)).void }
      def initialize(out: $stdout)
        @out = T.let(out, T.any(IO, StringIO))

        api_token = extract_env_api_token
        @api_interface = T.let(Geet::Github::ApiInterface.new(api_token), Geet::Github::ApiInterface)
      end

      # options:
      #   :description
      #   :publik:      defaults to false
      #   :open_browser defaults to true
      #
      sig {
        params(
          full_filename: String,
          stdin: T::Boolean,
          description: T.nilable(String),
          publik: T::Boolean,
          open_browser: T::Boolean
        ).void
      }
      def execute(full_filename, stdin: false, description: nil, publik: false, open_browser: false)
        content = stdin ? $stdin.read : IO.read(full_filename)

        gist_access = publik ? "public" : "private"
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

      sig { returns(String) }
      def extract_env_api_token
        ENV[API_TOKEN_KEY] || raise("#{API_TOKEN_KEY} not set!")
      end
    end
  end
end
