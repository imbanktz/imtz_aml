class AuthService
  include HTTParty
  
  def self.get_access_token
    new.get_access_token
  end
  
  def get_access_token
    response = self.class.post(
      "#{THETARAY_BASE_URL}#{TOKEN_ENDPOINT}",
      headers: {
        'Content-Type' => 'application/json'
      },
      body: {
        clientSecret: 'thetaray'
      }.to_json
    )
    
    if response.success?
      # Parse the JSON response to extract the token
      parsed_response = JSON.parse(response.body)
      token = parsed_response['token']
      Rails.logger.info("✅ Access token obtained successfully")
      Rails.logger.debug("Token expires in: #{parsed_response['expirationInMinutes']} minutes")
      token
    else
      Rails.logger.error("❌ Failed to get access token: #{response.code} - #{response.body}")
      raise "Failed to obtain access token: #{response.body}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error("❌ Failed to parse token response: #{e.message}")
    raise "Invalid token response format: #{response.body}"
  end
  
  # Get token with caching
  def self.get_cached_token(force_refresh: false)
    @token_cache ||= {}
    
    if force_refresh || !@token_cache[:token] || Time.current > (@token_cache[:expires_at] - 2.minutes)
      @token_cache[:token] = get_access_token
      @token_cache[:expires_at] = 5.minutes.from_now # Token expires in 5 minutes
    end
    
    @token_cache[:token]
  end
  
  # Clear cache
  def self.clear_cache
    @token_cache = nil
  end
  
  # Test token validity
  def self.test_token
    token = get_cached_token(force_refresh: true)
    
    payload = {
      requestId: "TEST_#{Time.current.to_i}",
      transactionDirection: "OUT",
      transactionAmount: 1000,
      transactionCurrency: "TZS",
      transactionDate: Date.current.to_s,
      clearingSystemRef: "TZIMBAN",
      parties: [
        {
          partyId: "TEST001",
          partyType: "Debtor",
          fullName: "Test Debtor",
          nationalities: ["TZ"],
          addressLine: "Dar Es Salaam, TZ",
          typeValue: "Debtor"
        }
      ],
      agents: [
        {
          agentId: "IMBLTZTZ",
          agentType: "InstructingAgent",
          bic: "IMBLTZTZ",
          typeValue: "InstructingAgent"
        }
      ],
      narratives: {
        remittanceInfo: "TEST",
        all: ["TEST"]
      },
      forensicData: {},
      processingType: "CHECK",
      profile: "Tanzania",
      profileName: "Tanzania"
    }
    
    response = HTTParty.post(
      "https://apps-tanzania-screening.imbank.thetaray.cloud/screening/transaction/generic/check",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      },
      body: payload.to_json
    )
    
    puts "\n" + "=" * 80
    puts "🔍 TOKEN TEST RESULTS"
    puts "=" * 80
    puts "Token (first 30 chars): #{token[0..30]}..."
    puts "Status: #{response.code}"
    puts "Success: #{response.success?}"
    puts "Body: #{response.body}"
    puts "=" * 80 + "\n"
    
    response
  end
end
