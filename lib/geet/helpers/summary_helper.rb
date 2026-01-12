# frozen_string_literal: true

module Geet
  module Helpers
    module SummaryHelper
      # Split the summary in title and description.
      # The description is optional, but the title mandatory.
      #
      def split_summary(summary)
        raise "Missing title in summary!" if summary.to_s.strip.empty?

        title, description = summary.split(/\r|\n/, 2)

        raise "Title missing" if title.nil?

        # The title may have a residual newline char; the description may not be present,
        # or have multiple blank lines.
        [title.strip, description.to_s.strip]
      end
    end
  end
end
