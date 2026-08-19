class AddJobIdToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :job_id, :string
    add_index :transactions, :job_id
  end
end
