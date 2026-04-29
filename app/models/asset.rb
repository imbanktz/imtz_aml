class Asset < ApplicationRecord
  belongs_to :model, class_name: 'AssetModel', optional: true
  belongs_to :primary_operator, class_name: 'User', optional: true
  
  has_many :work_orders
  has_many :hour_meter_readings
  has_many :lubricant_consumptions
  has_many :monthly_availabilities

  # Enums
  enum current_status: {
         operational: 'Operational',
         in_repair: 'In Repair',
         on_pm: 'On PM',
         idle: 'Idle',
         deployed: 'Deployed',
         stored: 'Stored',
         scrapped: 'Scrapped'
       }

  # This will create methods like asset_workshop?, asset_store?,
  # etc., avoiding any conflicts with existing Rails methods.
  enum current_location_type: {
         workshop: 'workshop',
         farm: 'farm',
         store: 'store',
         yard: 'yard'
       }, _prefix: true
  
  # enum current_location_type: {
  #        workshop: 'workshop',
  #        farm: 'farm',
  #        store: 'store',
  #        yard: 'yard'
  #      }

  # Validations
  validates :fleet_number, presence: true, uniqueness: true
  validates :serial_number, uniqueness: true, allow_blank: true
  validates :current_hour_meter, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :operational, -> { where(current_status: 'operational') }
  scope :by_fleet_number, ->(number) { where("fleet_number ILIKE ?", "%#{number}%") }

  # Callbacks
  before_save :update_last_meter_update

  # Methods
  def full_description
    "#{fleet_number} - #{model&.model_name} - #{current_hour_meter} hrs"
  end

  def current_location_name
    return nil unless current_location_id
    
    case current_location_type
    when 'workshop'
      Workshop.find_by(id: current_location_id)&.name
    when 'farm'
      Farm.find_by(id: current_location_id)&.farm_name
    else
      'Unknown'
    end
  end

  def availability_for_month(month_date)
    monthly_availabilities.find_by(month: month_date.beginning_of_month)
  end

  private

  def update_last_meter_update
    self.last_meter_update = Date.today if current_hour_meter_changed?
  end
end
