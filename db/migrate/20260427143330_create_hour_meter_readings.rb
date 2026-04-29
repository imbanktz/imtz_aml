class CreateHourMeterReadings < ActiveRecord::Migration[6.1]
  def change
    create_table :hour_meter_readings do |t|
      t.references :asset, foreign_key: true
      t.date :reading_date
      t.decimal :hour_meter, precision: 10, scale: 1
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.boolean :verified, default: false

      t.timestamps
    end
    add_index :hour_meter_readings, [:asset_id, :reading_date], unique: true
  end
end
