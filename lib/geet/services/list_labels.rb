# frozen_string_literal: true

module Geet
  module Services
    class ListLabels
      def execute(repository, output: $stdout)
        labels = repository.labels

        labels.each do |label|
          output.puts "- #{label}"
        end
      end
    end
  end
end
