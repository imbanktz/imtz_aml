# app/services/manual_rtgs_parser_service.rb
class ManualRtgsParserService
  attr_reader :content, :parsed_data

  def initialize(rtgs_message)
    @content = rtgs_message.is_a?(File) ? File.read(rtgs_message) : rtgs_message
    @parsed_data = {}
  end

  def call
    parse_fields
    build_parties
    build_result
  end

  private

  def parse_fields
    # Reference (field 20)
    if @content =~ /:20:([^\n]+)/
      @parsed_data['reference'] = $1.strip
    end

    # Transaction type (field 23B)
    if @content =~ /:23B:([^\n]+)/
      @parsed_data['transactionType'] = $1.strip
    end

    # Amount from 32A or 33B
    if @content =~ /:32A:\d{6}([A-Z]{3})([\d,]+)/
      @parsed_data['currency'] = $1
      @parsed_data['amount'] = $2.gsub(',', '').to_i
    elsif @content =~ /:33B:([A-Z]{3})([\d,]+)/
      @parsed_data['currency'] = $1
      @parsed_data['amount'] = $2.gsub(',', '').to_i
    end

    # Date from 32A
    if @content =~ /:32A:(\d{6})/
      date_str = $1
      @parsed_data['date'] = "20#{date_str[0..1]}-#{date_str[2..3]}-#{date_str[4..5]}"
    end

    # Debtor (field 50F)
    if @content =~ /:50F:(?:\/)?([^\n]+)\n([^\n]+)\n([^\n]+)/
      @parsed_data['debtor'] = {
        account: $1.strip,
        name: $2.strip,
        address: $3.strip
      }
    elsif @content =~ /:50F:(?:\/)?([^\n]+)\n([^\n]+)/
      @parsed_data['debtor'] = {
        account: $1.strip,
        name: $2.strip,
        address: ''
      }
    end

    # Creditor (field 59)
    if @content =~ /:59:(?:\/)?([^\n]+)\n([^\n]+)/
      @parsed_data['creditor'] = {
        account: $1.strip,
        name: $2.strip
      }
    elsif @content =~ /:59:(?:\/)?([^\n]+)/
      @parsed_data['creditor'] = {
        account: $1.strip,
        name: $1.strip
      }
    end

    # Narrative (field 70)
    if @content =~ /:70:([^\n]+)/
      @parsed_data['narrative'] = $1.strip
    end

    # Bank code (field 57A or from header)
    if @content =~ /:57A:([^\n]+)/
      @parsed_data['bankCode'] = $1.strip
    elsif @content =~ /{1:F01([A-Z]{8}[A-Z0-9]{3})/
      @parsed_data['bankCode'] = $1
    end

    # Determine direction
    if @content.include?(':50F:') && @content.include?(':59:')
      @parsed_data['direction'] = 'INCOMING'
    else
      @parsed_data['direction'] = 'UNKNOWN'
    end
  end

  def build_parties
    parties = []

    if @parsed_data['debtor']
      parties << {
        'partyId' => @parsed_data['debtor'][:account],
        'partyType' => 'Debtor',
        'fullName' => @parsed_data['debtor'][:name],
        'nationalities' => ['TZ'],
        'addressLine' => @parsed_data['debtor'][:address] || ''
      }
    end

    if @parsed_data['creditor']
      parties << {
        'partyId' => @parsed_data['creditor'][:account],
        'partyType' => 'Creditor',
        'fullName' => @parsed_data['creditor'][:name],
        'nationalities' => ['TZ'],
        'addressLine' => ''
      }
    end

    @parsed_data['parties'] = parties
  end

  def build_result
    {
      'requestId' => "IMTZTRX#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(6).upcase}",
      'reference' => @parsed_data['reference'],
      'transactionDirection' => @parsed_data['direction'] || 'INCOMING',
      'transactionAmount' => @parsed_data['amount'] || 0,
      'transactionCurrency' => @parsed_data['currency'] || 'TZS',
      'transactionDate' => @parsed_data['date'] || Date.current.to_s,
      'transactionType' => @parsed_data['transactionType'] || 'CRED',
      'narrative' => @parsed_data['narrative'],
      'bankCode' => @parsed_data['bankCode'],
      'parties' => @parsed_data['parties'] || [],
      'rawFields' => {
        '20' => @parsed_data['reference'],
        '23B' => @parsed_data['transactionType'],
        '32A' => @parsed_data['date'] ? "#{@parsed_data['date'].gsub('-', '')[2..7]}#{@parsed_data['currency']}#{@parsed_data['amount']}" : nil,
        '50F' => @parsed_data['debtor'] ? "#{@parsed_data['debtor'][:account]} #{@parsed_data['debtor'][:name]}" : nil,
        '59' => @parsed_data['creditor'] ? "#{@parsed_data['creditor'][:account]} #{@parsed_data['creditor'][:name]}" : nil,
        '70' => @parsed_data['narrative']
      }
    }
  end
end
