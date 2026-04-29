class CreateFarms < ActiveRecord::Migration[6.1]
  def change
    create_table :farms do |t|
      t.string :farm_code
      t.string :farm_name
      t.string :farm_category
      t.string :region
      t.decimal :area_hectares
      t.integer :manager_id

      t.timestamps
    end
  end
end
