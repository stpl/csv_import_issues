Redmine::Plugin.register :csv_import_issues do
  name 'csv_import_issues'
  author 'Systango'
  description 'This is a plugin for adding multiple issues using CSV'
  version '0.0.2'
  requires_redmine :version_or_higher => '2.3.0'


	project_module :issue_tracking do
		permission :create_issues_via_csv_import,	:csv_imports => [:new, :create, :download, :create_issue]
	end

	require 'csv_import_hook_listener.rb'
end
