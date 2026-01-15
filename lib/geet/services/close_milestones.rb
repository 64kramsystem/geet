# frozen_string_literal: true
# typed: strict

module Geet
  module Services
    class CloseMilestones
      extend T::Sig

      include Geet::Shared::Selection

      sig { params(repository: T.untyped, out: T.any(IO, StringIO)).void }
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      sig { params(numbers: T.nilable(String)).void }
      def execute(numbers: nil)
        numbers = find_and_select_milestone_numbers(numbers)

        close_milestone_threads = close_milestones(numbers)

        close_milestone_threads.each(&:join)
      end

      private

      sig { params(numbers: T.nilable(String)).returns(T::Array[T.untyped]) }
      def find_and_select_milestone_numbers(numbers)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:milestones, 'milestone', numbers, SELECTION_MULTIPLE, name_method: :title)

        milestones = selection_manager.select_attributes[0]

        milestones.map(&:number)
      end

      sig { params(numbers: T::Array[T.untyped]).returns(T::Array[Thread]) }
      def close_milestones(numbers)
        @out.puts "Closing milestones #{numbers.join(', ')}..."

        numbers.map do |number|
          Thread.new do
            @repository.close_milestone(number)
          end
        end
      end
    end # CloseMilestones
  end # Services
end # Geet
