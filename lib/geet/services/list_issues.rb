# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class ListIssues
      extend T::Sig

      include Geet::Shared::Selection

      sig {
        params(
          repository: Git::Repository,
          out: StringIO
        ).void
      }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig {
        params(
          assignee: T.nilable(String)
        )
        .returns(T.any(T::Array[Github::AbstractIssue], T::Array[Gitlab::Issue]))
      }
      def execute(assignee: nil)
        selected_assignee = find_and_select_attributes(assignee) if assignee

        issues = @repository.issues(assignee: selected_assignee)

        issues.each do |issue|
          @out.puts "#{issue.number}. #{issue.title} (#{issue.link})"
        end
      end

      private

      sig {
        params(
          assignee: String
        ).returns(T.any(Github::User, Gitlab::User))
      }
      def find_and_select_attributes(assignee)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:collaborators, "assignee", assignee, SELECTION_SINGLE, name_method: :username)

        T.cast(selection_manager.select_attributes[0], T.any(Github::User, Gitlab::User))
      end
    end
  end
end
