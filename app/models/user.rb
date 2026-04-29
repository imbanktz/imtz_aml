class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable, :trackable
  devise :timeoutable
  # Include default devise modules
  # devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :primary_workshop, class_name: 'Workshop', optional: true
  has_many :reported_work_orders, class_name: 'WorkOrder', foreign_key: 'reported_by_id'
  has_many :assigned_work_orders, class_name: 'WorkOrder', foreign_key: 'assigned_mechanic_id'
  has_many :hour_meter_readings, foreign_key: 'recorded_by_id'
  
  validates :email, presence: true, uniqueness: true

  # Enums
  enum role: {
         viewer: 'viewer',
         planner: 'planner',
         manager: 'manager',
         admin: 'admin'
       }
  
  enum user_type: {
         driver: 'driver',
         operator: 'operator',
         mechanic: 'mechanic',
         engineer: 'engineer',
         maintenance_planner: 'maintenance_planner',
         storekeeper: 'storekeeper',
         supervisor: 'supervisor',
         imtz_aml: 'imtz_aml'
       }

  # Validations
  validates :employee_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :user_type, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :mechanics, -> { where(user_type: 'mechanic') }
  scope :planners, -> { where(user_type: 'maintenance_planner') }

  # Methods
  def full_name
    "#{employee_id} - #{name}"
  end

  def can_create_po?
    maintenance_planner? || imtz_aml?
  end

  def can_approve_wo?
    supervisor? || imtz_aml?
  end

  def can_create_schedule?
    maintenance_planner? || engineer? || imtz_aml?
  end
end
