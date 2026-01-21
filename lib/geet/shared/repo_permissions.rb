# frozen_string_literal: true
# typed: strict

module Geet
  module Shared
    module RepoPermissions
      extend T::Sig

      PERMISSION_ADMIN = "admin"
      PERMISSION_WRITE = "write"
      PERMISSION_READ = "read"
      PERMISSION_NONE = "none"

      ALL_PERMISSIONS = T.let(T.unsafe(nil), T::Array[String]) if defined?(T::sig)
      ALL_PERMISSIONS = [
        PERMISSION_ADMIN,
        PERMISSION_WRITE,
        PERMISSION_READ,
        PERMISSION_NONE,
      ].freeze

      # Not worth creating a Permission class at this stage.
      #
      sig { params(subject_permission: String, object_permission: String).returns(T::Boolean) }
      def permission_greater_or_equal_to?(subject_permission, object_permission)
        T.must(ALL_PERMISSIONS.index(subject_permission)) <= T.must(ALL_PERMISSIONS.index(object_permission))
      end
    end
  end
end
