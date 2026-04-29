class AddTypicalLifespanHoursToAssetType < ActiveRecord::Migration[6.1]
  def change
    add_column :asset_types, :typical_lifespan_hours, :integer
  end
end
