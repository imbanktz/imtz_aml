class CreateAssets < ActiveRecord::Migration[6.1]
  def change
    create_table :assets do |t|
      t.string :fleet_number, null: false
      t.string :serial_number
      t.references :asset_model, foreign_key: { to_table: :asset_models }
      t.string :current_status
      t.string :current_location_type
      t.integer :current_location_id
      t.decimal :current_hour_meter, precision: 10, scale: 1, default: 0
      t.date :last_meter_update
      t.date :acquisition_date
      t.decimal :acquisition_cost, precision: 15, scale: 2
      t.integer :primary_operator_id
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :assets, :fleet_number, unique: true
    add_index :assets, :serial_number, unique: true
    add_index :assets, :primary_operator_id
  end
end
