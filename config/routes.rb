Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :admin do
    authenticate :user, ->(user) { user.admin? } do
      mount MissionControl::Jobs::Engine, at: "/jobs"
    end
  end

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

  # Stripe Connect (callback)
  get "/callbacks/stripe", to: "clubs/stripe_accounts#callback", as: :callbacks_stripe

  # Stripe webhooks
  post "/webhooks/stripe", to: "webhooks/stripe#create"

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

    # Invitations (owner only)
    resources :club_invitations, only: [ :create, :destroy ], path: "invitations" do
      member do
        post :resend
      end
    end

    # Stripe connect endpoints
    resource :stripe_account,
             controller: "clubs/stripe_accounts",
             only: [ :new, :create, :show, :destroy ],
             path: :payments,
             as: :payments

    # Subscription Plans (owner only)
    resources :subscription_plans, controller: "clubs/subscription_plans", only: [ :new, :create, :edit, :update ]

    # Checkout (members) - for paid memberships
    get "checkout", to: "clubs/stripe_accounts#checkout", as: :checkout
    post "checkout", to: "clubs/stripe_accounts#create_checkout_session"
    get "checkout/success", to: "clubs/stripe_accounts#success", as: :checkout_success

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

  # Invitation acceptance routes (no auth required)
  get "/invitations/:token/accept", to: "club_invitations#accept", as: :accept_club_invitation
  post "/invitations/:token/reject", to: "club_invitations#reject", as: :reject_club_invitation

  # Member payments
  resources :payments, only: [ :index, :show ]

  # Subscription management
  resources :subscriptions, only: [ :show ] do
    member do
      post :cancel
      post :resume
    end
  end

  # User profiles
  resources :users, only: [ :show ], controller: "users/profiles" do
    collection do
      get :subscriptions, to: "users/subscriptions#index"
    end
  end
end
