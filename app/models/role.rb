class Role < ApplicationRecord
  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  
  # Constants for role codes
  ROLES = {
    super_admin: 'SUPER_ADMIN',
    admin: 'ADMIN',
    screener: 'SCREENER',
    approver: 'APPROVER',
    viewer: 'VIEWER'
  }.freeze
  
  # Instance methods
  def display_name
    "#{name} (#{code})"
  end
  
  def active?
    active == true
  end
end
