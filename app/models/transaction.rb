class Transaction < ApplicationRecord
  # Validations
  validates :request_id, presence: true, uniqueness: true
  validates :transaction_amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_currency, presence: true
  validates :transaction_direction, presence: true, inclusion: { in: ['IN', 'OUT'] }
  validates :processing_type, presence: true
  
  # Scopes
  scope :inbound, -> { where(transaction_direction: 'IN') }
  scope :outbound, -> { where(transaction_direction: 'OUT') }
  scope :by_currency, ->(currency) { where(transaction_currency: currency) }
  scope :by_processing_type, ->(type) { where(processing_type: type) }
  scope :by_date_range, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }
  
  # Custom JSON query methods
  def debtor_party
    parties.find { |p| p['partyType'] == 'Debtor' }
  end
  
  def creditor_party
    parties.find { |p| p['partyType'] == 'Creditor' }
  end
  
  def instructing_agent
    agents.find { |a| a['agentType'] == 'InstructingAgent' }
  end
  
  def instructed_agent
    agents.find { |a| a['agentType'] == 'InstructedAgent' }
  end
  
  def remittance_info
    narratives['remittanceInfo']
  end
  
  # Class methods for JSONB queries
  def self.by_debtor_name(name)
    where("parties @> ?", [{ partyType: 'Debtor', fullName: name }].to_json)
  end
  
  def self.by_creditor_name(name)
    where("parties @> ?", [{ partyType: 'Creditor', fullName: name }].to_json)
  end
  
  def self.by_agent_bic(bic)
    where("agents @> ?", [{ bic: bic }].to_json)
  end
  
  def self.by_narrative_keyword(keyword)
    where("narratives->>'remittanceInfo' ILIKE ?", "%#{keyword}%")
  end
  
  def self.by_nationality(country_code)
    where("parties @> ?", [{ nationalities: [country_code] }].to_json)
  end
end
