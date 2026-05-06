Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :articles, param: :slug, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      post :publish, to: "articles/publishes#create"
      post :review, to: "articles/reviews#create"
      get :export, to: "articles/exports#create"
      post :translate, to: "articles/translations#create"
      patch :translate, to: "articles/translations#update"
      get :export_translation, to: "articles/translations#export"
    end
    collection do
      post :markdown_preview, to: "articles/markdown_previews#show"
    end
  end

  patch "articles/:slug/review_suggestions/:id", to: "articles/reviews#update_suggestion", as: :article_review_suggestion

  resources :categories, only: [ :index, :create, :destroy ]
  resource :settings, only: [ :edit, :update ]

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
