Rails.application.routes.draw do
  root 'sessions#new'

  resources :users
  
  get '/login', to: 'sessions#new'
  delete '/sessions', to: 'sessions#destroy', as: :logout_path
  post '/sessions', to: 'sessions#create', as: :login_path

  post '/incoming', to: 'calls#incoming', as: :calls_path
  post '/select_conference', to: 'calls#select_conference'
  post '/authenticate/:id', to: 'calls#authenticate'
  post '/incoming_sms', to: 'calls#incoming_sms'
end
