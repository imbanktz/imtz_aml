class CreateBreakdownReasons < ActiveRecord::Migration[6.1]
  def change
    create_table :breakdown_reasons do |t|
      t.string :reason_code
      t.string :reason_name
      t.string :category
      t.text :typical_parts
      t.decimal :average_repair_hours

      t.timestamps
    end
  end
end
