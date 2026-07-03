class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      # Basic info
      t.string :employee_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :user_type, default: 'viewer'
      
      # Permissions flags (legacy, kept for compatibility)
      t.boolean :is_creator, default: false
      t.boolean :is_approver, default: false
      t.decimal :approval_limit, precision: 15, scale: 2
      
      # Workshop (optional - kept for compatibility)
      t.integer :primary_workshop_id
      
      # Security
      t.string :pin_code
      t.boolean :active, default: true
      
      # Devise fields
      t.string :encrypted_password, default: "", null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      
      # Trackable fields
      t.integer :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      
      # Lockable fields
      t.integer :failed_attempts, default: 0, null: false
      t.string :unlock_token
      t.datetime :locked_at
      
      t.timestamps
    end
    
    # Indexes
    add_index :users, :email, unique: true
    add_index :users, :employee_id, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
    add_index :users, :user_type
    add_index :users, :active
  end
end
