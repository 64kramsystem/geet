# frozen_string_literal: true
# typed: strict

module Geet
  module Github
    class PR < AbstractIssue
      extend T::Sig

      sig { returns(T.nilable(String)) }
      attr_reader :node_id

      sig {
        override.params(
          number: Integer,
          api_interface: Geet::Github::ApiInterface,
          title: String,
          link: String,
          node_id: T.nilable(String)
        ).void
      }
      def initialize(number, api_interface, title, link, node_id: nil)
        super(number, api_interface, title, link)
        @node_id = node_id
      end

      # See https://developer.github.com/v3/pulls/#create-a-pull-request
      #
      sig {
        params(
          title: String,
          description: String,
          head: String,
          api_interface: Geet::Github::ApiInterface,
          base: String,
          draft: T::Boolean
        ).returns(Geet::Github::PR)
      }
      def self.create(title, description, head, api_interface, base, draft: false)
        api_path = 'pulls'

        if api_interface.upstream?
          authenticated_user = Geet::Github::User.authenticated(api_interface).username
          head = "#{authenticated_user}:#{head}"
        end

        request_data = { title:, body: description, head:, base:, draft: }

        response = T.cast(api_interface.send_request(api_path, data: request_data), T::Hash[String, T.untyped])

        number = T.cast(response.fetch('number'), Integer)
        title = T.cast(response.fetch('title'), String)
        link = T.cast(response.fetch('html_url'), String)
        node_id = T.cast(response['node_id'], T.nilable(String))

        new(number, api_interface, title, link, node_id:)
      end

      # See https://developer.github.com/v3/pulls/#list-pull-requests
      #
      sig {
        override.params(
          api_interface: Geet::Github::ApiInterface,
          milestone: T.nilable(Geet::Github::Milestone),
          assignee: T.nilable(Geet::Github::User),
          owner: T.nilable(String),
          head: T.nilable(String),
          type_filter:
            T.nilable(
              T.proc.params(issue_data: T::Hash[String, T.untyped]).returns(T::Boolean)
            )
        ).returns(T::Array[Geet::Github::PR])
      }
      def self.list(api_interface, milestone: nil, assignee: nil, owner: nil, head: nil, &type_filter)
        check_list_params!(milestone, assignee, head)

        if head
          api_path = 'pulls'

          # Technically, the upstream approach could be used for both, but it's actually good to have
          # both of them as reference.
          #
          # For upstream pulls, the owner is the authenticated user, otherwise, the repository owner.
          #
          response = if api_interface.upstream?
            unfiltered_response = T.cast(
              api_interface.send_request(api_path, multipage: true),
              T::Array[T::Hash[String, T.untyped]]
            )

            # VERY weird. From the docs, it's not clear if the user/org is required in the `head` parameter,
            # but:
            #
            # - if it isn't included (eg. `anything`), the parameter is ignored
            # - if it's included (eg. `saveriomiroddi:local_branch_name`), an empty resultset is returned.
            #
            # For this reason, we can't use that param, and have to filter manually.
            #
            unfiltered_response.select do |pr_data|
              pr_head = T.cast(pr_data.fetch('head'), T::Hash[String, T.untyped])
              label = T.cast(pr_head.fetch('label'), String)

              label == "#{owner}:#{head}"
            end
          else
            request_params = { head: "#{owner}:#{head}" }

            T.cast(
              api_interface.send_request(api_path, params: request_params, multipage: true),
              T::Array[T::Hash[String, T.untyped]]
            )
          end

          response.map do |pr_data|
            number = T.cast(pr_data.fetch('number'), Integer)
            title = T.cast(pr_data.fetch('title'), String)
            link = T.cast(pr_data.fetch('html_url'), String)

            new(number, api_interface, title, link)
          end
        else
          result = super(api_interface, milestone:, assignee:) do |issue_data|
            issue_data.key?('pull_request')
          end

          T.cast(result, T::Array[Geet::Github::PR])
        end
      end

      # See https://developer.github.com/v3/pulls/#merge-a-pull-request-merge-button
      #
      sig {
        params(
          merge_method: T.nilable(String)
        ).void
      }
      def merge(merge_method: nil)
        api_path = "pulls/#{number}/merge"
        request_data = { merge_method: } if merge_method

        @api_interface.send_request(api_path, http_method: :put, data: request_data)
      end

      sig {
        params(
          reviewers: T::Array[String]
        ).void
      }
      def request_review(reviewers)
        api_path = "pulls/#{number}/requested_reviewers"
        request_data = { reviewers: }

        @api_interface.send_request(api_path, data: request_data)
      end

      # Enable auto-merge for this PR using an available merge method.
      # Queries the repository to find allowed merge methods and uses the first available one
      # (see method comment below for the priority).
      # See https://docs.github.com/en/graphql/reference/mutations#enablepullrequestautomerge
      #
      sig { void }
      def enable_automerge
        merge_method = fetch_available_merge_method

        query = <<~GRAPHQL
          mutation($pullRequestId: ID!, $mergeMethod: PullRequestMergeMethod!) {
            enablePullRequestAutoMerge(input: {pullRequestId: $pullRequestId, mergeMethod: $mergeMethod}) {
              pullRequest {
                id
                autoMergeRequest {
                  enabledAt
                  mergeMethod
                }
              }
            }
          }
        GRAPHQL

        variables = { pullRequestId: @node_id, mergeMethod: merge_method }

        @api_interface.send_graphql_request(query, variables:)
      end

      private

      # Query the repository to find the first available merge method.
      # Priority: MERGE > SQUASH > REBASE.
      #
      sig { returns(String) }
      def fetch_available_merge_method
        query = <<~GRAPHQL
          query($owner: String!, $name: String!) {
            repository(owner: $owner, name: $name) {
              mergeCommitAllowed
              squashMergeAllowed
              rebaseMergeAllowed
            }
          }
        GRAPHQL

        owner, name = T.must(@api_interface.repository_path).split('/')

        response = @api_interface.send_graphql_request(query, variables: {owner:, name:})
        repo_data = response['repository'].transform_keys(&:to_sym)

        case repo_data
        in { mergeCommitAllowed: true }
          'MERGE'
        in { squashMergeAllowed: true }
          'SQUASH'
        in { rebaseMergeAllowed: true }
          'REBASE'
        else
          raise 'No merge methods are allowed on this repository'
        end
      end

      class << self
        extend T::Sig

        private

        sig {
          params(
            milestone: T.nilable(Geet::Github::Milestone),
            assignee: T.nilable(Geet::Github::User),
            head: T.nilable(String)
          ).void
        }
        def check_list_params!(milestone, assignee, head)
          if (milestone || assignee) && head
            raise "Head can't be specified with milestone or assignee!"
          end
        end
      end
    end
  end
end
