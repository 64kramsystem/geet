# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class Issue < Geet::Github::AbstractIssue
      extend T::Sig

      sig {
        params(
          title: String,
          description: String,
          api_interface: Geet::Github::ApiInterface,
        ).returns(Geet::Github::Issue)
      }
      def self.create(title, description, api_interface)
        api_path = 'issues'
        request_data = {title:, body: description}

        response = T.cast(
          api_interface.send_request(api_path, data: request_data),
          T::Hash[String, T.untyped]
        )

        issue_number = T.cast(response.fetch('number'), Integer)
        title = T.cast(response.fetch('title'), String)
        link = T.cast(response.fetch('html_url'), String)

        new(issue_number, api_interface, title, link)
      end

      sig {
        override.params(
          api_interface: Geet::Github::ApiInterface,
          assignee: T.nilable(Geet::Github::User),
          milestone: T.nilable(Geet::Github::Milestone),
          type_filter:
            T.nilable(
              T.proc.params(issue_data: T::Hash[String, T.untyped]).returns(T::Boolean)
            )
        ).returns(T::Array[Geet::Github::AbstractIssue])
      }
      def self.list(api_interface, assignee: nil, milestone: nil, &type_filter)
        super do |issue_data|
          !issue_data.key?('pull_request')
        end
      end
    end
  end
end
