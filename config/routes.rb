Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'upload#index'

  post 'import', to: 'upload#import'

  post 'file_parity', to: 'upload#file_parity'
end
