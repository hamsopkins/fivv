Rails.application.routes.draw do
  root 'sessions#new'

  resources :users, only: [:show, :new, :create, :edit, :update]
  resources :contacts, :conferences
  
  get '/login', to: 'sessions#new', as: :login_form_path
  delete '/sessions', to: 'sessions#destroy', as: :logout_path
  post '/sessions', to: 'sessions#create', as: :login_path
  get '/success', to: 'users#success', as: :success_path

  post '/incoming', to: 'calls#incoming', as: :calls_path
  post '/select_conference', to: 'calls#select_conference'
  post '/authenticate/:id', to: 'calls#authenticate'
  post '/incoming_sms', to: 'calls#incoming_sms'
  post '/callback', to: 'calls#callback'
  get '/expired', to: 'sessions#account_expired', as: :account_expired
  get '/forgot_password', to: 'sessions#forgot_password', as: :forgot_password_path
  post '/generate_token', to: 'sessions#generate_token', as: :generate_token_path
  get '/reset_password', to: 'sessions#reset_password_form', as: :reset_password_form_path
  post '/reset_password', to: 'sessions#reset_password', as: :reset_password_path
  post '/client_join', to: 'calls#client_join'
end
