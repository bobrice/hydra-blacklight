#http://viget.com/extend/protip-passing-parameters-to-your-rake-tasks
#https://github.com/projecthydra/active_fedora/wiki/Getting-Started:-Console-Tour
#rack security update

#todo 3/12/13 - compound to complex bug, create simple and child models, fill in Active fedora
require Rails.root.join('config/environment.rb')
namespace :yulhy2 do
  desc "ingest from ladybird"
  task :ingest do
    puts "Running ladybird ingest"
    puts Time.now
	puts "requirement: root of share must be 'ladybird'"

	lbconf = YAML.load_file ('config/ladybird_test.yml')
	lbuser = lbconf.fetch("username").strip
	lbpw = lbconf.fetch("password").strip
	lbhost = lbconf.fetch("host").strip
	lbdb = lbconf.fetch("database").strip
	puts "using db:"+lbdb
	@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client2 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client3 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client4 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client5 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client6 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)

    puts "client1 connection to db OK? #{@@client.active?}"
    if @@client.active? == false
      abort("TASK ABORTED: client1 could not connect to db")
    end

    puts "client2 connection to db OK? #{@@client2.active?}"
    if @@client2.active? == false
      abort("TASK ABORTED: client2 could not connect to db")
    end

    puts "client3 connection to db OK? #{@@client3.active?}"
    if @@client3.active? == false
      abort("TASK ABORTED: client3 could not connect to db")
    end

    puts "client4 connection to db OK? #{@@client4.active?}"
    if @@client4.active? == false
      abort("TASK ABORTED: client4 could not connect to db")
    end

    puts "client5 connection to db OK? #{@@client5.active?}"
    if @@client5.active? == false
      abort("TASK ABORTED: client5 could not connect to db")
    end
	
    puts "client6 connection to db OK? #{@@client6.active?}"
    if @@client6.active? == false
      abort("TASK ABORTED: client6 could not connect to db")
    end
	@mountroot = "/home/ermadmix/libshare/"
	puts "batch mounted as " + @mountroot
	@tempdir = "/home/ermadmix/"
	puts "temp directory" + @tempdir
	@blacklight_solr_config = Blacklight.solr_config
	puts "solr host:" + @blacklight_solr_config.inspect
	@cnt=0
    processoids()
    @@client.close
	@@client2.close
	@@client3.close
	@@client4.close
	@@client5.close
	@@client6.close
    puts Time.now
  end

  def processoids()
	@cnt += 1
	puts @cnt
    #result = @@client.execute("select top 1 hpid,oid,cid,pid,contentModel,_oid,zindex from dbo.hydra_publish where dateHydraStart is null and dateReady is not null and _oid=0 order by dateReady")
	result = @@client.execute("select top 1 a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid from dbo.hydra_publish a, dbo.hydra_content_model b where a.dateHydraStart is null and a.dateReady is not null and a._oid=0 and a.hcmid is not null and a.hcmid=b.hcmid and a.action='insert' order by a.dateReady")
    result.fields.to_s
	if result.affected_rows == 0
      @@client.close
	  @@client2.close
	  @@client3.close
	  @@client4.close
	  @@client5.close
	  @@client6.close
      puts Time.now
      abort("finished, no more baghydra rows to process")
    else 
      result.each(:first=>true) do |i|
        begin	  
          processparentoid(i)
        rescue Exception => msg
          processerror(i,msg)
        end		  
      end
	  if @cnt > 1000
	    @@client.close
	    @@client2.close
		@@client3.close
		@@client4.close
		@@client5.close
		@@client6.close
	    puts Time.now
	    abort("prevent infinite loop")
	  end	  
      processoids()
    end
  end
  
  def processparentoid(i)
	puts "processing top level oid: #{i}"  
	update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#
	runningErrorStr = ""
	obj = nil
	contentModel = i["contentModel"]
	if contentModel == "simple"
      obj = Simple.new 
	elsif contentModel == "complexParent"
	  obj = ComplexParent.new  
	elsif contentModel == "complexChild" #this won't happen in processparentoid
	  obj = ComplexChild.new 
	else
      erromsg =  "Error, contentModel #{contentModel} not handled"
	  processmsg(i,errormsg)
	  return
	end
	obj.label = ("oid: #{i["oid"]}")
	begin
	datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/) 
	datastreams.each do |datastream|
	  dsid = datastream["dsid"].strip
	  ingestMethod = datastream["ingestMethod"].strip
	  required = datastream["required"].strip
	  ds = @@client2.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
	  if required == 'y'
	    if ds.affected_rows == 0
		  runningErrorStr.concat(" missing required datastream #{dsid}")
		  next
		end
      end		
	  ds.each(:first=>true) do |ds1|
	    type = ds1["type"].strip
	    md5 = ds1["md5"].strip
        pathUNC = ds1["pathUNC"].strip
	    pathHTTP = ds1["pathHTTP"].strip
        controlGroup = ds1["controlGroup"].strip
        mimeType = ds1["mimeType"].strip
        dsid1 = ds1["dsid"].strip
	    if ingestMethod == 'pullHTTP'
		  file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
          ff = File.new(file)
          obj.add_file_datastream(ff,:controlGroup=>controlGroup,:mimeType=>mimeType,:dsid=>dsid1)
          File.delete(file)
		elsif ingestMethod == 'filepath'
		  realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
	      #puts "path: #{realpath}"
		  if File.new(realpath).size == 0
            ds.cancel		  
			runningErrorStr.concat(" file #{realpath} empty")
		    break
		  end  
	      digest = Digest::MD5.hexdigest(File.read(realpath))
		  #puts "digest #{digest}"
	      if digest != md5
	        ds.cancel
			runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		    break
            return
          end
		  file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5') 
		end
	  end
	end  
	#
	rescue Exception => msg
      processerror(i,msg)
	end
    if runningErrorStr.size > 0
	  processmsg(i,runningErrorStr)
	  return
	end
	begin
    obj.oid = i["oid"]
	obj.cid = i["cid"]
	obj.projid = i["pid"]
	obj.zindex = i["zindex"]
	obj.parentoid = i["_oid"]
	collection_pid = get_coll_pid(i["cid"],i["pid"])
	if collection_pid.size==0
	  processmsg(i,"collection pid not found")
	  return
	end  
	collection_pid_uri = "info:fedora/#{collection_pid}"
	obj.add_relationship(:is_member_of,collection_pid_uri)
	if contentModel == "complexParent"
	  result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
	  result.each do |i|
	    obj.ztotal =  i["total"]
	  end
	end  
	  obj.save
	rescue Exception => msg
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg)
	  return
    end
	puts "PID #{obj.pid} sucessfully created for #{i["oid"]}"	
	update = @@client5.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	process_children(i,obj.pid)
  end

  #ERJ error routine for exceptions 
  def processerror(i,errormsg)
    linenum = errormsg.backtrace[0].split(':')[1]
	dberror = "[#{linenum}] #{errormsg}"
    puts "error for oid: #{i["oid"]} errormsg: #{dberror}"
	puts "ERROR:" + errormsg.backtrace.to_s
	puts "STACK:" + errormsg.backtrace.to_s
	ehid = @@client4.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},"#{dberror}")/)
	ehid.insert
  end
  #ERJ error routine for message driven errors (no exceptions) 
  def processmsg(i,errormsg)
    puts "error for oid: #{i["oid"]} errormsg: #{errormsg}"
	ehid = @@client4.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},"#{errormsg}")/)
	ehid.insert
  end
  
  def process_children(i,ppid)
    puts "process_children for #{ppid}"
	#ERJ note using client2 for children iteration
    #result = @@client2.execute("select hpid,oid,cid,pid,contentModel,_oid,zindex from dbo.hydra_publish where dateHydraStart is null and _oid=#{i["oid"]} order by date")
	result = @@client3.execute("select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.zindex from dbo.hydra_publish a,dbo.hydra_content_model b where a.dateHydraStart is null and a._oid=#{i["oid"]} and a.hcmid=b.hcmid and a.action='insert' order by a.date")
    result.each { |j|
      begin 	
	    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{j["hpid"]}/)
        update.do
		#if j["oid"] == 10590509
          process_child(j,ppid)
		#else
	    #  puts %Q/bypass processing child #{j["hpid"]} #{j["oid"]}/ 
        #end			
	    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{j["hpid"]}/)
	    update.do
	  rescue Exception => msg
	    unless update.nil? 
		  update.cancel
		end
	    unless result.nil?
		  result.cancel
		end
	    processerror(i,msg)
	    return#for testing
	  end
    }  
  end
  
    def process_child(i,ppid)
	puts "processing child oid: #{i}"  
	update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#
	runningErrorStr = ""
	obj = nil
	contentModel = i["contentModel"]
	if contentModel == "complexChild"
	  obj = ComplexChild.new #this won't happen ,WHY not?
	else
      erromsg =  "Error, contentModel #{contentModel} not handled"
	  processmsg(i,errormsg)
	  return
	end
	obj.label = ("oid: #{i["oid"]}")
	begin
	datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/) 
	datastreams.each do |datastream|
	  dsid = datastream["dsid"].strip
	  ingestMethod = datastream["ingestMethod"].strip
	  required = datastream["required"].strip
	  ds = @@client6.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
	  if required == 'y'
	    if ds.affected_rows == 0
		  runningErrorStr.concat(" missing required datastream #{dsid}")
		  next
		end
      end		
	  ds.each(:first=>true) do |ds1|
	    type = ds1["type"].strip
	    md5 = ds1["md5"].strip
        pathUNC = ds1["pathUNC"].strip
	    pathHTTP = ds1["pathHTTP"].strip
        controlGroup = ds1["controlGroup"].strip
        mimeType = ds1["mimeType"].strip
        dsid1 = ds1["dsid"].strip
	    if ingestMethod == 'pullHTTP'
		  file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
          ff = File.new(file)
          obj.add_file_datastream(ff,:controlGroup=>controlGroup,:mimeType=>mimeType,:dsid=>dsid1)
          File.delete(file)
		elsif ingestMethod == 'filepath'
		  realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
	      #puts "path: #{realpath}"
		  if File.new(realpath).size == 0
            ds.cancel		  
			runningErrorStr.concat(" file #{realpath} empty")
		    break
		  end  
	      digest = Digest::MD5.hexdigest(File.read(realpath))
		  #puts "digest #{digest}"
	      if digest != md5
	        ds.cancel
			runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		    break
            return
          end
		  file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5') 
		end
	  end
	end  
	#
	rescue Exception => msg
      processerror(i,msg)
	end
    if runningErrorStr.size > 0
	  processmsg(i,runningErrorStr)
	  return
	end
	begin
    obj.oid = i["oid"]
	obj.cid = i["cid"]
	obj.projid = i["pid"]
	obj.zindex = i["zindex"]
	obj.parentoid = i["_oid"]
	pid_uri = "info:fedora/#{ppid}"
	obj.add_relationship(:is_member_of,pid_uri)
	result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
	result.each do |i|
	  obj.ztotal =  i["total"]
	end
	obj.save
	rescue Exception => msg
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg)
	  return
    end
	puts "PID #{obj.pid} sucessfully created for #{i["oid"]}"	
	update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#process_children(i,obj.pid)#ERJ process a child's child here
  end
  
  def get_coll_pid(cid,pid) 
    query = "cid_i:"+cid.to_s+" && projid_i:"+pid.to_s+" && active_fedora_model_s:Collection"
	#puts "Q:"+query
    blacklight_solr = RSolr.connect(@blacklight_solr_config)
	#puts "B:"+blacklight_solr.inspect
    response = blacklight_solr.get("select",:params=> {:fq => query,:fl =>"id"})
	#puts "R:"+response
	puts "No Collection found for cid:"+cid.to_s+" pid:"+pid.to_s if response["response"]["numFound"] == 0 
    id = response["response"]["docs"][0]["id"]
    id
  end

end