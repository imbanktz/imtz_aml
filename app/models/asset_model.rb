class AssetModel < ApplicationRecord
  belongs_to :make
  belongs_to :type

  scope :active, -> { where(active: true) }
end
