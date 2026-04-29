
class AddDeviseToUsers < ActiveRecord::Migration[6.1]
  def up
    change_table :users do |t|
      # Only add columns that don't already exist
      unless column_exists?(:users, :encrypted_password)
        t.string :encrypted_password, null: false, default: ""
      end
      
      unless column_exists?(:users, :reset_password_token)
        t.string :reset_password_token
      end
      
      unless column_exists?(:users, :reset_password_sent_at)
        t.datetime :reset_password_sent_at
      end
      
      unless column_exists?(:users, :remember_created_at)
        t.datetime :remember_created_at
      end
      
      # Add other Devise columns if needed
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip
      
      # Add indexes if they don't exist
      unless index_exists?(:users, :reset_password_token, unique: true)
        t.index :reset_password_token, unique: true
      end
    end
  end

  def down
    # Remove only the columns we added
    remove_column :users, :encrypted_password if column_exists?(:users, :encrypted_password)
    remove_column :users, :reset_password_token if column_exists?(:users, :reset_password_token)
    remove_column :users, :reset_password_sent_at if column_exists?(:users, :reset_password_sent_at)
    remove_column :users, :remember_created_at if column_exists?(:users, :remember_created_at)
  end
end
