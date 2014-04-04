class LeavesHookListener < Redmine::Hook::ViewListener
		render_on :view_issues_sidebar_planning_bottom, :partial => "csv_imports/link_to_import_csv" 
end
