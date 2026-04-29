class Workshop < ApplicationRecord

  
  # Add this scope
  scope :active, -> { where(active: true) }
  
  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  
  # You can also add a class method as fallback
  def self.active_workshops
    where(active: true)
  end
  
end
