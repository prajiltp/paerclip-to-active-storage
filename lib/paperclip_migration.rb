require 'open-uri'
require 'aws-sdk-s3'

class PaperclipMigration
  class << self
    def migrate(model, attachment, instance_ids)
      connect_s3
      instances = model.where('id In (?)', instance_ids)
      instances.each do |instance|
        next if instance.send(attachment).path.blank?
        connection = ActiveRecord::Base.connection_pool.connection
        updated_at = instance.try(:updated_at)
        updated_at = instance.try("#{attachment}_updated_at".to_sym) unless updated_at

        begin
          updated_at = updated_at.iso8601
        rescue
          updated_at = Time.now.iso8601
        end

        key = key(instance, attachment)
        checksum = checksum(instance.send(attachment))
        begin
          insert_query(connection, instance, attachment, key, checksum, updated_at, model.name)
        rescue ActiveRecord::RecordNotUnique
          key = duplicate_file_and_handle(instance, attachment, key)
          begin
            insert_query(connection, instance, attachment, key, checksum, updated_at, model.name)
          rescue
            next
          end
        end
      end
    end

    def key(instance, attachment)
      instance.send(attachment).path
    end

    def checksum(attachment)
      url = attachment.expiring_url(30.minutes)
      begin
        Digest::MD5.base64digest(Net::HTTP.get(URI(url)))
      rescue StandardError
        "fakechecksum"
      end
    end

    def defult_paperclip_path(instance, attachment)
      file_name = instance.send("#{attachment}_file_name")
      "#{instance.class.table_name}/#{attachment.pluralize}/#{instance.id}/#{file_name}"
    end

    def duplicate_file_and_handle(instance, attachment, key)
      new_path = defult_paperclip_path(instance, attachment)
      begin
        @s3.copy_object(bucket: @bucket_name,
          copy_source: @bucket_name + '/' + key,
          key: new_path)
      rescue StandardError => ex
        puts("Exception for #{new_path} ====> #{ex}")
      end
      new_path
    end

    def insert_query(connection, instance, attachment, key, checksum, updated_at, model_name)
      file_name = instance.send("#{attachment}_file_name")
      content_type = instance.send("#{attachment}_content_type")
      size = instance.send("#{attachment}_file_size")
      key = connection.quote(key)
      file_name = connection.quote(file_name)
      checksum = connection.quote(checksum)
      storage_insert_query = "INSERT INTO active_storage_blobs (
        key, filename, content_type, metadata, byte_size, checksum, created_at
      ) VALUES (#{key}, #{file_name}, '#{content_type}', '{}', #{size}, #{checksum}, '#{updated_at}') returning *"
      response = connection.execute(storage_insert_query)
      blob_id = response[0]['id'].to_i
      attachment_query = "INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ('#{attachment}', '#{model_name}', #{instance.id}, #{blob_id}, '#{updated_at}')"
      connection.execute(attachment_query)
    end

    def connect_s3
      aws_content = YAML.load_file("#{Rails.root.join('config/aws.yml') }")[Rails.env]
      @bucket_name = aws_content["bucket"]
      access_key = aws_content["access_key_id"]
      secret = aws_content["secret_access_key"]
      region = aws_content["region"] || 'ap-south-1'
      Aws.config.update({region: region, credentials: Aws::Credentials.new(access_key, secret)})
      @s3 = Aws::S3::Client.new(region: region)
    end
  end
end
