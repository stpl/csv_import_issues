require 'csv_import_issues/user_patch'

module CsvImportIssues
	
  def self.apply_patch
    User.send(:include, UserPatch)
  end
end
