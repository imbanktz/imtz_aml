class AddReferenceToTransaction < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :reference, :string
  end
end
