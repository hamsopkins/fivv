Rails.application.routes.draw do
  root 'sessions#new'

  resources :users
  
  get '/login', to: 'sessions#new'
  delete '/sessions', to: 'sessions#destroy', as: :logout_path
  post '/sessions', to: 'sessions#create', as: :login_path
end
