class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.datetime :date
      t.string :request_id, index: true
      t.string :transaction_direction
      t.decimal :transaction_amount, precision: 18, scale: 2
      t.string :transaction_currency
      t.date :transaction_date
      t.string :clearing_system_ref
      
      # JSON fields for complex data structures
      t.jsonb :parties, default: []
      t.jsonb :agents, default: []
      t.jsonb :narratives, default: {}
      t.jsonb :forensic_data, default: {}
      
      t.string :processing_type
      t.string :profile
      t.string :profile_name

      t.timestamps
    end

    # Add indexes for JSONB fields for better query performance
    add_index :transactions, :parties, using: :gin
    add_index :transactions, :agents, using: :gin
    add_index :transactions, :narratives, using: :gin
    add_index :transactions, :transaction_direction
    add_index :transactions, [:transaction_date, :transaction_currency]
    add_index :transactions, :processing_type
  end
end
