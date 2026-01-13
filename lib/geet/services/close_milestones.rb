# frozen_string_literal: true

module Geet
  module Services
    class CloseMilestones
      include Geet::Shared::Selection

      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute(numbers: nil)
        numbers = find_and_select_milestone_numbers(numbers)

        close_milestone_threads = close_milestones(numbers)

        close_milestone_threads.each(&:join)
      end

      private

      def find_and_select_milestone_numbers(numbers)
        selection_manager = Geet::Utils::AttributesSelectionManager.new(@repository, out: @out)

        selection_manager.add_attribute(:milestones, 'milestone', numbers, SELECTION_MULTIPLE, name_method: :title)

        milestones = selection_manager.select_attributes[0]

        milestones.map(&:number)
      end

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
