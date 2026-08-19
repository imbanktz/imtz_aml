class RtgsParserService
  def initialize(rtgs_message)
    @rtgs_message = rtgs_message
  end

  def call
    parsed = parse_rtgs_message
    
    {
      requestId: generate_request_id,
      transactionDirection: determine_direction(parsed),
      transactionAmount: parse_amount(parsed),
      transactionCurrency: parsed[:currency] || 'TZS',
      transactionDate: format_date(parsed[:date]),
      clearingSystemRef: 'TZIMBAN',
      parties: build_parties(parsed),
      agents: build_agents(parsed),
      narratives: build_narratives(parsed),
      forensicData: {},
      processingType: 'CHECK',
      profile: 'Tanzania',
      profileName: 'Tanzania'
    }
  end

  private

  def parse_rtgs_message
    # Parse SWIFT MT103 message
    fields = {}
    
    # Transaction Reference (:20:)
    if @rtgs_message =~ /:20:([^\n:]+)/
      fields[:reference] = $1.strip
    end
    
    # Date, Currency, Amount (:32A:)
    if @rtgs_message =~ /:32A:(\d{6})([A-Z]{3})([\d,]+)/
      fields[:date] = $1
      fields[:currency] = $2
      fields[:amount] = $3.gsub(',', '')
    end
    
    # Debtor/Ordering Customer (:50F:)
    if @rtgs_message =~ /:50F:(.+?)(?=:52A:|:57A:|:59:|:70:|:71A:|:72:|$)/
      fields[:debtor] = $1.strip
    end
    
    # Beneficiary/Creditor (:59:)
    if @rtgs_message =~ /:59:(.+?)(?=:70:|:71A:|:72:|$)/
      fields[:creditor] = $1.strip
    end
    
    # Remittance Information (:70:)
    if @rtgs_message =~ /:70:(.+?)(?=:71A:|:72:|$)/
      fields[:narrative] = $1.strip
    end
    
    # Ordering Institution (:52A:)
    if @rtgs_message =~ /:52A:([A-Z0-9]+)/
      fields[:ordering_institution] = $1.strip
    end
    
    # Account With Institution (:57A:)
    if @rtgs_message =~ /:57A:([A-Z0-9]+)/
      fields[:account_with_institution] = $1.strip
    end
    
    fields
  end

  def determine_direction(parsed)
    if @rtgs_message =~ /{2:O103/
      'IN'
    elsif @rtgs_message =~ /{2:I103/
      'OUT'
    else
      'IN'
    end
  end

  # app/services/rtgs_parser_service.rb - Check parse_amount method

  def parse_amount(parsed)
    # Get the amount from 32A field
    amount_field = parsed['32A'] || parsed['33B']
    return nil unless amount_field
    # Extract amount - format is YYMMDDCURAMOUNT
    # Example: 260623TZS174308602,00
    match = amount_field.match(/([A-Z]{3})([\d,]+)/)
    return nil unless match
    currency = match[1]
    amount_str = match[2].gsub(',', '') # Remove commas
    # Convert to integer (cents)
    amount_str.to_i
  end
  
  def format_date(date_string)
    return Date.current.to_s unless date_string
    
    year = "20#{date_string[0..1]}"
    month = date_string[2..3]
    day = date_string[4..5]
    
    "#{year}-#{month}-#{day}"
  rescue StandardError
    Date.current.to_s
  end

  def generate_request_id
    "IMTZTRX#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(6).upcase}"
  end

  def build_parties(parsed)
    parties = []
    
    # Debtor
    if parsed[:debtor].present?
      debtor_info = parsed[:debtor]
      
      # Extract account and name
      account = nil
      name = nil
      address = ''
      
      if debtor_info =~ /\/(\d+)/
        account = $1
      end
      
      # Extract name (after account or from beginning)
      if debtor_info =~ /\/(\d+)\s+([A-Z][A-Z\s]+)/
        name = $2.strip
      elsif debtor_info =~ /([A-Z][A-Z\s]+)/
        name = $1.strip
      end
      
      # Extract address
      if debtor_info =~ /\/TZ\/([^\/]+)/
        address = $1.strip
      end
      
      parties << {
        partyId: account || generate_party_id,
        partyType: "Debtor",
        fullName: name.presence || "UNKNOWN",
        nationalities: ["TZ"],
        addressLine: address.presence || "Tanzania",
        typeValue: "Debtor"
      }
    end
    
    # Creditor
    if parsed[:creditor].present?
      creditor_info = parsed[:creditor]
      
      account = nil
      name = nil
      address = ''
      
      if creditor_info =~ /\/(\d+)/
        account = $1
      end
      
      if creditor_info =~ /\/(\d+)\s+(.+)/
        name = $2.strip
      elsif creditor_info =~ /([A-Z][A-Z\s]+)/
        name = $1.strip
      end
      
      parties << {
        partyId: account || generate_party_id,
        partyType: "Creditor",
        fullName: name.presence || "UNKNOWN",
        nationalities: ["TZ"],
        addressLine: address.presence || "Tanzania",
        typeValue: "Creditor"
      }
    end
    
    parties
  end

  def build_agents(parsed)
    agents = []
    
    if parsed[:ordering_institution].present?
      agents << {
        agentId: parsed[:ordering_institution],
        agentType: "InstructingAgent",
        bic: parsed[:ordering_institution],
        typeValue: "InstructingAgent"
      }
    end
    
    if parsed[:account_with_institution].present?
      agents << {
        agentId: parsed[:account_with_institution],
        agentType: "InstructedAgent",
        bic: parsed[:account_with_institution],
        typeValue: "InstructedAgent"
      }
    end
    
    # Default agents if none found
    if agents.empty?
      agents << {
        agentId: "IMBLTZTZ",
        agentType: "InstructingAgent",
        bic: "IMBLTZTZ",
        typeValue: "InstructingAgent"
      }
      agents << {
        agentId: "CRDBTZTZ",
        agentType: "InstructedAgent",
        bic: "CRDBTZTZ",
        typeValue: "InstructedAgent"
      }
    end
    
    agents
  end

  def build_narratives(parsed)
    remittance_info = parsed[:narrative] || "RTGS Transaction"
    
    {
      remittanceInfo: remittance_info,
      all: [remittance_info]
    }
  end

  def generate_party_id
    "PTY#{SecureRandom.hex(4).upcase}"
  end
end
