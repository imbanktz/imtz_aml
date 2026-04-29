class CreateWoParts < ActiveRecord::Migration[6.1]
  def change
    create_table :wo_parts do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :part, null: false, foreign_key: true
      t.integer :quantity_used
      t.decimal :unit_cost
      t.decimal :total_cost

      t.timestamps
    end
  end
end
