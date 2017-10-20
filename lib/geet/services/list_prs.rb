# frozen_string_literal: true

module Geet
  module Services
    class ListPrs
      def execute(repository)
        prs = repository.list_prs

        prs.each do |pr|
          puts "#{pr.number}. #{pr.title} (#{pr.link})"
        end
      end
    end
  end
end
