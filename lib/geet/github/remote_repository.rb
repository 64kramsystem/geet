# frozen_string_literal: true
# typed: strict

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
      extend T::Sig

      # Nil if the repository is not a fork.
      #
      sig { returns(T.nilable(String)) }
      attr_reader :parent_path

      sig {
        params(
          api_interface: Geet::Github::ApiInterface,
          parent_path: T.nilable(String)
        ).void
      }
      def initialize(api_interface, parent_path: nil)
        @api_interface = api_interface
        @parent_path = parent_path
      end

      # Get the repository parent path.
      #
      # https://docs.github.com/en/rest/reference/repos#get-a-repository
      #
      sig {
        params(
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::RemoteRepository)
      }
      def self.find(api_interface)
        api_path = "/repos/#{api_interface.repository_path}"

        response = T.cast(api_interface.send_request(api_path), T::Hash[String, T.untyped])

        parent_hash = T.cast(response["parent"], T.nilable(T::Hash[String, T.untyped]))
        parent_path = T.cast(parent_hash&.fetch("full_name)"), T.nilable(String))

        new(api_interface, parent_path:)
      end
    end # module RemoteRepository
  end # module GitHub
end # module Geet
