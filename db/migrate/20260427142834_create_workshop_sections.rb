class CreateWorkshopSections < ActiveRecord::Migration[6.1]
  def change
    create_table :workshop_sections do |t|
      t.references :workshop, null: false, foreign_key: true
      t.string :section_code
      t.string :section_name
      t.string :section_type
      t.integer :capacity
      t.boolean :active

      t.timestamps
    end
  end
end
