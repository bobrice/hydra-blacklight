#deal AD group restriction
#study cas authentication 
require 'nokogiri'
require 'open-uri'
require 'securerandom'
#require 'casclient'
#require 'casclient/frameworks/rails/filter'
class AccessConditionsController < ApplicationController

  include Blacklight::Catalog
  
  #ERJ Cas code
  before_filter CASClient::Frameworks::Rails::Filter , :only => :test_cas
  
  def index 
#http://libserver3.yale.edu:3000/auth?oid=10590515&type=jpg150&ip=130.132.80.210
#http://lbdev.library.yale.edu/xml_accesscondition.aspx?a=s_lib_ladybird&b=E8F3FF02-A65A-4A20-B7B1-A9E35969A0B7&c=10590515'
    oid = params[:oid] || ""
	type = params[:type] || ""
	ip = params[:ip] || ""
	netid = params[:netid] || ""
	
	if oid=="" || type=="" || ip==""
		render :text => "missing parameters - oid:"+oid+" type:"+type+" ip:"+ip
		return
    end  
	base_url = 'http://lbdev.library.yale.edu/xml_accesscondition.aspx?'
	param_a = 'a=s_lib_ladybird'
	param_b = 'b=E8F3FF02-A65A-4A20-B7B1-A9E35969A0B7'
	param_c = 'c=' + oid
	full_url = base_url+param_a+"&"+param_b+"&"+param_c
	logger.info full_url
    doc = Nokogiri::XML(open(full_url))
	rule = doc.xpath("//schema//object//rule[@type='"+type+"']//@code")
	logger.info rule.to_s
	return_msg = "default"
	if rule.to_s == "Yale Only"
		if ip_check(ip) == true
			return_msg = "authorized"
		else
			#if cas netid ok then return_msg = "authorized"
			#elsf no cas netid then return_msg = "try cas"
			#else unauthorized
			if netid.size == 0
				return_msg = "unauthorized"
			else
				return_msg = "authorized"
			end
		end  
	end
	if rule.to_s == "AD Group Restriction"
		group = doc.xpath("//schema//object//rule[@type='"+type+"']//value")
		return_msg = group.to_s	
	end
	#TODO other rules here

	#logger.info "IP:"+ip
	#logger.info ip_check(ip)
    logger.info "Host:"+ request.host_with_port	
	render :text => return_msg
	return
  end
  def test_cas
	#render :text => "You're seeing this because you've passed CAS authentication"
	    #LRR Cas Code
        redirect_to root_path
        #session["mediakey"] = SecureRandom.urlsafe_base64(10) if session["mediakey"] == nil
        #render :text => session.inspect
        
        #render :text => session["mediakey"]
  end
  def logout
    CASClient::Frameworks::Rails::Filter.logout(self)
  end
  def getnetid
    netid = ""
    mediakey = params[:mediakey] || ""
    if mediakey == session["mediakey"]
      netid = session["cas_user"]
    else
      netid = "invalid media key"
    end
    render :text => netid
  end
	#ERJ bug-times out in the rest client
  def test_access
    oid = 10590515
	type = "jpg150"
	ip = request.remote_ip
	host = request.host_with_port
	full_url = "http://"+host+"/auth?oid="+oid.to_s+"&type="+type+"&ip="+ip
	logger.info "auth path:"+full_url
	resource = RestClient::Resource.new(full_url)
	page = resource.get()
	page = page.to_s
	logger.info page
	return_msg = "default"
	if page == "authorized"
		return_msg = "you we able to pass the test access conditions"
	elsif page == "unauthorized"
		return_msg = "try cas"
	else 
		return_msg = "last else condition, this shouldn't happen"
	end	
	render :text => return_msg
	return
  end
 
  private
  def ip_check(client_ip)
    ips = ["130.132", 
            "128.36", 
            "192.31.236", 
            "198.125.138", 
            "192.131.129", 
            "192.152.148", 
            "192.152.149", 
            "192.152.150", 
            "204.60.184", 
            "204.60.185", 
            "204.60.186", 
            "204.60.187", 
            "205.167.18", 
            "205.167.19", 
            "204.90.81", 
            "192.26.88", 
            "192.31.2", 
            "192.35.89",
            "172.22"]
	ips.each do |ip|
		#logger.info "  "+client_ip.start_with?(ip).to_s
		return true if client_ip.start_with?(ip)
	end	
    false
  end
end

#code bag:
#resource = RestClient::Resource.new(full_url)
#page = resource.get(:accept=>'text/xml')
#render :xml => page
#render :xml => doc
#ip = request.remote_ip
