Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  # Defines the root path route ("/")
  # root "posts#index"
end


Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      # JWT/JWKS (if you want auth around these)
      # get  :jwks, to: 'jwks#show'              # => { keys: [...] }
      # namespace :admin do
      #   resources :tokens, only: [:create]     # POST /api/v1/admin/tokens
      # end

      resources :campaigns, only: [:index, :show, :create, :update, :destroy]
      resources :leads,     only: [:index, :show, :create, :update, :destroy] do
        member do
          put :promote
          put :reject
        end
      end
      resources :contacts,  only: [:index, :show, :create, :update, :destroy]
      resources :opportunities, only: [:index, :show, :create, :update, :destroy]
    end
  end

  root to: proc { [200, { 'Content-Type' => 'application/json' }, [ { status: 'ok' }.to_json ]] }
end