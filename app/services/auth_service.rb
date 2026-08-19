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
      token = response.body.strip # Remove any quotes if present
      Rails.logger.info("✅ Access token obtained successfully")
      token
    else
      Rails.logger.error("❌ Failed to get access token: #{response.code} - #{response.body}")
      raise "Failed to obtain access token: #{response.body}"
    end
  end
  
  # Get token with caching
  def self.get_cached_token
    @token_cache ||= {}
    @token_cache[:token] ||= get_access_token
    @token_cache[:expires_at] ||= 1.hour.from_now
    
    # Refresh if expired (with 5-minute buffer)
    if Time.current > (@token_cache[:expires_at] - 5.minutes)
      @token_cache[:token] = get_access_token
      @token_cache[:expires_at] = 1.hour.from_now
    end
    
    @token_cache[:token]
  end
  
  # Clear cache (useful for testing)
  def self.clear_cache
    @token_cache = nil
  end
end
