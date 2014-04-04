module IssueMapper
	def self.set_foreign_key_field_index(params)
		@foreign_key_field_index = {"tracker" => "", "status"=>"", "priority"=>"", "parent"=>"", "category"=>"", "assigned_to"=>"","author"=>"","fixed_version"=>""}
		@foreign_key_field_index.keys.each {|key| @foreign_key_field_index[key]=params.index(key)}
	end

	def self.get_value(key)
		@foreign_key_field_index[key]
	end

	def self.get_foreign_key_field_index
		@foreign_key_field_index
	end
end