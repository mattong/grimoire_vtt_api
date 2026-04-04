Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  devise_for :users, path: "", path_names: {
    sign_in: "api/auth/login",
    sign_out: "api/auth/logout"
  },
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  },
  skip: [:registrations]

  devise_scope :user do
    post "api/auth/signup", to: "users/registrations#create"
  end


  namespace :api do
    resources :games do
      resources :resource_templates
    end
  end
end
