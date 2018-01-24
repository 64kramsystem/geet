# frozen_string_literal: true

module Geet
  module Services
    class ListPrs
      def initialize(repository)
        @repository = repository
      end

      def execute(output: $stdout)
        prs = @repository.prs

        prs.each do |pr|
          output.puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
