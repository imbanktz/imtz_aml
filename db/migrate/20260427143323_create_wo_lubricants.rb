class CreateWoLubricants < ActiveRecord::Migration[6.1]
  def change
    create_table :wo_lubricants do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :lubricant, null: false, foreign_key: true
      t.decimal :quantity_used
      t.decimal :unit_cost
      t.decimal :total_cost

      t.timestamps
    end
  end
end
