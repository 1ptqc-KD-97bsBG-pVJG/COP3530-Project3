Rails.application.routes.draw do
  get 'temperature_records/search'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  get 'search', to: 'temperature_records#search'
end
