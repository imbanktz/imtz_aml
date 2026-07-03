# db/migrate/20260703000000_create_users.rb
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
      
      # Devise fields
      t.string :encrypted_password, default: "", null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :employee_id, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
