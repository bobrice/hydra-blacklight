class CasController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter, :only => :login
  def login
    if !current_user.nil?
      flash[:notice] = "Welcome, " + current_user.netid + '! Login was successful.'
      redirect_to root_path
    end
  end

  def logout
    reset_session
    CASClient::Frameworks::Rails::Filter.logout(self)
  end
end
