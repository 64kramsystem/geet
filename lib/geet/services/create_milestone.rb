# frozen_string_literal: true
# typed: strict

require "stringio"

module Geet
  module Services
    class CreateMilestone
      extend T::Sig

      sig { params(repository: Git::Repository, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig { params(title: String).returns(Github::Milestone) }
      def execute(title)
        create_milestone(title)
      end

      private

      sig { params(title: String).returns(Github::Milestone) }
      def create_milestone(title)
        @out.puts "Creating milestone..."

        @repository.create_milestone(title)
      end
    end # class CreateMilestone
  end # module Services
end # module Geet
