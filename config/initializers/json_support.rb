require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      NATIVE_DATABASE_TYPES[:jsonb] = { name: "jsonb" }
    end
  end
end
