# frozen_string_literal: true

module Geet
  module Services
    class ListLabels
      def execute(repository)
        labels = repository.labels

        labels.each do |label|
          puts "- #{label}"
        end
      end
    end
  end
end
