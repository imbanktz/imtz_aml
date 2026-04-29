class CreateParts < ActiveRecord::Migration[6.1]
  def change
    create_table :parts do |t|
      t.string :part_number
      t.string :part_name
      t.string :applicable_make
      t.string :applicable_model
      t.integer :minimum_stock
      t.integer :current_stock
      t.integer :reorder_level
      t.decimal :unit_cost

      t.timestamps
    end
  end
end
