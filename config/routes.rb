Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :articles, param: :slug, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :publish, to: "articles/publishes#create"
      get :export, to: "articles/exports#create"
    end
    collection do
      post :markdown_preview, to: "articles/markdown_previews#show"
    end
  end

  resources :categories, only: [ :index, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
