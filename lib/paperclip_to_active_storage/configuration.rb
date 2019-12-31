module PaperclipToActivestorage
  class Configuration
    attr_accessor :models, :database_name, :database_user,
                  :database_password, :storage, :exceptional_columns
    def initialize
      @models = []
      @exceptional_columns = {}
      @database_name = nil
      @database_user = nil
      @database_password = nil
      @storage = :s3
    end
  end
end
