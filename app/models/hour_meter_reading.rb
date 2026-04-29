# app/models/hour_meter_reading.rb

class HourMeterReading < ApplicationRecord
  belongs_to :asset
  belongs_to :recorded_by, class_name: 'User', optional: true
  
  # Validations
  validates :asset_id, presence: true
  validates :hour_meter, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :reading_date, presence: true
  
  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :for_asset, ->(asset) { where(asset_id: asset.id) }
  scope :ordered, -> { order(reading_date: :desc) }
  scope :since, ->(date) { where('reading_date >= ?', date) }
  
  # Methods
  def previous_reading
    @previous_reading ||= HourMeterReading.where(asset_id: asset_id)
                            .where('reading_date < ?', reading_date)
                            .order(reading_date: :desc)
                            .first
  end
  
  def daily_average
    return nil unless previous_reading
    
    days = ((reading_date - previous_reading.reading_date) / 1.day).to_f
    return nil if days <= 0
    
    diff = hour_meter - previous_reading.hour_meter
    (diff / days).round(1)
  end
end
