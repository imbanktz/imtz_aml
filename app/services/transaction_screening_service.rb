class TransactionScreeningService
  include HTTParty
  
  def initialize
    @token = AuthService.get_cached_token
  end

  def screen_transaction(transaction)
    payload = build_payload_from_transaction(transaction)
    send_screening_request(payload, transaction)
  end

  def screen_rtgs_message(rtgs_message)
    parser = RtgsParserService.new(rtgs_message)
    parsed_data = parser.call
    
    # Log parsed data
    puts "\n" + "=" * 80
    puts "📋 RTGS PARSED DATA"
    puts "=" * 80
    puts JSON.pretty_generate(parsed_data)
    puts "=" * 80 + "\n"
    
    send_screening_request(parsed_data)
  end

  def screen_payload(payload)
    send_screening_request(payload)
  end

  private

  def send_screening_request(payload, transaction = nil)
    # Log the request
    log_screening_request(payload)
    
    begin
      # Make the request with the current token
      response = make_request(payload)
      
      # If token expired, refresh and retry once
      if response.code == 401
        Rails.logger.warn("⚠️ Token expired, refreshing...")
        @token = AuthService.get_cached_token(force_refresh: true)
        
        response = make_request(payload)
      end
      
      # Log response
      log_screening_response(response)
      
      # Process response
      if transaction.present?
        process_response(response, transaction)
      else
        {
          success: response.success?,
          status: response.code,
          body: response.body,
          headers: response.headers
        }
      end
      
    rescue StandardError => e
      Rails.logger.error("❌ Screening request failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      {
        success: false,
        error: e.message,
        status: nil
      }
    end
  end

  def make_request(payload)
    self.class.post(
      "#{THETARAY_BASE_URL}#{SCREENING_ENDPOINT}",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@token}"
      },
      body: payload.to_json
    )
  end

  def build_payload_from_transaction(transaction)
    {
      requestId: transaction.request_id,
      transactionDirection: transaction.transaction_direction,
      transactionAmount: (transaction.transaction_amount * 100).to_i,
      transactionCurrency: transaction.transaction_currency,
      transactionDate: transaction.transaction_date.to_s,
      clearingSystemRef: transaction.clearing_system_ref || 'TZIMBAN',
      parties: transaction.parties,
      agents: transaction.agents,
      narratives: transaction.narratives,
      forensicData: transaction.forensic_data || {},
      processingType: transaction.processing_type || 'CHECK',
      profile: transaction.profile || 'Tanzania',
      profileName: transaction.profile_name || 'Tanzania'
    }
  end

  def log_screening_request(payload)
    Rails.logger.info("=" * 80)
    Rails.logger.info("📤 SCREENING REQUEST")
    Rails.logger.info("=" * 80)
    Rails.logger.info("URL: #{THETARAY_BASE_URL}#{SCREENING_ENDPOINT}")
    Rails.logger.info("Token (first 20 chars): #{@token[0..20]}...")
    Rails.logger.info("Payload:")
    Rails.logger.info(JSON.pretty_generate(payload))
    Rails.logger.info("=" * 80)
    
    # Also output to console in development
    if Rails.env.development?
      puts "\n" + "=" * 80
      puts "📤 SCREENING REQUEST"
      puts "=" * 80
      puts "URL: #{THETARAY_BASE_URL}#{SCREENING_ENDPOINT}"
      puts "Token (first 20 chars): #{@token[0..20]}..."
      puts "Payload:"
      puts JSON.pretty_generate(payload)
      puts "=" * 80 + "\n"
    end
  end

  def log_screening_response(response)
    Rails.logger.info("=" * 80)
    Rails.logger.info("📥 SCREENING RESPONSE")
    Rails.logger.info("=" * 80)
    Rails.logger.info("Status: #{response.code}")
    Rails.logger.info("Body:")
    begin
      if response.body.present?
        parsed_body = JSON.parse(response.body)
        Rails.logger.info(JSON.pretty_generate(parsed_body))
      else
        Rails.logger.info("(empty response)")
      end
    rescue JSON::ParserError
      Rails.logger.info(response.body)
    end
    Rails.logger.info("=" * 80)
    
    if Rails.env.development?
      puts "\n" + "=" * 80
      puts "📥 SCREENING RESPONSE"
      puts "=" * 80
      puts "Status: #{response.code}"
      puts "Body:"
      begin
        if response.body.present?
          parsed_body = JSON.parse(response.body)
          puts JSON.pretty_generate(parsed_body)
        else
          puts "(empty response)"
        end
      rescue JSON::ParserError
        puts response.body
      end
      puts "=" * 80 + "\n"
    end
  end

  def process_response(response, transaction)
    if response.success?
      screening_result = JSON.parse(response.body) rescue {}
      
      transaction.update(
        screening_status: 'completed',
        screening_result: screening_result,
        screening_attempts: (transaction.screening_attempts || []) << {
          timestamp: Time.current.iso8601,
          status: 'success',
          result: screening_result
        }
      )
      
      { success: true, result: screening_result }
    else
      transaction.update(
        screening_status: 'failed',
        screening_attempts: (transaction.screening_attempts || []) << {
          timestamp: Time.current.iso8601,
          status: 'failed',
          error: response.body
        }
      )
      
      { success: false, error: response.body, status: response.code }
    end
  end
end
