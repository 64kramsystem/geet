# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class Branch
      extend T::Sig

      # See https://developer.github.com/v3/git/refs/#delete-a-reference
      #
      sig { params(name: String, api_interface: Geet::Github::ApiInterface).void }
      def self.delete(name, api_interface)
        api_path = "git/refs/heads/#{name}"

        api_interface.send_request(api_path, http_method: :delete)
      end
    end
  end
end
