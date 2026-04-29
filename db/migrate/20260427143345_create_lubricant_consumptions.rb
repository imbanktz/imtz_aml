class CreateLubricantConsumptions < ActiveRecord::Migration[6.1]
  def change
    create_table :lubricant_consumptions do |t|
      t.date :transaction_date
      t.references :asset, foreign_key: true
      t.references :work_order, foreign_key: true
      t.string :job_card_number
      t.string :lubricant_type
      t.decimal :quantity, precision: 10, scale: 2
      t.string :remark
      t.string :reason
      t.references :recorded_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :lubricant_consumptions, :transaction_date
    add_index :lubricant_consumptions, :lubricant_type
  end
end
