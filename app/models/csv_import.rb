class CsvImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include Paperclip::Glue
  extend ActiveModel::Callbacks

  attr_accessor :csv_file_name, :csv_file_size, :csv_content_type
  define_model_callbacks :save, only: [:after]
  define_model_callbacks :destroy, only: [:before, :after]

  has_attached_file :csv
  validates_attachment :csv, :presence => {:message => "Oops! Please select a CSV file to import."},
  :content_type => { :content_type => ['text/csv','text/comma-separated-values','application/csv','application/octet-stream','application/excel','application/vnd.ms-excel', 'application/vnd.msexcel', 'text/anytext'], :message => "Oops! Please upload a file with the extension of csv." },
  :size => { :greater_than => 0.kilobytes, :message => 'Oops! This file has no data. Please upload a file with some data.' }

  def initialize(attributes={})
     attributes.each{|name, value| send("#{name}=", value) } unless attributes.blank?
   end

   def persisted?
   	false
   end
end
