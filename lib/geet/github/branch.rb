# frozen_string_literal: true

module Geet
  module Github
    class Branch
      # See https://developer.github.com/v3/git/refs/#delete-a-reference
      #
      def self.delete(name, api_interface, **)
        api_path = "git/refs/heads/#{name}"

        api_interface.send_request(api_path, http_method: :delete)
      end
    end
  end
end
