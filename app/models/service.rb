class Service < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks. 
 include Blacklight::User
  # attr_accessible :title, :body
  attr_accessible :email, :provider, :uid, :user_id
  belongs_to :user
end
