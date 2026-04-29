class CreateAssetModels < ActiveRecord::Migration[6.1]
  def change
    create_table :asset_models do |t|
      t.references :asset_make, foreign_key: { to_table: :asset_makes }
      t.references :asset_type, foreign_key: { to_table: :asset_types }
      t.string :model_code, null: false
      t.string :model_name
      t.integer :engine_power_hp
      t.integer :operating_weight_kg
      t.integer :fuel_tank_capacity_liters
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :asset_models, :model_code
  end
end
