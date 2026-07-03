class AuthTokenService
  TOKEN_URL = 'https://keycloak-shared-pre.imbank.thetaray.cloud/auth/realms/applications/protocol/openid-connect/token'
  
  class << self
    def get_valid_token
      Rails.cache.fetch('screening_auth_token', expires_in: 5.minutes) do
        fetch_new_token
      end
    end

    private

    def fetch_new_token
      client_id = ENV['SCREENING_CLIENT_ID'] || 'apps_tanzania_screening_api'
      client_secret = ENV['SCREENING_CLIENT_SECRET']
      
      uri = URI(TOKEN_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data({
        'grant_type' => 'client_credentials',
        'client_id' => client_id,
        'client_secret' => client_secret
      })
      
      response = http.request(request)
      
      if response.code.to_i == 200
        result = JSON.parse(response.body)
        result['access_token']
      else
        Rails.logger.error "Failed to fetch auth token: #{response.code} - #{response.body}"
        nil
      end
    end
  end
end
