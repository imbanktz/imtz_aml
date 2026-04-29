class AddMissingFieldsToHourMeter < ActiveRecord::Migration[6.1]
  def change
    #add_column :hour_meter_readings, :verified, :boolean, default: false
    add_column :hour_meter_readings, :verified_by_id, :integer
    add_column :hour_meter_readings, :verified_at, :datetime
    add_column :hour_meter_readings, :notes, :text
    add_column :hour_meter_readings, :reading_type, :string, default: 'regular'
    
    add_index :hour_meter_readings, :reading_date
  end
end
