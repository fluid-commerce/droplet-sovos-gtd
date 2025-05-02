Rails.application.routes.draw do
  root "home#index"

  devise_for :users

  post "webhook", to: "webhooks#create", as: :webhook

  get "embed", to: "embeds#index", as: :embed

  post "sovos/update_settings", to: "sovos#update_settings", as: :sovos_update_settings
  post "sovos/calculate_tax", to: "sovos#calculate_tax", as: :sovos_calculate_tax

  namespace :admin do
    get "dashboard/index"
    resource :droplet, only: %i[ create update ]
    resources :settings, only: %i[ index edit update ]
    resources :users
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
