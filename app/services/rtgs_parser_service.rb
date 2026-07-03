class RtgsParserService
  attr_reader :raw_message, :parsed_data

  def initialize(raw_message)
    @raw_message = raw_message
    @parsed_data = {}
  end

  def call
    parse_message
    transform_to_target_format
  rescue StandardError => e
    Rails.logger.error "RTGS Parser Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  private

  def parse_message
    # Extract the content between {4: and -}
    content = raw_message.match(/\{4:(.*?)\s*-\}/m)&.[](1)
    return {} if content.blank?

    # Split by newlines and parse each field
    lines = content.split("\n").map(&:strip)
    
    current_field = nil
    current_value = ""
    field_data = {}

    lines.each do |line|
      if line.match?(/^:\d{2}[A-Z]?:/)
        # Save previous field if exists
        if current_field && !current_value.empty?
          field_data[current_field] = current_value.strip
        end
        
        # Parse new field
        if line =~ /^:(\d{2}[A-Z]?):(.*)/
          current_field = $1
          current_value = $2
        end
      else
        # Append to current field value (for multi-line fields)
        current_value += " " + line unless line.blank?
      end
    end

    # Save last field
    if current_field && !current_value.empty?
      field_data[current_field] = current_value.strip
    end

    @parsed_data = field_data
  end

  def transform_to_target_format
    {
      "requestId" => generate_request_id,
      "transactionDirection" => determine_transaction_direction,
      "transactionAmount" => extract_amount,
      "transactionCurrency" => extract_currency,
      "transactionDate" => extract_date,
      "parties" => extract_parties
    }
  end

  def generate_request_id
    "imtz-trxscreening-#{SecureRandom.hex(6)}"
  end

  def determine_transaction_direction
    # Based on field 23B: CRED = Credit (IN), DEBT = Debit (OUT)
    @parsed_data["23B"] == "CRED" ? "IN" : "OUT"
  end

  def extract_amount
    # Field 32A contains amount
    amount_str = @parsed_data["32A"] || ""
    amount_match = amount_str.match(/(\d+[.,]?\d*)$/)
    amount_match ? amount_match[1].gsub(',', '') : "0"
  end

  def extract_currency
    # Field 32A contains currency code
    @parsed_data["32A"]&.match(/^(\d{6}\w{3})/)?.[1]&.slice(6..8) || "TZS"
  end

  def extract_date
    # Field 32A contains date (YYMMDD format)
    date_str = @parsed_data["32A"]&.match(/^(\d{6})/)?.[1]
    return Date.today.strftime("%Y-%m-%d") if date_str.blank?
    
    begin
      Date.strptime(date_str, "%y%m%d").strftime("%Y-%m-%d")
    rescue StandardError
      Date.today.strftime("%Y-%m-%d")
    end
  end

  def extract_parties
    parties = []
    
    # Extract Debtor (Sender) from field 50F
    debtor = extract_debtor
    parties << debtor if debtor.present?
    
    # Extract Creditor (Beneficiary) from field 59
    creditor = extract_creditor
    parties << creditor if creditor.present?
    
    parties
  end

  def extract_debtor
    debtor_data = @parsed_data["50F"] || ""
    return nil if debtor_data.blank?
    
    lines = debtor_data.split("\n").map(&:strip)
    
    # Parse account number from first line
    account_number = lines[0]&.gsub(/^\/+/, '') || "UNKNOWN"
    
    # Parse name from second line
    name = lines[1] || "UNKNOWN"
    
    # Parse address from subsequent lines
    address = lines[2..]&.join(" ") || ""
    
    {
      "partyId" => account_number,
      "partyType" => "Debtor",
      "fullName" => name.strip,
      "nationalities" => [],
      "addressLine" => address
    }
  end

  def extract_creditor
    creditor_data = @parsed_data["59"] || ""
    return nil if creditor_data.blank?
    
    lines = creditor_data.split("\n").map(&:strip)
    
    # Parse account number from first line (remove leading /)
    account_number = lines[0]&.gsub(/^\/+/, '') || "UNKNOWN"
    
    # Parse name from second line
    name = lines[1] || "UNKNOWN"
    
    # Try to extract nationality from address or account number
    nationality = extract_nationality(creditor_data)
    
    {
      "partyId" => account_number,
      "partyType" => "Creditor",
      "fullName" => name.strip,
      "nationalities" => nationality ? [nationality] : [],
      "addressLine" => lines[2..]&.join(" ") || ""
    }
  end

  def extract_nationality(text)
    # Try to extract country code from various fields
    # Common patterns: /TZ/ or in address line
    if text =~ /\/([A-Z]{2})\//
      $1
    elsif text =~ /\b([A-Z]{2})\s+\w+\s+\w+/
      $1
    else
      nil
    end
  end
end
