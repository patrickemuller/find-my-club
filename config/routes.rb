Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  # Places autocomplete API endpoint
  get "places/autocomplete", to: "places#autocomplete"

  resources :clubs do
    # Membership actions (join/leave)
    resource :membership, only: [ :create, :destroy ]

    # Member management (owner only)
    resources :memberships, only: [] do
      member do
        patch :approve
        patch :enable
        patch :disable
      end
    end

    # Events
    resources :events do
      member do
        get :registrations  # Owner view of all registrations
      end

      resources :event_registrations, only: [ :create, :destroy ] do
        member do
          patch :approve
        end
      end
    end

    # Club management (owner only)
    member do
      patch :enable  # Enable/disable entire club
      patch :disable
      get :members   # Member list view
    end
  end

  get "my-clubs", to: "clubs#my_clubs"

  # User profiles
  resources :users, only: [ :show ], controller: "users/profiles"
end
