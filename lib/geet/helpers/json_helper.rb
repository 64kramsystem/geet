# frozen_string_literal: true

require 'time'

module Geet
  module Helpers
    module JsonHelper
      # Most common Json time format.
      #
      # Returns nil if nil is passed.
      #
      def parse_iso_8601_timestamp(timestamp)
        Time.iso8601(timestamp).to_date if timestamp
      end
    end # JsonHelper
  end # Helpers
end # Geet
