require File.expand_path('../../test_helper', __FILE__)

#TODO :: Why dont we have any tests?
class CsvImportsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', [:projects, :enabled_modules, :member_roles, :members, :projects_trackers, :roles, :users, :trackers, :custom_fields, :enumerations, :issue_statuses, :workflows, :issue_categories, :issues, :versions])
	def setup # works like before filter
    @request.session[:user_id] = 1
  end

  def test_new
    get :new, :project_id => "ecookbook"
    assert_template :new
    assert_not_nil assigns(:import)
  end

  def test_project_find_filter
    ['new', 'create', 'create_issue'].each do |action|
      get action.to_sym, :project_id => ""
      assert_response 404
    end
  end

	def test_create
    ['wrong_format.txt', 'blank_csv.csv', 'single_row_csv.csv', 'multiple_extensions.txt.csv'].each do |file|
       post :create, :project_id => "ecookbook", :csv_import => {csv: fixture_file_upload('../../plugins/csv_import_issues/test/fixtures/'+file,'text/csv')}
       assert_equal false, assigns(:import).valid?
       assert_equal true, assigns(:import).errors.has_key?(:csv)
    end

  	post :create, :project_id => "ecookbook", :csv_import => {:csv => fixture_file_upload('../../plugins/csv_import_issues/test/fixtures/export.csv','text/csv')}
    assert_not_nil assigns(:issue)
  	assert_template :finalize

    post :create, :project_id => "ecookbook", :csv_import => {:csv => fixture_file_upload('../../plugins/csv_import_issues/test/fixtures/content_type_of_not_csv.csv','text/csv')}
    assert_template :new

	end

  def test_create_issue
    #All working fine
    options = ["", "", "tracker", "parent", "status", "priority", "subject", "author", "assigned_to", "updated_on", "category", "fixed_version", 
      "start_date", "due_date", "estimated_hours", "spent_hours", "done_ratio", "created_on", "relations", "cf_1", ""]
    csv_data = "[[\"#\", \"Project\", \"Tracker\", \"Parent task\", \"Status\", \"Priority\", \"Subject\", \"Author\", \"Assignee\", \"Updated\", 
    \"Category\", \"Target version\", \"Start date\", \"Due date\", \"Estimated time\", \"Spent time\", \"% Done\", \"Created\", \"Related issues\", 
    \"Expected Estimate\", \"Build\"], [\"12780\", \"eCookbook\", \"Bug\", \"1\", \"New\", \"Normal\", \"problem in Headphone and table \", 
    \"redMine Admin\", \"redMine Admin\", \"04/02/2014 04:07 pm\", \"Printing\", \"2.0\", \"04/02/2014\", \"\", \"\", \"0.00\", \"50\", \"04/02/2014 03:29 pm\", \"1\", \"\", \"\"]]"
    post :create_issue, :project_id => "ecookbook", :options=> options , :import=>{:csv=>csv_data}
    assert_template 'mailer/issue_add'

    #Error of mapping require fields.
    options = ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]   
    csv_data = "[[\"#\", \"Project\", \"Tracker\", \"Parent task\", \"Status\", \"Priority\", \"Subject\", \"Author\", \"Assignee\", \"Updated\", 
    \"Category\", \"Target version\", \"Start date\", \"Due date\", \"Estimated time\", \"Spent time\", \"% Done\", \"Created\", \"Related issues\", 
    \"Expected Estimate\", \"Build\"], [\"12780\", \"eCookbook\", \"Support\", \"\", \"in-progress\", \"Normal\", \"problem in Headphone and table \", 
    \"redMine Admin\", \"\", \"04/02/2014 04:07 pm\", \"\", \"\", \"04/02/2014\", \"\", \"\", \"0.00\", \"\", \"04/02/2014 03:29 pm\", \"\", \"\", \"\"]]"
    post :create_issue, :project_id => "ecookbook", :options=> options , :import=>{:csv=>csv_data}
    assert_equal true,  assigns(:issue).errors.has_key?(:tracker)
    assert_equal true,  assigns(:issue).errors.has_key?(:subject)
    assert_template :finalize

    #error of mapping multiple fields.
    options = ["", "", "tracker", "parent", "status", "priority", "subject", "author", "assigned_to", "updated_on", "category", "fixed_version", 
    "start_date", "due_date", "estimated_hours", "spent_hours", "done_ratio", "created_on", "relations", "", "due_date"]
    post :create_issue, :project_id => "ecookbook", :options=> options , :import=>{:csv=>csv_data}
    assert_template :finalize

    #errors of mapping incorrect field
    options = ["", "", "tracker", "parent", "status", "priority", "subject", "author", "assigned_to", "updated_on", "category", "fixed_version", 
      "start_date", "due_date", "estimated_hours", "spent_hours", "done_ratio", "created_on", "relations", "", ""]
    csv_data = "[[\"#\", \"Project\", \"Tracker\", \"Parent task\", \"Status\", \"Priority\", \"Subject\", \"Author\", \"Assignee\", \"Updated\", 
    \"Category\", \"Target version\", \"Start date\", \"Due date\", \"Estimated time\", \"Spent time\", \"% Done\", \"Created\", \"Related issues\", 
    \"Expected Estimate\", \"Build\"], [\"12780\", \"eCookbook\", \"Bugs\", \"aaa\", \"New\", \"in-progress\", \"problem in Headphone and table \", 
    \"test test\", \"test test\", \"04/02/2014 04:07 pm\", \"abc\", \"abc\", \"04/02/2014\", \"\", \"\", \"0.00\", \"23\", \"04/02/2014 03:29 pm\", \"\", \"\", \"\"]]"
    post :create_issue, :project_id => "ecookbook", :options=> options , :import=>{:csv=>csv_data}
    ["priority", "tracker", "parent" ,"assignee","category","version","author"].each { |key| assert_equal true,  assigns(:issue).errors.has_key?(key.to_sym)}  
  end

  def test_download
   get :download, :project_id => "ecookbook", format: "csv"
   assert_template 'csv_imports/download.csv'
 end

end
