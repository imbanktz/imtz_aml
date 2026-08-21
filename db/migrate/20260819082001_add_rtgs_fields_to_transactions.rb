class AddRtgsFieldsToTransactions < ActiveRecord::Migration[6.1]
  def change
    # Add RTGS specific fields
    add_column :transactions, :rtgs_reference, :string
    add_column :transactions, :raw_rtgs_message, :text
    
    # Add screening fields if they don't exist
    #add_column :transactions, :screening_status, :string, default: 'pending'
    #add_column :transactions, :screening_result, :jsonb, default: {}
    add_column :transactions, :screening_attempts, :jsonb, default: []
    
    # Add indexes
    add_index :transactions, :rtgs_reference, unique: true, where: "rtgs_reference IS NOT NULL"
    #add_index :transactions, :screening_status
  end
end
