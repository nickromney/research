Rails.application.routes.draw do
  devise_for :users

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Resources
  resources :projects do
    member do
      get :servers
    end
  end

  resources :servers do
    member do
      post :check_services
      post :test_connection
      get :services
    end
    resources :services, only: [:index, :create, :destroy] do
      member do
        post :check_status
      end
    end
  end

  resources :user_groups do
    member do
      post :add_user
      delete :remove_user
    end
  end

  resources :renewals do
    member do
      post :execute
      post :test
    end
  end

  # API endpoints for AJAX requests
  namespace :api do
    namespace :v1 do
      resources :servers, only: [] do
        member do
          get :status
          post :execute_command
        end
      end
      resources :services, only: [] do
        member do
          get :status
        end
      end
    end
  end
end
