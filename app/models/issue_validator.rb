class IssueValidator
  include ActiveModel::Validations
  include IssueMapper
  validate :validate_and_assign_tracker, :validate_and_assign_status,
  				 :validate_and_assign_priority, :validate_and_assign_parent_issue,
  				 :validate_and_assign_category, :validate_and_assign_fixed_version,
           :validate_and_assign_assigned_to_id, :validate_and_assign_author

  def initialize(row, project, params)
    IssueMapper.set_foreign_key_field_index(params)
    @mapping_order = params
    @project = project
    @issue_row = row
    @issue_param_hash = attribute_map
    self.valid?
  end

  def validate_and_assign_tracker
    return if parameter_exist?("tracker")
    assign_or_add_error(@project.trackers.where("trackers.name = ? ", @issue_row[IssueMapper.get_value("tracker")]).first, "tracker", :tracker)
  end

  ['status', 'priority', 'category'].each do |field|
    define_method "validate_and_assign_#{field}" do
      return if parameter_exist?(field)
      assign_or_add_error(("Issue#{field.camelize}".constantize.where("name = ? ", @issue_row[IssueMapper.get_value(field)]).first.id rescue false), "#{field}_id", field.to_sym)
    end
  end

  def validate_and_assign_parent_issue
    return if parameter_exist?('parent')
    assign_or_add_error((Issue.find(@issue_row[IssueMapper.get_value("parent")]).id rescue false), "parent_issue_id", :parent)
  end

  def validate_and_assign_fixed_version
    return if parameter_exist?('fixed_version')
    assign_or_add_error((Version.where("name = ? ", @issue_row[IssueMapper.get_value("fixed_version")]).first.id rescue false), "fixed_version_id", :version)
  end

  def validate_and_assign_author
    if parameter_exist?('author')
      @issue_param_hash['author'] = User.current
      return
    end
    assign_or_add_error(get_user('author'), 'author', :author)
  end

  def validate_and_assign_assigned_to_id
    return if parameter_exist?('assigned_to')
    assign_or_add_error((get_user('assigned_to').id rescue false), 'assigned_to_id', :assignee)
  end

  def get_user(field)
    name = @issue_row[IssueMapper.get_value(field)].split(' ') rescue nil
    User.where("firstname = ? AND lastname = ? ",name.first,name.last).first if name
  end

  def issue_param_hash
    @issue_param_hash
  end

private
  def parameter_exist?(key)
    IssueMapper.get_value(key).blank? or @issue_row[IssueMapper.get_value(key)].blank?
  end

  def assign_or_add_error(record, hash_key, error_key)
    if record
      @issue_param_hash[hash_key] = record
    else
      self.errors.add(error_key, "is invalid")
    end
  end

  def attribute_map
    mapping_hash = {}
    @mapping_order.each_with_index do |field, index|
      next if field.blank? or IssueMapper.get_foreign_key_field_index.keys.include?(field)
      if field.starts_with?("cf_")
        mapping_hash["custom_field_values"] = (mapping_hash["custom_field_values"] || {}).merge(field[3..-1]=>@issue_row[index])
      else
        mapping_hash[field]= (@issue_row[index].encode("UTF-8", "ISO-8859-15") rescue @issue_row[index])
      end
    end
    mapping_hash
  end
end