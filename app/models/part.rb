class Part < ApplicationRecord

  # Scope for low stock parts
  scope :low_stock, -> { where("current_stock <= reorder_level") }
  
  # Scope for out of stock parts
  scope :out_of_stock, -> { where(current_stock: 0) }
  
end
