# db/migrate/20260703000001_create_roles.rb
class CreateRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :roles do |t|
      t.string :name
      t.string :code
      t.text :description
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    add_index :roles, :code, unique: true
    add_index :roles, :name, unique: true
  end
end
