
Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config.merge(skip: [:confirmations, :registrations, :unlocks])
  ActiveAdmin.routes(self)
  # Health check endpoint (for Docker/Kubernetes)
  get "/health", to: proc { [200, {}, ["OK"]] } # Simple health check
  root to: "admin/dashboard#index"

  match 'api/v1/transaction_screening', to: 'api/v1/transaction_screening#txn_screen', via: 'post'
  match 'api/v1/tz_callback', to: 'api/v1/transaction_screening#tz_callback', via: 'post'

  get 'api/v1/screening/test', to: 'api/v1/screening#test_screening'
  post 'api/v1/screening/rtgs', to: 'api/v1/screening#test_rtgs'
  post 'api/v1/rtgs/process_sync', to: 'api/v1/rtgs#process_sync' # sync 
  post 'api/v1/rtgs/process_async', to: 'api/v1/rtgs#process_async' # async

  get 'api/v1/rtgs/status/:id', to: 'api/v1/rtgs#status', as: 'rtgs_status'
  post 'api/v1/rtgs/reprocess/:id', to: 'api/v1/rtgs#reprocess', as: 'rtgs_reprocess'
  

  namespace :api do
    namespace :v1 do
      resources :transaction_screening
      resources :screening
      resources :rtgs
      # resources :customer_screening
    end
  end
end 
