class CreatePmSchedules < ActiveRecord::Migration[6.1]
  def change
    create_table :pm_schedules do |t|
      t.string :name
      t.string :equipment_category
      t.integer :trigger_hours
      t.jsonb :checklist_template
      t.decimal :estimated_hours
      t.boolean :active

      t.timestamps
    end
  end
end
