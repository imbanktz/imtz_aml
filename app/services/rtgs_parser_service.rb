# app/services/rtgs_parser_service.rb
class RtgsParserService
  attr_reader :raw_message, :parsed_data, :transaction_type

  def initialize(raw_message)
    @raw_message = raw_message
    @parsed_data = {}
    @transaction_type = determine_transaction_type
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

  def determine_transaction_type
    if raw_message.include?("{2:I103") || raw_message.include?(":23B:CRED")
      "INCOMING"
    elsif raw_message.include?("{2:O103") || raw_message.include?(":23B:DEBT")
      "OUTGOING"
    else
      "UNKNOWN"
    end
  end

  def parse_message
    # Extract the content between {4: and -}
    content_match = raw_message.match(/\{4:(.*?)\s*-\}/m)
    return {} if content_match.nil?
    
    content = content_match[1]
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
      "transactionDirection" => determine_direction,
      "transactionAmount" => extract_amount,
      "transactionCurrency" => extract_currency,
      "transactionDate" => extract_date,
      "parties" => extract_parties,
      "reference" => extract_reference,
      "narrative" => extract_narrative,
      "transactionType" => @transaction_type,
      "bankCode" => extract_bank_code,
      "rawFields" => @parsed_data
    }
  end

  def generate_request_id
    "imtz-trxscreening-#{SecureRandom.hex(6)}"
  end

  def determine_direction
    case @transaction_type
    when "INCOMING"
      "IN"
    when "OUTGOING"
      "OUT"
    else
      @parsed_data["23B"] == "CRED" ? "IN" : "OUT"
    end
  end

  def extract_amount
    # Field 32A contains amount
    amount_str = @parsed_data["32A"] || ""
    amount_match = amount_str.match(/(\d+[.,]?\d*)$/)
    amount_match ? amount_match[1].gsub(',', '') : "0"
  end

  def extract_currency
    # Field 32A contains currency code
    currency_str = @parsed_data["32A"] || ""
    currency_match = currency_str.match(/\d{6}([A-Z]{3})/)
    currency_match ? currency_match[1] : "TZS"
  end

  def extract_date
    # Field 32A contains date (YYMMDD format)
    date_str = @parsed_data["32A"] || ""
    date_match = date_str.match(/^(\d{6})/)
    return Date.today.strftime("%Y-%m-%d") if date_match.nil?
    
    begin
      Date.strptime(date_match[1], "%y%m%d").strftime("%Y-%m-%d")
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
    account_number = lines[0].to_s.gsub(/^\/+/, '')
    account_number = "UNKNOWN" if account_number.blank?
    
    # Parse name - handle different formats
    name = "UNKNOWN"
    lines.each do |line|
      if line.match?(/^\d+\//)
        name = line.gsub(/^\d+\//, '').strip
        break
      elsif line.match?(/^[A-Z\s]+$/) && !line.match?(%r{/}) && line.length > 3
        name = line.strip
        break
      end
    end
    
    # If name is still UNKNOWN, try line 1 or 2
    if name == "UNKNOWN"
      name = lines[1].to_s.strip if lines[1].present?
      name = lines[0].to_s.strip if name.blank? || name == "UNKNOWN"
    end
    
    # Parse address from subsequent lines
    address_lines = lines.select { |line| !line.match?(/^\d+\//) && line != name }
    address = address_lines.join(" ")
    
    # Extract nationality
    nationality = extract_nationality(debtor_data)
    
    {
      "partyId" => account_number,
      "partyType" => "Debtor",
      "fullName" => name.strip,
      "nationalities" => nationality ? [nationality] : [],
      "addressLine" => address
    }
  end

  def extract_creditor
    creditor_data = @parsed_data["59"] || ""
    return nil if creditor_data.blank?
    
    lines = creditor_data.split("\n").map(&:strip)
    
    # Parse account number from first line (remove leading /)
    account_number = lines[0].to_s.gsub(/^\/+/, '')
    account_number = "UNKNOWN" if account_number.blank?
    
    # Parse name from subsequent lines
    name = "UNKNOWN"
    address_lines = []
    
    lines.each_with_index do |line, index|
      if index == 1 && !line.match?(%r{/}) && line.present?
        name = line.strip
      elsif index > 1 && line.present?
        address_lines << line.strip
      end
    end
    
    # If name is still UNKNOWN, try to find it
    if name == "UNKNOWN"
      lines.each do |line|
        if line.match?(/^[A-Za-z\s]+$/) && !line.match?(%r{/}) && line.length > 3 && !line.match?(/\d/)
          name = line.strip
          break
        end
      end
    end
    
    # If still UNKNOWN, use the second line
    if name == "UNKNOWN" && lines[1].present?
      name = lines[1].strip
    end
    
    address = address_lines.join(" ")
    
    # Extract nationality
    nationality = extract_nationality(creditor_data)
    
    {
      "partyId" => account_number,
      "partyType" => "Creditor",
      "fullName" => name.strip,
      "nationalities" => nationality ? [nationality] : [],
      "addressLine" => address
    }
  end

  def extract_nationality(text)
    # Try to extract country code from various fields
    # Common patterns: /TZ/ or in address line
    if text =~ /\/([A-Z]{2})\//
      return $1
    elsif text =~ /\b([A-Z]{2})\s+\w+\s+\w+/
      return $1
    elsif text.include?("TANZANIA")
      return "TZ"
    elsif text.include?("KENYA")
      return "KE"
    elsif text.include?("UGANDA")
      return "UG"
    else
      nil
    end
  end

  def extract_reference
    @parsed_data["20"] || ""
  end

  def extract_narrative
    @parsed_data["70"] || @parsed_data["72"] || ""
  end

  def extract_bank_code
    bank_code = @parsed_data["57A"] || @parsed_data["52A"] || ""
    bank_code.gsub(/[^A-Z0-9]/, '')
  end
end
