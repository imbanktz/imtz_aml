class CreateAssetTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :asset_types do |t|
      t.references :asset_category, foreign_key: { to_table: :asset_categories }
      t.string :type_code, null: false
      t.string :type_name, null: false

      t.timestamps
    end
    add_index :asset_types, :type_code, unique: true
  end
end
