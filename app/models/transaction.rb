class Transaction < ApplicationRecord

   attribute :job_id, :string
  
  # Scopes
  scope :queued, -> { where(screening_status: 'QUEUED') }
  scope :processing, -> { where(screening_status: 'PROCESSING') }
  
  # Enums with prefixes to avoid method conflicts
  enum transaction_direction: {
         in: 'IN',
         out: 'OUT'
       }
  
  enum transaction_type: {
         incoming: 'INCOMING',
         outgoing: 'OUTGOING',
         unknown: 'UNKNOWN'
       }
  
  # Status enum with prefix
  enum status: {
         pending: 'PENDING',
         pending_screening: 'PENDING_SCREENING',
         screening: 'SCREENING',
         screened: 'SCREENED',
         screening_failed: 'SCREENING_FAILED',
         pending_review: 'PENDING_REVIEW',
         approved: 'APPROVED',
         rejected: 'REJECTED',
         processed: 'PROCESSED',
         failed: 'FAILED'
       }, _prefix: :status
  
  # Screening status enum with prefix
  enum screening_status: {
         pending: 'PENDING',
         passed: 'PASSED',
         failed: 'FAILED',
         error: 'ERROR',
         queued: 'QUEUED',
         processing: 'PROCESSING'
       }, _prefix: :screening

  # Validations
  validates :request_id, presence: true, uniqueness: true
  validates :transaction_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_currency, presence: true
  validates :transaction_date, presence: true
  validates :transaction_direction, presence: true
  validates :raw_rtgs_message, presence: true
  
  # No serialize needed for json/jsonb columns in PostgreSQL
  # The data is automatically serialized/deserialized by ActiveRecord
  
  # Scopes
  scope :incoming, -> { where(transaction_direction: 'IN') }
  scope :outgoing, -> { where(transaction_direction: 'OUT') }
  scope :by_date, ->(date) { where(transaction_date: date) }
  scope :by_currency, ->(currency) { where(transaction_currency: currency) }
  scope :by_amount_range, ->(min, max) { where(transaction_amount: min..max) }
  scope :by_reference, ->(ref) { where('reference ILIKE ?', "%#{ref}%") }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
  
  # Status scopes
  scope :pending_screening, -> { where(status: 'PENDING_SCREENING') }
  scope :screened, -> { where(status: 'SCREENED') }
  scope :screening_passed, -> { where(screening_status: 'PASSED') }
  scope :screening_failed, -> { where(screening_status: 'FAILED') }
  scope :approved, -> { where(status: 'APPROVED') }
  scope :rejected, -> { where(status: 'REJECTED') }
  scope :pending_review, -> { where(status: 'PENDING_REVIEW') }
  
  # Callbacks
  before_validation :set_default_values, on: :create
  after_create :process_after_creation, if: -> { status == 'PENDING' }
  
  # Instance methods
  def debtor
    parties&.find { |p| p["partyType"] == "Debtor" }
  end
  
  def creditor
    parties&.find { |p| p["partyType"] == "Creditor" }
  end
  
  def formatted_amount
    "#{transaction_currency} #{transaction_amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  
  def is_incoming?
    transaction_direction == 'IN'
  end
  
  def is_outgoing?
    transaction_direction == 'OUT'
  end
  
  def screening_passed?
    screening_status == 'PASSED'
  end
  
  def screening_failed?
    screening_status == 'FAILED'
  end
  
  def can_process?
    ['PENDING', 'PENDING_SCREENING'].include?(status)
  end
  
  def can_screen?
    ['PENDING_SCREENING', 'SCREENING_FAILED'].include?(status)
  end
  
  def processed?
    ['PROCESSED', 'APPROVED', 'REJECTED'].include?(status)
  end
  
  # Class methods
  def self.process_pending
    where(status: 'PENDING').each do |transaction|
      ProcessRtgsWithScreeningJob.perform_later(transaction.raw_rtgs_message)
    end
  end
  
  def self.screening_summary
    {
      total: count,
      pending_screening: pending_screening.count,
      screened: screened.count,
      screening_failed: screening_failed.count,
      screening_passed: screening_passed.count,
      approved: approved.count,
      rejected: rejected.count,
      pending_review: pending_review.count,
      by_status: group(:status).count,
      by_screening_status: group(:screening_status).count,
      by_direction: group(:transaction_direction).count,
      by_currency: group(:transaction_currency).sum(:transaction_amount)
    }
  end

  # Status helpers
  def queued?
    screening_status == 'QUEUED'
  end
  
  def processing?
    screening_status == 'PROCESSING'
  end
  
  def completed?
    screening_status == 'PASSED'
  end
  
  def failed?
    screening_status == 'FAILED'
  end
  
  private
  
  def set_default_values
    self.status ||= 'PENDING'
    self.transaction_direction ||= 'IN'
    self.transaction_type ||= 'UNKNOWN'
    self.transaction_currency ||= 'TZS'
    self.transaction_amount ||= 0
    self.transaction_date ||= Date.today
    self.parties ||= []
    self.screening_status ||= 'PENDING'
  end
  
  def process_after_creation
    # Queue for screening if not already processed
    if status == 'PENDING'
      ProcessRtgsWithScreeningJob.perform_later(raw_rtgs_message)
    end
  end
end
