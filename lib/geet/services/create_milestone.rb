# frozen_string_literal: true

module Geet
  module Services
    class CreateMilestone
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute(title)
        create_milestone(title)
      end

      private

      def create_milestone(title)
        @out.puts 'Creating milestone...'

        @repository.create_milestone(title)
      end
    end # class CreateMilestone
  end # module Services
end # module Geet
