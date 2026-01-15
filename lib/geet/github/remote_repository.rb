# frozen_string_literal: true

module Geet
  module Github
    # A remote repository. Currently only provides the parent path.
    #
    # It's a difficult choice whether to independently use the repository path, or relying on the one
    # stored in the ApiInterface.
    # The former design is conceptually cleaner, but it practically (as of the current design) introduces
    # duplication. All in all, for simplicity, the latter design is chosen, but is subject to redesign.
    #
    class RemoteRepository
      # Nil if the repository is not a fork.
      #
      attr_reader :parent_path

      def initialize(api_interface, parent_path: nil)
        @api_interface = api_interface
        @parent_path = parent_path
      end

      # Get the repository parent path.
      #
      # https://docs.github.com/en/rest/reference/repos#get-a-repository
      #
      def self.find(api_interface)
        api_path = "/repos/#{api_interface.repository_path}"

        response = api_interface.send_request(api_path)

        parent_path = response['parent']&.fetch("full_name")

        new(api_interface, parent_path:)
      end
    end # module RemoteRepository
  end # module GitHub
end # module Geet
