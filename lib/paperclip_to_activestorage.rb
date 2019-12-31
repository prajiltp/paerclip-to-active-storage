require 'paperclip_to_active_storage/configuration.rb'
require 'paperclip_migration.rb'
require 'custom_thread_utility.rb'

module PaperclipToActivestorage
  class << self
    attr_accessor :configuration

    def regenerate
      configuration.models.each do |model|
        check_and_invoke_model(model)
      end
    end

    def check_and_invoke_model(model)
      attachments = model.column_names.map do |c|
        $1 if c =~ /(.+)_file_name$/
      end.compact
      except_attachments = configuration.exceptional_columns[model.to_s.to_sym]
      attachments -= except_attachments if except_attachments&.kind_of?(Array)
      return if attachments.blank?

      migrate_contentes(attachments, model)
    end

    def migrate_contentes(attachments, model)
      attachments.each do |attachment|
        records = model.where("#{attachment}_file_name is not null").order('id DESC')
        CustomThreadUtility.thread do
          records.find_in_batches do |instances|
            instance_ids = instances.collect(&:id)
            PaperclipMigration.migrate(model, attachment, instance_ids)
          end
        end
      end
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
