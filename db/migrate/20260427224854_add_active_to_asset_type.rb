class AddActiveToAssetType < ActiveRecord::Migration[6.1]
  def change
    add_column :asset_types, :active, :boolean, default: true
  end
end
