class CsvImportsController < ApplicationController
  unloadable
  menu_item :issues
  OPTION_TO_REMOVE = [["Project", :project], ["Related issues", :relations], ["Spent time", :spent_hours], ["#", :id]]

  before_filter :find_project, :validate_permission_for_issue_import
  before_filter :validate_file_extension, :validate_csv,:validate_file_data, only:[:create]
  before_filter :validate_mutiple_values, :initialize_valid_params, only: [:create_issue]

  def new
    @import = CsvImport.new
  end

  def create
    @issue = Issue.new
    render :finalize
  end

  def create_issue
    @issues_ready_to_save.each_with_index{|issue, index| call_hook(:controller_issues_new_after_save, { :params => @issue_param_hash[index], :issue => issue}) if issue.save }
    flash[:notice] = l(:import_successful_notice, :no_of_issues_created => @issues_ready_to_save.length) 
    redirect_to new_project_csv_import_path
  end

  def download
    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = 'attachment; filename=sample.csv'
        render :template => "csv_imports/download.csv.erb", :type => 'text/csv; header=present'
      end
    end
  end

private
  
  def validate_csv
    @import = CsvImport.new(params[:csv_import]) #TODO:: What if this crashes ?
    render :new unless @import.valid?
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def validate_permission_for_issue_import
    render_back = true
    User.current.roles_for_project(@project).collect { |role|  break render_back = false if role.has_permission?("create_issues_via_csv_import") }
    render_403 if render_back
  end
  
  def validate_file_extension
    @query =  fetch_options_to_map
    return if params[:csv_import].blank?
    file_name = params[:csv_import][:csv].original_filename
    render_on_error(l(:error_file_not_of_csv_extension)) if file_name.count('.') > 1 or File.extname(file_name) != (".csv")
  end

  def validate_file_data
    return if  params[:csv_import].blank?
    begin
      @csv_rows = CSV.parse(params[:csv_import][:csv].read)
      # 2 Stand for number for rows in CSV.
      render_back = nil
      if @csv_rows.blank? or @csv_rows.size < 2
        render_back = true
      else
        # validate number of columns(comma saperated values) in csv with @columns.size < 2
        # where 2 stands for default number of mandatory fields for Issues
        @csv_rows.each{|column| break render_back = true if column.size < 2 }
      end
      render_on_error(l(:error_invalid_csv_data)) if render_back
    rescue Exception => e
      render_on_error(e.message)
    end
  end

  def render_on_error(message, render_view = 'new')
    @import = CsvImport.new if render_view == 'new' 
    @issue = Issue.new if render_view == 'finalize'
    flash.now[:error] = message
    render :"#{render_view}"
  end
  
  def validate_mutiple_values
    @query = fetch_options_to_map
    @csv_rows = eval(params[:import][:csv])
    options = params[:options].reject(&:empty?)
    render_on_error(l(:error_to_try_map_same_field_twice), 'finalize') unless (options.uniq.length == options.length)
  end

  def fetch_options_to_map
    total_options = IssueQuery.new(:column_names => Setting.issue_list_default_columns).available_columns.collect{|column| [column.caption,column.name]}
    (total_options - OPTION_TO_REMOVE).sort
  end

  def initialize_valid_params
    @issue_param_hash, @issues_ready_to_save, validation_failed = [], [], false
    @csv_rows[1...@csv_rows.length].each do |issue|
      issue_validator = IssueValidator.new(issue, @project, params[:options])
      issue_param_hash = issue_validator.issue_param_hash

      @issue=Issue.new(project: @project, created_on: issue_param_hash['created_on'], updated_on: issue_param_hash['updated_on'])
      call_hook(:controller_issues_new_before_save, { :params => issue_param_hash, :issue => @issue })
      @issue.safe_attributes = issue_param_hash
      ['tracker', 'author'].each{|mapping| @issue.send("#{mapping}=", issue_param_hash["#{mapping}"])}
      unless issue_validator.errors.blank? and @issue.valid?
        @issue.errors.messages.merge!(issue_validator.errors.messages)
        validation_failed = true
        break
      else
        @issue_param_hash << issue_param_hash
        @issues_ready_to_save << @issue
      end
    end
    if validation_failed
      @import = CsvImport.new
      render :finalize
    end
  end
end
