# config/initializers/screening.rb
Rails.application.config.tap do |config|
  config.screening = ActiveSupport::Configurable::Configuration.new
  config.screening.base_url = ENV['SCREENING_BASE_URL'] || 'https://apps-tanzania-screening.imbank.thetaray.cloud'
  config.screening.token_endpoint = '/security/accessToken'
  config.screening.screening_endpoint = '/screening/transaction/generic/check'
  config.screening.client_secret = ENV['SCREENING_CLIENT_SECRET'] || 'thetaray'
  config.screening.token_cache_duration = 55.minutes
end
