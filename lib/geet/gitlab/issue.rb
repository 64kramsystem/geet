# frozen_string_literal: true
# typed: strict

module Geet
  module Gitlab
    class Issue
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
          title: String,
          link: String
        ).void
      }
      def initialize(number, title, link)
        @number = number
        @title = title
        @link = link
      end

      # See https://docs.gitlab.com/ee/api/issues.html#list-issues
      #
      sig {
        params(
          api_interface: ApiInterface,
          assignee: T.nilable(User),
          milestone: T.nilable(Milestone)
        ).returns(T::Array[Issue])
      }
      def self.list(api_interface, assignee: nil, milestone: nil)
        api_path = "projects/#{api_interface.path_with_namespace(encoded: true)}/issues"

        request_params = {}
        request_params[:assignee_id] = assignee.id if assignee
        request_params[:milestone] = milestone.title if milestone

        response = T.cast(
          api_interface.send_request(api_path, params: request_params, multipage: true),
          T::Array[T::Hash[String, T.untyped]]
        )

        response.map do |issue_data, result|
          number = T.cast(issue_data.fetch('iid'), Integer)
          title = T.cast(issue_data.fetch('title'), String)
          link = T.cast(issue_data.fetch('web_url'), String)

          new(number, title, link)
        end
      end
    end
  end
end
