# frozen_string_literal: true
# typed: strict

module Geet
  module Gitlab
    class PR
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :number

      sig { returns(String) }
      attr_reader :title

      sig { returns(String) }
      attr_reader :link

      sig {
        params(
          number: Integer,
          api_interface: ApiInterface,
          title: String,
          link: String
        ).void
      }
      def initialize(number, api_interface, title, link)
        @number = number
        @api_interface = api_interface
        @title = title
        @link = link
      end

      # See https://docs.gitlab.com/ee/api/merge_requests.html#list-merge-requests
      #
      sig {
        params(
          api_interface: ApiInterface,
          milestone: T.nilable(Milestone),
          assignee: T.nilable(User),
          # Required only for API compatibility. it's not required; if passed, it's only checked
          # against the API path to make sure it's correct.
          owner: T.nilable(String),
          head: T.nilable(String)
        ).returns(T::Array[PR])
      }
      def self.list(api_interface, milestone: nil, assignee: nil, owner: nil, head: nil)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/merge_requests"

        check_list_owner!(api_interface, owner) if owner

        request_params = {}
        request_params[:assignee_id] = assignee.id if assignee
        request_params[:milestone] = milestone.title if milestone
        request_params[:source_branch] = head if head

        response = T.cast(
          api_interface.send_request(api_path, params: request_params, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |issue_data, result|
          number = T.cast(issue_data.fetch('iid'), Integer)
          title = T.cast(issue_data.fetch('title'), String)
          link = T.cast(issue_data.fetch('web_url'), String)

          new(number, api_interface, title, link)
        end
      end

      # See https://docs.gitlab.com/ee/api/notes.html#create-new-merge-request-note
      #
      sig { params(comment: String).void }
      def comment(comment)
        api_path = "projects/#{@api_interface.path_with_namespace(encoded: true)}/merge_requests/#{number}/notes"
        request_data = { body: comment }

        @api_interface.send_request(api_path, data: request_data)
      end

      # See https://docs.gitlab.com/ee/api/merge_requests.html#accept-mr
      #
      sig {
        params(
          merge_method: T.nilable(String)
        ).void
      }
      def merge(merge_method: nil)
        raise ArgumentError, "GitLab does not support the merge_method parameter" if merge_method

        api_path = "projects/#{@api_interface.path_with_namespace(encoded: true)}/merge_requests/#{number}/merge"

        @api_interface.send_request(api_path, http_method: :put)
      end

      class << self
        extend T::Sig

        private

        sig {
          params(
            api_interface: ApiInterface,
            owner: String
          ).void
        }
        def check_list_owner!(api_interface, owner)
          if !api_interface.path_with_namespace.start_with?("#{owner}/")
            raise "Mismatch owner/API path!: #{owner}<>#{api_interface.path_with_namespace}"
          end
        end
      end
    end # PR
  end # Gitlab
end # Geet
