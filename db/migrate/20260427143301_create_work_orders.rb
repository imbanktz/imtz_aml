class CreateWorkOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :work_orders do |t|
      t.string :wo_number, null: false
      t.references :asset, foreign_key: true
      t.string :wo_type
      t.string :priority
      t.references :breakdown_reason, foreign_key: true
      t.text :defect_description
      t.decimal :meter_at_report, precision: 10, scale: 1
      t.decimal :meter_at_start, precision: 10, scale: 1
      t.decimal :meter_at_completion, precision: 10, scale: 1
      t.string :status, default: 'reported'
      t.references :reported_by, foreign_key: { to_table: :users }
      t.datetime :reported_at
      t.integer :assigned_mechanic_id
      t.datetime :started_at
      t.datetime :completed_at
      t.decimal :total_cost, precision: 15, scale: 2

      t.timestamps
    end
    add_index :work_orders, :wo_number, unique: true
    add_index :work_orders, :assigned_mechanic_id
    add_index :work_orders, :status
  end
end
