# app/models/lubricant_consumption.rb

class LubricantConsumption < ApplicationRecord
  belongs_to :asset
  belongs_to :work_order, optional: true
  belongs_to :recorded_by, class_name: 'User'

  # Validations
  validates :transaction_date, presence: true
  validates :lubricant_type, presence: true
  # Fixed: Changed from greater_than to greater_than_or_equal_to
  validates :quantity, numericality: { greater_than_or_equal_to: 0.01, message: "must be greater than 0" }

  # Enums for lubricant types
  LUBRICANT_TYPES = %w[
    ATF 10W ISO_68 SAE_50 80W90 TDH_MVP 15W40 10W30
    FLUIDE COOLANT GREASE DECREASE 85W140
  ].freeze

  validates :lubricant_type, inclusion: { in: LUBRICANT_TYPES }

  # Scopes
  scope :for_month, ->(date) { where(transaction_date: date.beginning_of_month..date.end_of_month) }
  scope :by_asset, ->(asset_id) { where(asset_id: asset_id) }

  # Methods
  def self.summary_for_month(date)
    where(transaction_date: date.beginning_of_month..date.end_of_month)
      .group(:lubricant_type)
      .sum(:quantity)
  end
end
