Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config.merge(skip: [:confirmations, :registrations, :unlocks])
  # devise_for :users, skip: [:registrations]
  ActiveAdmin.routes(self)
  # Health check endpoint (for Docker/Kubernetes)
  get "/health", to: proc { [200, {}, ["OK"]] } # Simple health check
  root to: "admin/dashboard#index"
  
end 
