Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if it boots without exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :public_services, only: %i[index show], param: :slug
  resources :cases, only: %i[new create show] do
    resources :observations, only: %i[new create], controller: "case_observations"
    resources :case_actions, only: %i[new create show update]

    resource :assistant, only: [] do
      post :explain_case
      post :explain_discrepancy
      post :explain_action
      post :refine_draft
    end
  end

  resource :assistant, only: [] do
    post :ask
  end

  root "public_services#index"
end
