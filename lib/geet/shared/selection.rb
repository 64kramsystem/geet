# frozen_string_literal: true

module Geet
  module Shared
    module Selection
      MANUAL_LIST_SELECTION_FLAG = '-'.freeze
      # Don't select anything; return the null value.
      SKIP_LIST_SELECTION_FLAG = ''.freeze

      SELECTION_SINGLE = :single
      SELECTION_MULTIPLE = :multiple
    end
  end
end
