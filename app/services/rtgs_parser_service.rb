# app/services/rtgs_parser_service.rb
class RtgsParserService
  # Characters that indicate the start of the next SWIFT field
  FIELD_BOUNDARY = /(?=\n:\d{2}[A-Z]?:|\n-}|$)/m

  def initialize(rtgs_message)
    @rtgs_message = rtgs_message.to_s
  end

  def call
    parsed = parse_rtgs_message

    {
      requestId:           generate_request_id,
      transactionDirection: determine_direction(parsed),
      transactionType:     parsed[:transaction_type] || 'CRED',
      transactionAmount:   parse_amount(parsed),
      transactionCurrency: parsed[:currency] || 'TZS',
      transactionDate:     format_date(parsed[:date]),
      clearingSystemRef:   'TZIMBAN',
      reference:           parsed[:reference],
      narrative:           parsed[:narrative],
      bankCode:            parsed[:account_with_institution],
      parties:             build_parties(parsed),
      agents:              build_agents(parsed),
      narratives:          build_narratives(parsed),
      forensicData:        {},
      rawFields:           parsed,
      processingType:      'CHECK',
      profile:             'Tanzania',
      profileName:         'Tanzania'
    }
  end

  private

  # ---------------------------------------------------------------
  # Field extraction
  # ---------------------------------------------------------------
  def parse_rtgs_message
    fields = {}

    # :20: Transaction Reference
    if @rtgs_message =~ /:20:([^\r\n]+)/
      fields[:reference] = $1.strip
    end

    # :23B: Bank Operation Code
    if @rtgs_message =~ /:23B:([^\r\n]+)/
      fields[:transaction_type] = $1.strip
    end

    # :32A: Value Date / Currency / Amount
    if @rtgs_message =~ /:32A:(\d{6})([A-Z]{3})([\d,\.]+)/
      fields[:date]     = $1
      fields[:currency] = $2
      fields[:amount]   = $3.gsub(',', '')
    end

    # :50F: Ordering Customer (multiline, ends at next :NN: field or -})
    if (m = @rtgs_message.match(/:50F:(.*?)(?=\r?\n:\d{2}[A-Z]?:|\r?\n-})/m))
      fields[:debtor] = clean_multiline(m[1])
    end

    # :52A: Ordering Institution
    if @rtgs_message =~ /:52A:([A-Z0-9]+)/
      fields[:ordering_institution] = $1.strip
    end

    # :57A: Account With Institution
    if @rtgs_message =~ /:57A:([A-Z0-9]+)/
      fields[:account_with_institution] = $1.strip
    end

    # :59: Beneficiary Customer (multiline)
    if (m = @rtgs_message.match(/:59:(.*?)(?=\r?\n:\d{2}[A-Z]?:|\r?\n-})/m))
      fields[:creditor] = clean_multiline(m[1])
    end

    # :70: Remittance Information (multiline) -- THE NARRATIVE
    if (m = @rtgs_message.match(/:70:(.*?)(?=\r?\n:\d{2}[A-Z]?:|\r?\n-})/m))
      fields[:narrative] = clean_multiline(m[1])
    end

    # :71A: Details of Charges
    if @rtgs_message =~ /:71A:([^\r\n]+)/
      fields[:charges] = $1.strip
    end

    # :72: Sender to Receiver Info
    if (m = @rtgs_message.match(/:72:(.*?)(?=\r?\n:\d{2}[A-Z]?:|\r?\n-})/m))
      fields[:sender_to_receiver] = clean_multiline(m[1])
    end

    fields
  end

  # Remove trailing `-}` etc and collapse multi-line with single space
  def clean_multiline(str)
    return nil if str.nil?

    str
      .gsub(/\r\n?/, "\n")
      .sub(/\n-.*\z/m, '')          # drop the trailing -}
      .lines
      .map(&:strip)
      .reject(&:empty?)
      .join(' ')
      .strip
  end

  # ---------------------------------------------------------------
  # Direction
  # ---------------------------------------------------------------
  def determine_direction(_parsed)
    if @rtgs_message =~ /\{2:O\d{3}/
      'IN'    # Outgoing message from counterparty = INCOMING to us
    elsif @rtgs_message =~ /\{2:I\d{3}/
      'OUT'   # Input to us = we are sending = OUTGOING
    else
      'IN'
    end
  end

  # ---------------------------------------------------------------
  # Amount
  # ---------------------------------------------------------------
  def parse_amount(parsed)
    return nil if parsed[:amount].blank?
    parsed[:amount].to_i
  end

  # ---------------------------------------------------------------
  # Date
  # ---------------------------------------------------------------
  def format_date(date_string)
    return Date.current.to_s if date_string.blank?
    "20#{date_string[0..1]}-#{date_string[2..3]}-#{date_string[4..5]}"
  rescue StandardError
    Date.current.to_s
  end

  def generate_request_id
    "IMTZTRX#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(6).upcase}"
  end

  # ---------------------------------------------------------------
  # Parties
  # ---------------------------------------------------------------
  def build_parties(parsed)
    parties = []

    if parsed[:debtor].present?
      parties << build_party(parsed[:debtor], 'Debtor')
    end

    if parsed[:creditor].present?
      parties << build_party(parsed[:creditor], 'Creditor')
    end

    parties
  end

  def build_party(raw, type)
    account, name, address = extract_party_info(raw, type)

    {
      partyId:       account.presence || generate_party_id,
      partyType:     type,
      fullName:      name.presence || 'UNKNOWN',
      nationalities: ['TZ'],
      addressLine:   address.presence || 'Tanzania',
      typeValue:     type
    }
  end

  # Parses SWIFT 50F / 59 blocks that look like:
  #   /30027507002
  #   1/BEAR ELECTRICAL LIMITED
  #   2/MBAGARA
  #   3/TZ/DAR ES SALAAM
  # or:
  #   /100269121
  #   NYOTA TANZANIA LIMITED
  def extract_party_info(raw, _type)
    lines = raw.lines.map(&:strip).reject(&:empty?)

    account = nil
    name    = nil
    addr    = []

    lines.each_with_index do |line, idx|
      # Account line: /30027507002
      if line =~ %r{\A/([A-Z0-9]+)\z}i
        account = $1
        next
      end

      # Numbered address lines: 1/name, 2/address, 3/country/city
      if line =~ %r{\A\d/(.+)\z}
        part = $1.strip
        if idx <= 1 && name.nil?
          name = part
        else
          addr << part
        end
        next
      end

      # Free-form: first non-numbered line is the name, rest is address
      if name.nil?
        name = line
      else
        addr << line
      end
    end

    # Try to clean "1/BEAR ELECTRICAL LIMITED" -> "BEAR ELECTRICAL LIMITED"
    name = name.sub(%r{\A\d+/}, '') if name

    [account, name, addr.join(' ')&.strip]
  end

  def generate_party_id
    "PTY#{SecureRandom.hex(4).upcase}"
  end

  # ---------------------------------------------------------------
  # Agents
  # ---------------------------------------------------------------
  def build_agents(parsed)
    agents = []

    if parsed[:ordering_institution].present?
      agents << {
        agentId:   parsed[:ordering_institution],
        agentType: 'InstructingAgent',
        bic:       parsed[:ordering_institution],
        typeValue: 'InstructingAgent'
      }
    end

    if parsed[:account_with_institution].present?
      agents << {
        agentId:   parsed[:account_with_institution],
        agentType: 'InstructedAgent',
        bic:       parsed[:account_with_institution],
        typeValue: 'InstructedAgent'
      }
    end

    if agents.empty?
      agents << { agentId: 'IMBLTZTZ', agentType: 'InstructingAgent',
                  bic: 'IMBLTZTZ', typeValue: 'InstructingAgent' }
      agents << { agentId: 'CRDBTZTZ', agentType: 'InstructedAgent',
                  bic: 'CRDBTZTZ', typeValue: 'InstructedAgent' }
    end

    agents
  end

  # ---------------------------------------------------------------
  # Narratives
  # ---------------------------------------------------------------
  def build_narratives(parsed)
    remittance_info = parsed[:narrative].presence || 'RTGS Transaction'

    {
      remittanceInfo: remittance_info,
      all:            [remittance_info]
    }
  end
end
