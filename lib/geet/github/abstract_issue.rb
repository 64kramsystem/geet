# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    # For clarity, in this class we keep only the identical logic between the subclasses, but
    # other methods could be moved in here at some complexity cost.
    class AbstractIssue
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :number

      sig { returns(String) }
      attr_reader :title

      sig { returns(String) }
      attr_reader :link

      sig {
        overridable.params(
          number: Integer,
          api_interface: Geet::Github::ApiInterface,
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

      # See https://developer.github.com/v3/issues/#list-issues-for-a-repository
      #
      # This works both for Issues and PRs, however, when the `/pulls` API (path) is used, additional
      # information is provided (e.g. `head`).
      #
      sig {
        overridable.params(
          api_interface: Geet::Github::ApiInterface,
          milestone: T.nilable(Geet::Github::Milestone),
          assignee: T.nilable(Geet::Github::User),
          type_filter:
            T.nilable(
              T.proc.params(issue_data: T::Hash[String, T.untyped]).returns(T::Boolean)
            )
        ).returns(T::Array[Geet::Github::AbstractIssue]) }
      def self.list(api_interface, milestone: nil, assignee: nil, &type_filter)
        api_path = 'issues'

        request_params = {}
        request_params[:milestone] = milestone.number if milestone
        request_params[:assignee] = assignee.username if assignee

        response = T.cast(api_interface.send_request(api_path, params: request_params, multipage: true), T::Array[T::Hash[String, T.untyped]])

        abstract_issues_list = response.map do |issue_data|
          number = T.cast(issue_data.fetch('number'), Integer)
          title = T.cast(issue_data.fetch('title'), String)
          link = T.cast(issue_data.fetch('html_url'), String)

          new(number, api_interface, title, link) if type_filter.nil? || type_filter.call(issue_data)
        end

        abstract_issues_list.compact
      end

      sig { params(users: T.any(String, T::Array[String])).void }
      def assign_users(users)
        api_path = "issues/#{@number}/assignees"
        request_data = {assignees: Array(users)}

        @api_interface.send_request(api_path, data: request_data)
      end

      sig { params(labels: T::Array[String]).void }
      def add_labels(labels)
        api_path = "issues/#{@number}/labels"

        @api_interface.send_request(api_path, data: labels)
      end

      # See https://developer.github.com/v3/issues/comments/#create-a-comment
      #
      sig { params(comment: String).void }
      def comment(comment)
        api_path = "issues/#{@number}/comments"
        request_data = {body: comment}

        @api_interface.send_request(api_path, data: request_data)
      end

      # See https://developer.github.com/v3/issues/#edit-an-issue
      #
      sig { params(milestone: Integer).void }
      def edit(milestone:)
        request_data = {milestone: milestone}
        api_path = "issues/#{@number}"

        @api_interface.send_request(api_path, data: request_data, http_method: :patch)
      end
    end
  end
end
