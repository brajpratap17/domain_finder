Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'domains/new', to: 'domains#new', as: :new_domain
  post 'domains/check', to: 'domains#check', as: :check_domains
end
