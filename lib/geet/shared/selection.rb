# frozen_string_literal: true
# typed: strict

module Geet
  module Shared
    module Selection
      MANUAL_LIST_SELECTION_FLAG = "-"
      # Don't select anything; return the null value.
      SKIP_LIST_SELECTION_FLAG = ""

      SELECTION_SINGLE = :single
      SELECTION_MULTIPLE = :multiple
    end
  end
end
