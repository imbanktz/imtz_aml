# app/controllers/users/registrations_controller.rb

class Users::RegistrationsController < Devise::RegistrationsController
  # You can customize this as needed
  before_action :configure_sign_up_params, only: [:create]
  
  protected
  
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :employee_id, :user_type])
  end
end
