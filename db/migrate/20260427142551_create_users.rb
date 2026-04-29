class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :employee_id
      t.string :name
      t.string :email
      t.string :user_type
      t.boolean :is_creator
      t.boolean :is_approver
      t.decimal :approval_limit
      t.integer :primary_workshop_id
      t.string :pin_code
      t.boolean :active

      t.timestamps
    end
  end
end
