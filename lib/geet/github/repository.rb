# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class Repository
      extend T::Sig

      sig { returns(String) }
      attr_reader :full_name

      sig { returns(String) }
      attr_reader :html_url

      sig { returns(String) }
      attr_reader :ssh_url

      sig {
        params(
          name: String,
          visibility: String,
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::Repository)
      }
      def self.create(name, visibility, api_interface)
        response = api_interface.send_request("/user/repos", data: {name:, private: visibility == "private"})
        from_response(response, api_interface)
      end

      sig {
        params(
          upstream_path: String,
          name: String,
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::Repository)
      }
      def self.fork(upstream_path, name, api_interface)
        response = api_interface.send_request("/repos/#{upstream_path}/forks", data: {name:})
        from_response(response, api_interface)
      end

      sig {
        params(
          path: String,
          api_interface: Geet::Github::ApiInterface
        ).returns(Geet::Github::Repository)
      }
      def self.fetch(path, api_interface)
        response = api_interface.send_request("/repos/#{path}")
        from_response(response, api_interface)
      end

      sig {
        params(
          response: T::Hash[String, T.untyped],
          api_interface: Geet::Github::ApiInterface
        ).void
      }
      def initialize(response, api_interface)
        @full_name = T.let(T.cast(response.fetch("full_name"), String), String)
        @html_url = T.let(T.cast(response.fetch("html_url"), String), String)
        @ssh_url = T.let(T.cast(response.fetch("ssh_url"), String), String)
        @api_interface = T.let(api_interface, Geet::Github::ApiInterface)
      end

      sig { params(branch: String).void }
      def update_default_branch(branch)
        @api_interface.send_request("/repos/#{@full_name}", data: {default_branch: branch}, http_method: :patch)
      end

      class << self
        extend T::Sig

        private

        sig {
          params(
            response: T.untyped,
            api_interface: Geet::Github::ApiInterface
          ).returns(Geet::Github::Repository)
        }
        def from_response(response, api_interface)
          new(T.cast(response, T::Hash[String, T.untyped]), api_interface)
        end
      end
    end
  end
end
