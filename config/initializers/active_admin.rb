ActiveAdmin.setup do |config|
  config.site_title = "Fleet Management System"
  config.authentication_method = :authenticate_user!
  config.current_user_method = :current_user
  config.logout_link_path = :destroy_user_session_path
  config.comments = false
  config.batch_actions = true
  config.filter_attributes = [:encrypted_password, :password, :password_confirmation]
  config.localize_format = :long
  config.register_javascript 'https://www.gstatic.com/charts/loader.js'
  config.register_javascript 'https://cdn.jsdelivr.net/npm/chartkick'
  
end
