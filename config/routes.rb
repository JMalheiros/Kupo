Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :articles, param: :slug, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      post :publish
    end
    collection do
      post :preview
    end
  end

  resources :categories, only: [ :index, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
