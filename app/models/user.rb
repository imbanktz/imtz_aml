class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, 
         :recoverable, 
         :rememberable, 
         :trackable, 
         :validatable,
         :timeoutable,
         :lockable

  # Associations - Make sure these exist
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  
  # Enums
  enum user_type: {
         driver: 'driver',
         operator: 'operator',
         mechanic: 'mechanic',
         engineer: 'engineer',
         maintenance_planner: 'maintenance_planner',
         storekeeper: 'storekeeper',
         supervisor: 'supervisor',
         imtz_aml: 'imtz_aml',
         viewer: 'viewer',
         screener: 'screener',
         approver: 'approver',
         admin: 'admin'
       }
  
  # Validations
  validates :employee_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :by_email, ->(email) { where("email ILIKE ?", "%#{email}%") }
  scope :by_employee_id, ->(employee_id) { where("employee_id ILIKE ?", "%#{employee_id}%") }
  scope :with_role, ->(role_code) { joins(:roles).where(roles: { code: role_code }) }
  
  # Callbacks
  before_validation :set_default_values, on: :create
  
  # Instance Methods
  def full_name
    "#{employee_id} - #{name}"
  end
  
  def display_name
    name.presence || email
  end
  
  # Role checking methods
  def has_role?(role_code)
    roles.exists?(code: role_code)
  end
  
  def has_any_role?(*role_codes)
    roles.where(code: role_codes).exists?
  end
  
  # Permission methods
  def super_admin?
    has_role?('SUPER_ADMIN')
  end
  
  def admin?
    has_role?('ADMIN') || super_admin?
  end
  
  def screener?
    has_role?('SCREENER') || admin?
  end
  
  def approver?
    has_role?('APPROVER') || admin?
  end
  
  def viewer?
    has_role?('VIEWER') || admin?
  end
  
  def can_screen_transactions?
    active? && (screener? || admin?)
  end
  
  def can_approve_transactions?
    active? && (approver? || admin?)
  end
  
  def can_view_transactions?
    active? && (viewer? || screener? || approver? || admin?)
  end
  
  def can_manage_users?
    active? && (admin? || super_admin?)
  end
  
  # Status methods
  def active?
    active == true
  end
  
  def inactive?
    !active?
  end
  
  def activate!
    update(active: true)
  end
  
  def deactivate!
    update(active: false)
  end
  
  # Role management
  def add_role(role_code)
    role = Role.find_by(code: role_code)
    return false unless role
    
    user_roles.find_or_create_by(role: role)
  end
  
  def remove_role(role_code)
    role = Role.find_by(code: role_code)
    return false unless role
    
    user_role = user_roles.find_by(role: role)
    user_role&.destroy
  end
  
  def assign_roles(role_codes)
    role_codes = Array(role_codes)
    roles_to_assign = Role.where(code: role_codes)
    
    # Remove roles not in the list
    user_roles.where.not(role: roles_to_assign).destroy_all
    
    # Add new roles
    roles_to_assign.each do |role|
      user_roles.find_or_create_by(role: role)
    end
  end
  
  private
  
  def set_default_values
    self.active = true if active.nil?
    self.user_type = 'viewer' if user_type.blank?
  end
end
