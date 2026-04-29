class CreateLubricants < ActiveRecord::Migration[6.1]
  def change
    create_table :lubricants do |t|
      t.string :code
      t.string :name
      t.string :unit
      t.decimal :current_stock
      t.decimal :min_stock_level
      t.decimal :unit_cost

      t.timestamps
    end
  end
end
