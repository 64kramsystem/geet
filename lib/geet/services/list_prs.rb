# frozen_string_literal: true

module Geet
  module Services
    class ListPrs
      def initialize(repository, out: $stdout)
        @repository = repository
        @out = out
      end

      def execute
        prs = @repository.prs

        prs.each do |pr|
          @out.puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
