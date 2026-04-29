class CreateWorkshops < ActiveRecord::Migration[6.1]
  def change
    create_table :workshops do |t|
      t.string :code
      t.string :name
      t.text :address
      t.integer :manager_id
      t.boolean :active

      t.timestamps
    end
  end
end
