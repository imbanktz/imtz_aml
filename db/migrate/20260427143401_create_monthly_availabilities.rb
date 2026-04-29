class CreateMonthlyAvailabilities < ActiveRecord::Migration[6.1]
  def change
    create_table :monthly_availabilities do |t|
      t.references :asset, null: false, foreign_key: true
      t.date :month
      t.decimal :downtime_hours
      t.decimal :breakdown_hours
      t.decimal :pm_hours
      t.decimal :waiting_parts_hours
      t.text :notes

      t.timestamps
    end
  end
end
