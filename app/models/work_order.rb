class WorkOrder < ApplicationRecord
  belongs_to :asset
  belongs_to :breakdown_reason, class_name: 'BreakdownReason', optional: true
  belongs_to :reported_by, class_name: 'User'
  belongs_to :assigned_mechanic, class_name: 'User', optional: true
  
  has_many :wo_parts, dependent: :destroy
  has_many :wo_lubricants, dependent: :destroy
  has_many :parts, through: :wo_parts
  has_many :lubricants, through: :wo_lubricants

  # Enums
  enum wo_type: {
    preventive: 'preventive',
    breakdown: 'breakdown',
    inspection: 'inspection',
    campaign: 'campaign',
    top_up: 'top_up'
  }

  enum priority: {
    emergency: 'emergency',
    high: 'high',
    medium: 'medium',
    low: 'low'
  }

  enum status: {
    draft: 'draft',
    reported: 'reported',
    scheduled: 'scheduled',
    assigned: 'assigned',
    in_progress: 'in_progress',
    pending_parts: 'pending_parts',
    on_hold: 'on_hold',
    completed: 'completed',
    verified: 'verified',
    closed: 'closed',
    cancelled: 'cancelled'
  }

  # Validations
  validates :wo_number, presence: true, uniqueness: true
  validates :reported_at, presence: true
  
  # Callbacks
  before_validation :generate_wo_number, on: :create
  before_save :calculate_total_cost

  # Scopes
  scope :active, -> { where.not(status: ['completed', 'closed', 'cancelled']) }
  scope :breakdowns, -> { where(wo_type: 'breakdown') }
  scope :overdue, -> { where("reported_at < ? AND status NOT IN (?)", 24.hours.ago, ['completed', 'closed', 'cancelled']) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'emergency' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END")) }

  # Methods
  def hours_since_report
    return 0 unless reported_at
    ((Time.current - reported_at) / 3600).round(1)
  end

  def sla_status
    return 'Completed' if completed?
    
    case priority
    when 'emergency'
      hours_since_report > 1 ? 'OVERDUE' : 'ON_TRACK'
    when 'high'
      hours_since_report > 4 ? 'OVERDUE' : 'ON_TRACK'
    when 'medium'
      hours_since_report > 24 ? 'OVERDUE' : 'ON_TRACK'
    else
      'ON_TRACK'
    end
  end

  def add_part(part, quantity)
    wo_parts.create!(
      part: part,
      quantity_used: quantity,
      unit_cost: part.unit_cost,
      total_cost: part.unit_cost * quantity
    )
    update_total_cost
  end

  private

  def generate_wo_number
    return if wo_number.present?
    
    year = Time.current.year
    last_wo = WorkOrder.where("wo_number LIKE ?", "WO-#{year}-%").order(:wo_number).last
    
    if last_wo
      last_number = last_wo.wo_number.split('-').last.to_i
      self.wo_number = "WO-#{year}-#{(last_number + 1).to_s.rjust(5, '0')}"
    else
      self.wo_number = "WO-#{year}-00001"
    end
  end

  def calculate_total_cost
    self.total_cost = wo_parts.sum(:total_cost) + wo_lubricants.sum(:total_cost)
  end

  def update_total_cost
    update_column(:total_cost, calculate_total_cost)
  end
end
