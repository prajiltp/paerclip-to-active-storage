=== Paerclip to active storage migration ===

Prerequisite - You should have the tables for active storage in your database

You should execute it form the app where the paperclip is configured.

Configure the s3 details in file conig/aws.yml with sample format
  development:
    access_key_id: "key"
    secret_access_key: "secret"
    bucket: "vbucket name"
    paperclip_secret: 'paperclip secret'


Configuring models and execption create an initilizer file for paperclip_migrate_init.rb with Sample content

PaperclipToActivestorage.configure do |conf|
  # model name
  conf.models = [Profile, Attachment]

  # if some exceptional columns are there you can specify as
  conf.exceptional_columns = {
    Profile: ['secondar_image']
  }
end

Limitation

Only s3 is configured
Handled with threads may be we can use multiple worker to execute the job which will make it fast
Single DB is allowded - Default one configured with the app.

