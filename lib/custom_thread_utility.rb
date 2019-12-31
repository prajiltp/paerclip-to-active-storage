module CustomThreadUtility
  class << self
    def thread(&block)
      Thread.new { db(&block) }
    end

    def db(&block)
      begin
        yield block
      ensure
        # Check the connection back in to the connection pool
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      end
    end
  end
end
