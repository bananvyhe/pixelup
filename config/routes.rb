Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"

  namespace :api do
    resource :session, only: %i[show create destroy]
    resource :registration, only: :create
    resource :dashboard, only: :show, controller: :dashboard
    resources :payment_transactions, path: "payments", only: %i[create show]

    namespace :admin do
      resources :users, only: %i[index update]
      resources :tariffs, only: %i[index create update destroy]
    end
  end

  resource :session, only: %i[new create destroy]
  resource :dashboard, only: :show, controller: :dashboard
  resources :payment_transactions, path: "payments", only: %i[create show]

  post "payments/yoomoney/notifications", to: "yoo_money_notifications#create", as: :yoo_money_notifications

  namespace :admin do
    resources :tariffs, except: %i[show destroy]
    resources :users, only: %i[index edit update]
  end
end
