class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  protect_from_forgery

  before_filter :current_user
  def current_user
    if session[:cas_user]
        return User.find_or_create_by_netid(session[:cas_user])
    end
  end
  helper_method :current_user
  
end
