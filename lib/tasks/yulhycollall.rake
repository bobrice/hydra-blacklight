#bundle exec rake yulhy:add_all_collections
require Rails.root.join('config/environment.rb')
namespace :yulhy do
  desc "add all collections from pamoja projects table"
  task :add_all_collections do
    lbconf = YAML.load_file ('config/ladybird.yml')
	lbuser = lbconf.fetch("username").strip
	lbpw = lbconf.fetch("password").strip
	lbhost = lbconf.fetch("host").strip
	lbdb = lbconf.fetch("database").strip
	puts "using db:"+lbdb
	@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	
    puts "client connection to db OK? #{@@client.active?}"
    if @@client.active? == false
      abort("TASK ABORTED: client1 could not connect to db")
    end
	rows = Array.new
	sqlstmt = %Q/select cid,pid,label from dbo.project order by pid/
	result = @@client.execute(sqlstmt)
	result.each do |i|
	    row = Array.new
		row.push i["cid"]
		row.push i["pid"]
		row.push i["label"]
		rows.push row
	end
	#puts "size:" + rows.size.to_s
	rows.each do |i| 
	    puts "--------------"
		exists = get_coll_pid(i[0],i[1])
		puts "  cid: #{i[0]}"
		puts "  pid: #{i[1]}"
		puts "  label: #{i[2]}"
		if exists == "true"
		  puts "  Not ingesting, already exists"
		elsif exists == "false"
          puts "  Creating new object"
		  obj = Collection.new
		  obj.label = i[2]
	      obj.cid = i[0]
          obj.projid = i[1] 
          obj.title = i[2]
	      obj.save
          puts "Created pid: "+ obj.pid
		end  
	end
	@@client.close
  end
  private
  def get_coll_pid(cid,pid)
    exists = ""
    query = "cid_isi:"+cid.to_s+" && projid_isi:"+pid.to_s+" && active_fedora_model_s:Collection"
    blacklight_solr_config = Blacklight.solr_config
    #puts query
    #puts blacklight_solr_config
    blacklight_solr = RSolr.connect(blacklight_solr_config)
    puts blacklight_solr.inspect
    response = blacklight_solr.get("select",:params=> {:fq => query,:fl =>"id"})
    #@solr_response = Blacklight::SolrResponse.new(force_to_utf8(response),{:fq => query,:fl => "id"})
    #puts "R:"+response["response"].inspect
	if response["response"]["numFound"] == 0
      #puts "No Collection found for cid:"+cid.to_s+" pid:"+pid.to_s
	  exists = "false"
	else 
	  #puts "A Collection found for cid:"+cid.to_s+" pid:"+pid.to_s"
	  exists = "true"
	end
    #puts "S:"+response["response"]["numFound"]
    #id = response["response"]["docs"][0]["id"]
    exists
  end	  
end