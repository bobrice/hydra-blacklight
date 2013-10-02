class ServicesController < ApplicationController

  
  def caslogout
  	redirect_to 'https://secure.its.yale.edu/cas/logout'
  end


  def login
  	#iscas = params[:provider]
    params[:provider] ? provider = params[:provider] : provider = ''
    
    if request.env["omniauth.auth"] && !provider.blank?
      case provider
      when 'cas'
        user_info = getExtraFromLDAP(request.env["omniauth.auth"].uid)
        user_info['mail'] ? email = user_info['mail'][0] : email = ''
        user_info['uid'] ? uid = user_info['uid'][0] : uid = ''
      end
      
      if uid.present? #If there is a user, in this case from the LDAP server which provides CAS data, find a row in the service table using the provider (which is only cas in our case)
        auth = Service.find_by_provider_and_uid(provider, uid) #SELECT `services`.* FROM `services` WHERE `services`.`provider` = 'cas' AND `services`.`uid` = 'lrr36' LIMIT 1
        if !user_signed_in? #If the user is not signed in with devise, but signed in via CAS
          if auth
            flash[:notice] = 'Signed in successfully via ' + provider.upcase + '. To sign out of CAS, please go to https://secure.its.yale.edu/cas/logout.'
            cas_user = User.find_by_email(auth.email)
            sign_in_and_redirect(cas_user)

          else #If user is not signed in with devise, but the data could not be found from the services table using provider and uid, search using the users email
            if email.present?
              existing_user = User.find_by_email(email)
              if existing_user
                existing_user.services.create(:provider => provider, :uid => uid, :email => email)
                flash[:notice] = 'Sign in via ' + provider.upcase + ' has been added to your account ' + existing_user.email + '. You are now signed in.'
                sign_in_and_redirect(existing_user)
              else
                user = User.new(:email => email, :password => SecureRandom.hex(10))
                user.services.build(:provider => provider, :uid => uid, :email => email)
                user.save!
                flash[:notice] = 'Your account has been created via ' + provider.upcase + '.'
                sign_in_and_redirect(user)
              end
            else
              flash[:error] =  provider.upcase + ' can not be used to sign up, because no valid email address was provided.'
              redirect_to root_path
            end
          end
        else
          if !auth #If no row was returned from the services table and the user is signed in with Devise
            current_user.services.create(:provider => provider, :uid => uid, :email => email)
            flash[:notice] = 'Sign in via ' + provider.upcase + ' has been added to your account.'
            redirect_to root_path
          else #If there was a row returned from the services table and the user is signed in with Devise
            if current_user.services.present? 
              if current_user.services.include? auth
                flash[:notice] = 'This ' + provider.upcase + ' account is already linked to your account.'
              end
            else
              flash[:error] = 'This ' + provider.upcase + ' account is linked to a different account.'
            end
            redirect_to root_path
          end  
        end
      else
        flash[:error] =  provider + ' returned invalid data.'
        redirect_to root_path
      end
    else
      flash[:error] = 'Error while authenticating via ' + provider.upcase + '.'
      redirect_to root_path
    end
  end
  
  protected

  def getExtraFromLDAP(netid)
    begin
      require 'net/ldap'
      ldap = Net::LDAP.new( :host =>"directory.yale.edu" , :port =>"389" )
      f = Net::LDAP::Filter.eq('uid', netid)
      b = 'ou=People,o=yale.edu'
      p = ldap.search(:base => b, :filter => f, :return_result => true).first
    rescue Exception => e
      return
    end
    return p
  end
end
