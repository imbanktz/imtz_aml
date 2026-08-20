source "https://rubygems.org"

gem "rails", "6.1.7.7"
gem 'activeadmin', "~> 3.5.2"
gem 'importmap-rails'
gem 'httparty'
gem 'fast_jsonapi'
gem 'cancan'
gem 'net-sftp', '~> 4.0'
gem 'whenever', '~> 1.0', require: false  # For cron jobs
gem 'prawn'
gem 'prawn-table'
gem 'devise'
gem 'devise-jwt'
gem 'sassc-rails'
gem 'image_processing', '~> 1.2'
gem 'redis', '~> 5.0'
# gem 'activeadmin_import'  # For Excel imports
gem 'ransack'              # For advanced searching
gem 'kaminari'             # Pagination
gem 'pundit'               # Authorization
gem 'sidekiq'              # Background jobs
gem 'chartkick'            # Charts
gem 'groupdate'            # Time-based grouping
gem 'caxlsx'               # Excel export
gem 'caxlsx_rails'         # Excel views
gem 'active_storage_validations'
gem "sprockets-rails"
#### 
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# # Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
# gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem 'pry-rails'
  gem 'faker'
  gem 'factory_bot_rails'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
