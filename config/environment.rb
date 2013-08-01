#ENV['RAILS_ENV'] = 'test'
# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
DiggitHydra::Application.initialize!

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => "https://securedev.its.yale.edu/cas/",
  :username_session_key => :cas_user,
  :extra_attributes_session_key => :cas_extra_attributes
)

