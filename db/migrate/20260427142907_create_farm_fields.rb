class CreateFarmFields < ActiveRecord::Migration[6.1]
  def change
    create_table :farm_fields do |t|
      t.references :farm, null: false, foreign_key: true
      t.string :field_name
      t.string :field_code
      t.decimal :area_hectares

      t.timestamps
    end
  end
end
