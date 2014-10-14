require_dependency 'user'

module CsvImportIssues
  module UserPatch

    def self.included(base)
       base.send(:include, InstanceMethods)
       base.class_eval do
         unloadable
       end
    end

    module InstanceMethods

      def has_import_issues_permission?(project)
        user_permissions = self.roles_for_project(project)
        return false if user_permissions.blank?
        user_permissions.each{ |user_permission| return true if user_permission.permissions.include?(:create_issues_via_csv_import) }
        false
      end

    end
  end
end