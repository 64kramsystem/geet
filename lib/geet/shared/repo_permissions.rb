# frozen_string_literal: true

module Geet
  module Shared
    module RepoPermissions
      PERMISSION_ADMIN = 'admin'
      PERMISSION_WRITE = 'write'
      PERMISSION_READ = 'read'
      PERMISSION_NONE = 'none'

      ALL_PERMISSIONS = [
        PERMISSION_ADMIN,
        PERMISSION_WRITE,
        PERMISSION_READ,
        PERMISSION_NONE,
      ].freeze

      # Not worth creating a Permission class at this stage.
      #
      def permission_greater_or_equal_to?(subject_permission, object_permission)
        ALL_PERMISSIONS.index(subject_permission) <= ALL_PERMISSIONS.index(object_permission)
      end
    end
  end
end
