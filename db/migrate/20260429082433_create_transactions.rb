class CreateTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      # Core identification fields
      t.string :request_id, null: false
      t.string :transaction_direction, null: false, default: 'IN'
      t.string :transaction_type, default: 'UNKNOWN'
      
      # Financial fields
      t.decimal :transaction_amount, precision: 18, scale: 2, null: false, default: 0
      t.string :transaction_currency, null: false, default: 'TZS'
      t.date :transaction_date, null: false
      
      # Transaction metadata
      t.string :reference
      t.text :narrative
      t.string :bank_code
      
      # Party information (Debtor and Creditor)
      t.json :parties
      
      # Raw data storage
      t.json :raw_data
      t.json :raw_fields
      t.text :raw_message
      
      # Status tracking - Updated default values
      t.string :status, default: 'PENDING'
      t.string :screening_status, default: 'NOT_SCREENED'
      t.json :screening_result
      t.text :screening_error
      t.datetime :screened_at
      
      # Error handling
      t.text :error_message
      
      # Processing metadata
      t.datetime :processed_at
      
      t.timestamps
    end
    
    # Indexes
    add_index :transactions, :request_id, unique: true
    add_index :transactions, :transaction_direction
    add_index :transactions, :transaction_type
    add_index :transactions, :transaction_date
    add_index :transactions, :transaction_currency
    add_index :transactions, :reference
    add_index :transactions, :status
    add_index :transactions, :screening_status
    add_index :transactions, [:transaction_date, :transaction_direction], name: 'index_transactions_on_date_and_direction'
    add_index :transactions, [:status, :screening_status], name: 'index_transactions_on_status_and_screening'
  end
end
