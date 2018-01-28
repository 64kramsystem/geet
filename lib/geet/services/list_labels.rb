# frozen_string_literal: true

module Geet
  module Services
    class ListLabels
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute
        labels = @repository.labels

        labels.each do |label|
          @out.puts "- #{label.name} (##{label.color})"
        end
      end
    end
  end
end
