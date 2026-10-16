Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  root "dashboard#show"

  # Onboarding: namn och språk, sedan en intervju i chatten
  resource :onboarding, only: :show, controller: "onboarding" do
    post :start
    post :message
    post :finish
  end

  # Livsområden: /areas/health, /areas/mind …
  resources :areas, only: %i[index show update]

  # Skolor och ramverk – användaren väljer vad som resonerar
  resources :approaches, only: :index do
    put :choice, on: :member
  end

  resources :entries, only: %i[index create destroy]
  resources :measurements, only: %i[index show create destroy]
  resources :documents, only: %i[index new create show destroy] do
    post :reanalyze, on: :member
  end
  resources :check_ins, only: %i[index new create show edit update]
  resources :experiments, except: :show
  resources :memories, only: %i[index create update destroy]
  resources :insights, only: %i[index update] do
    post :generate, on: :collection
  end

  get "coach", to: "conversations#index", as: :coach
  resources :conversations, only: %i[show create destroy] do
    resources :messages, only: :create
  end

  resource :settings, only: %i[show update]
  get "style_guide", to: "style_guide#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
