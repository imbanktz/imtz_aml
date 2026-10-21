class AddNarrativeToTransactions < ActiveRecord::Migration[6.1]
  def change
   add_column :transactions, :narrative, :text
   add_index  :transactions, :narrative
  end
end
