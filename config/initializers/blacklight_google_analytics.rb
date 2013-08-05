# Change to your Google Web id 
BlacklightGoogleAnalytics.web_property_id = case Rails.env.to_s
when 'development'
  'UA-16198946-2'
when 'test'
  nil
else
  'UA-16198946-1'
end      
