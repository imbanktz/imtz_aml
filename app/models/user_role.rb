class UserRole < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :role
  
  # Validations
  validates :user_id, uniqueness: { scope: :role_id, message: "already has this role" }
  validates :user, presence: true
  validates :role, presence: true
  
  # Scopes
  scope :active, -> { joins(:role).where(roles: { active: true }) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_role, ->(role) { where(role: role) }
  
  # Instance methods
  def active?
    role.active? && user.active?
  end
end
