# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class CreateMilestone
      extend T::Sig

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig { params(title: String).returns(T.any(Github::Milestone, Gitlab::Milestone)) }
      def execute(title)
        create_milestone(title)
      end

      private

      sig { params(title: String).returns(T.any(Github::Milestone, Gitlab::Milestone)) }
      def create_milestone(title)
        @out.puts "Creating milestone..."

        @repository.create_milestone(title)
      end
    end # class CreateMilestone
  end # module Services
end # module Geet
