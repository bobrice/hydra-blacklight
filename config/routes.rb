DiggitHydra::Application.routes.draw do
  root :to => "catalog#index"

  match 'users/auth/:provider/callback' => 'services#login'
  #match 'users/signout', :controller => 'services', :action => 'caslogout'

  match '/pagination', :controller => 'pagination', :action => 'index'
  match '/pagination/numofpages', :controller => 'pagination', :action => 'numofpages'
  match '/pagination/turndirection', :controller =>'pagination', :action => 'turndirection'
  match '/pagination/transcript', :controller => 'pagination', :action => 'transcript'
  match '/pagination/title', :controller => 'pagination', :action => 'gettitle'
  match '/pagination/getparentpid', :controller => 'pagination', :action => 'getparentpid'
  match '/pagination/getrailsenv', :controller => 'pagination', :action => 'getrailsenv'

  match '/auth', :controller => 'access_conditions', :action => 'index'
  match '/authtest', :controller => 'access_conditions', :action => 'test_access'
  match '/testcas', :controller => 'access_conditions', :action => 'test_cas'
  match '/logout', :controller => 'access_conditions', :action => 'logout'
  match '/getnetid', :controller => 'access_conditions', :action => 'getnetid'

  match '/catalog/email', :controller => "catalog", :action => 'email'


  Blacklight.add_routes(self)
  HydraHead.add_routes(self)

  devise_for :users

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
