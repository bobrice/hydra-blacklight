require Rails.root.join('config/environment.rb')
RAILS_ROOT = Rails.root
Rails.logger = Logger.new("#{RAILS_ROOT}/log/ingest.log",10,200.megabytes)
Rails.logger.formatter = Logger::Formatter.new
namespace :yulhy7 do
  desc "ingest from ladybird"
  task :ingest do
    logger.info("START: Running ladybird ingest")
	@start = Time.now
    logger.info("Start Time:"+@start.to_s)
	logger.info("requirement: root of share must be 'ladybird'")

	#configuration of ladybird sqlserver database
	lbconf = YAML.load_file ('config/ladybird_test.yml')
	lbuser = lbconf.fetch("username").strip
	lbpw = lbconf.fetch("password").strip
	lbhost = lbconf.fetch("host").strip
	lbdb = lbconf.fetch("database").strip
	logger.info("user:"+lbuser)
	logger.info("pw:"+lbpw)
	logger.info("lbhost:"+lbhost)
	logger.info("db:"+lbdb)
	#create 2 connections
	@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client2 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	#check connections
    logger.info("client1 connection to db OK? #{@@client.active?}")
    if @@client.active? == false
      abort("TASK ABORTED: client1 could not connect to db")
    end
    logger.info("client2 connection to db OK? #{@@client2.active?}")
    if @@client2.active? == false
      abort("TASK ABORTED: client2 could not connect to db")
    end

	@mountroot = "/usr/local/libshare/"
	logger.info("batch mounted as: " + @mountroot)
	@tempdir = "/home/blacklight/"
	logger.info("temp directory: " + @tempdir)
	#output of region (development,test, or production)
	logger.info("Region: " + Rails.env)
	#solr host
	@blacklight_solr_config = Blacklight.solr_config
	logger.info("solr host:" + @blacklight_solr_config.inspect)
	#fedora host
	fedoraconf = YAML.load_file('config/fedora.yml')
	region = fedoraconf.fetch(Rails.env)
	@server = region.fetch("url")
	logger.info("fedora host: "+@server)
	
	#check if any rows to process
	result = @@client.execute(queue_query)
 
    logger.info(queue_query)
    result.each
	rows = result.affected_rows
	result.fields.to_s
	logger.info("number of rows to process in hydra publish table:"+rows.to_s)
	if rows == 0
	  result.cancel
      @@client.close
	  @@client2.close
	  abort("no rows to process upfront");
	end
	result.cancel
	
	#if script reaches here, there ARE rows to process, send email that ingest has started
	@email_list = ["eric.james@yale.edu","lakeisha.robinson@yale.edu","michael.friscia@yale.edu","kalee.sprague@yale.edu","robert.rice@yale.edu", "gail.barnett@yale.edu", "stefano.disorbo@yale.edu"]
    @subject = "Ingest Started"
	@message = "Ingest Started at #{@start}"
	mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
	mail.deliver
	
	#main processing loop
	@cnt=0
	@error_cnt = 0
	@abort_var = false
	while rows > 0
	  logger.info("Inside Loop to process rows. Number of rows to process in hydra publish table:"+rows.to_s)
	  result = @@client.execute(queue_query)
      result.fields.to_s 

	  #get first result row, put rowinto in array, and send to procesqueue()
	  resultArr = Array.new	
      result.each(:first=>true) do |i|
        resultArr.push(i)  
      end

      rows = result.affected_rows
	  logger.info("rows to process before:"+rows.to_s)
	  logger.info("size of resultArr: " + resultArr.size.to_s)

	  result.cancel

	  resultArr.each do |i|
	  	counter_check
        begin
          processqueue(i)
        rescue Exception => msg
          processerror(i,msg,"")
        end

        # Production: set @cnt to an infinitely high value. Dev and Test: set @cnt low as needed for testing purposes
        if @cnt == 10000000
	      @@client.close
	      @@client2.close
	      logger.info("Count exceeded "+@cnt.to_s+" at "+Time.now.to_s)
	      abort("Forced abort at @cnt limit")	  
        end
	    rows -= 1
	  end
	end
	
	#if script reaches here there are no more rows to process, close connections, send email,and abort 
    @@client.close
	@@client2.close
    logger.info("DONE")
	@finish = Time.now
    logger.info("End Time:"+@finish.to_s)
	@elapse = @finish - @start
	logger.info("Elapsed Time:"+@elapse.to_s)
	@subject = "Ingest Complete"
	@message = "Ingest Started at #{@start}   Ingest Completed at #{@finish}    Count #{@cnt}  "
	mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
	mail.deliver
	abort("DONE, no more baghydra rows to process")	
  end

  def counter_check
    #code to pause ingest if too many errors occur, tweak error_cnt and sleep time as appropriate
	logger.info("counter_check count:"+@cnt.to_s)

    if @error_cnt > 100
	  logger.info("More than 100 errors per 1000, stopping for 1 hour(s).")
	  puts("More than 100 errors per 1000, stopping for 1 hour(s).")
	  
	  #too many errors occurred
	  @subject = "Ingest Suspended"
	  susTime = Time.now
	  @message = "Ingest Suspended for 2 hours to do errors at #{susTime}"
	  mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
	  mail.deliver
	  @error_cnt = 0
	  sleep(1.hours)
	end	   

    if @cnt%1000==0
	   logger.info("resetting runaway stopper")
       @error_cnt = 0
    end	
  end
  
  def processqueue(i)
	logger.info("processing queue oid: #{i}")  
	update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE(),attempts=(select attempts+1 from hydra_publish where hpid=#{i["hpid"]}),server='#{@server}' where hpid=#{i["hpid"]}/)
	update.do
	#
	action = i["action"]
	if action == "delete"
	  deleteoid(i)
	elsif action == "undel"
      undeleteoid(i)	
	elsif action == "update"
      updateoid(i)	
	elsif action == "ichild"
      insertchild(i)	  
	elsif action == "insert"
	  processtopleveloid(i)
	else
      errormsg = "Error, action #{action} not handled"
      processmsg(i,errormsg,"")	  
	  return
	end
  end
  
  def deleteoid(i)
    hydraID = i["hydraID"]
	@cnt += 1
	logger.info("oid count:"+@cnt.to_s)
    logger.info("starting deleteoid for #{hydraID}")
	begin	
	  obj = ActiveFedora::Base.find(hydraID,:cast=>true)
	  obj.inner_object.state = 'D'
	  obj.save
	  
	  logger.info("PID #{obj.pid} sucessfully inactivated for #{i["oid"]}")	
	  update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	  update.do
	rescue Exception => msg
      processerror(i,msg,hydraID)
	end  
  end
  
  def undeleteoid(i)
    hydraID = i["hydraID"]
	@cnt += 1
	logger.info("oid count:"+@cnt.to_s)
    logger.info("starting undeleteoid for #{hydraID}")
	begin
	  obj = ActiveFedora::Base.find(hydraID,:cast=>true)
	  obj.inner_object.state = 'A'
	  obj.save
	  
	  logger.info("PID #{obj.pid} sucessfully activated for #{i["oid"]}")	
	  update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	  update.do
	rescue Exception => msg
      processerror(i,msg,hydraID)
	end  
  end
  
  def updateoid(i)
    hydraID = i["hydraID"]
	contentModel = i["contentModel"]
	@cnt += 1
	logger.info("oid count:"+@cnt.to_s)
    logger.info("starting updateoid for #{hydraID}")
    runningErrorStr = ""
	obj = nil
	begin
	  obj = ActiveFedora::Base.find(hydraID,:cast=>true)
	  ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid,ingestMethod,OIDpointer from dbo.hydra_publish_path where hpid=#{i["hpid"]}/)
	  
	  dsArr = Array.new
	  ds.each do |ds1|
	    dsArr.push(ds1)
	  end
	  		
	  dsArr.each do |ds1|
		type = ds1["type"].nil? ? "" : ds1["type"].strip
	    md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
        pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
	    pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
        controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
        mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
        dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
		ingestMethod = ds1["ingestMethod"].nil? ? "" : ds1["ingestMethod"].strip
		oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip 
	    if ingestMethod == 'pullHTTP'
		  file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
          ff = File.new(file)
		  ng_xml = Nokogiri::XML::Document.parse(IO.read(ff))
		  if dsid1 == 'descMetadata' 
		    obj.descMetadata.ng_xml = ng_xml
		  elsif dsid1 == 'accessMetadata' 
		    obj.accessMetadata.ng_xml = ng_xml
		  elsif dsid1 == 'rightsMetadata' 
		    obj.rightsMetadata.ng_xml = ng_xml
		  end	
          File.delete(file)
		elsif ingestMethod == 'filepath'
		  realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
		  if File.new(realpath).size == 0
            ds.cancel		  
			runningErrorStr.concat(" file #{realpath} empty")
		    break
		  end  
		  digest = Digest::MD5.file(realpath).hexdigest
	      if digest != md5
	        ds.cancel
			runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		    break
            return
          end
		  file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
        elsif ingestMethod == 'pointer'
          obj.oidpointer = oidPointer		
		end
	  end
	  if runningErrorStr.size > 0
	    objpid = obj.nil? ? "" : obj.pid
	    processmsg(i,runningErrorStr,objpid)
	    return
	  end
      obj.oid = i["oid"].to_s
	  obj.cid = i["cid"].to_s
	  obj.projid = i["pid"].to_s
	  obj.zindex = i["zindex"].to_s
	  obj.parentoid = i["_oid"].to_s
	  #NOTE: no hierarchy changing functionality in updateoid 
	  if contentModel == "complexParent"
	    resultArr = Array.new 
	    result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
	    result.each(:first=>true) do |i|
	      resultArr.push(i)
	    end
	    resultArr.each do |i|
	      obj.ztotal =  i["total"].to_s
	    end
	  end  
	  #obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error 
	  obj.save
	rescue Exception => msg
	  objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while updating #{objpid}")
	  #cleanup database
	  logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["hpid"]}/) 
	  update = @@client.execute(%Q/update hydra_publish set dateHydraStart = null,dateHydraEnd = null where hpid = #{i["hpid"]}/)
	  update.do
      processerror(i,msg,objpid)
	  return
    end
	begin
	  logger.info("PID #{obj.pid} sucessfully updated for #{i["oid"]}")	
	  update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	  update.do	  
	  rescue Exception => msg
        processerror(i,msg,hydraID)
	  end
  end

  def insertchild(i)
    @cnt += 1
	logger.info("oid count:"+@cnt.to_s)
    logger.info(%Q/starting insertchild for #{i["oid"]}/)
	runningErrorStr = ""
	obj = nil
	begin
	  contentModel = i["contentModel"]
	  if contentModel == "complexChild"
	    obj = ComplexChild.new 
	  else
        erromsg = "Error, contentModel #{contentModel} not handled in insert child"
		objpid = obj.nil? ? "" : obj.pid
	    processmsg(i,errormsg,objpid)
	    return
	  end
	  
      obj.label = ("oid: #{i["oid"]}")
	  datastreamsArr = Array.new
	  datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/)
      datastreams.each do |datastream|
        datastreamsArr.push(datastream)
	  end  
	  datastreamsArr.each do |datastream|
	    dsid = datastream["dsid"].strip
	    ingestMethod = datastream["ingestMethod"].strip
	    required = datastream["required"].strip
	    dsArr = Array.new
		
	    ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid,OIDpointer from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
	    if required == 'y'
	      if ds.affected_rows == 0
		    ds.cancel
		    runningErrorStr.concat(" missing required datastream #{dsid}")
		    next
		  end
        end
	    ds.each(:first=>true) do |ds1|		
		  dsArr.push(ds1)
	    end
	  		
	    dsArr.each do |ds1|
		  type = ds1["type"].nil? ? "" : ds1["type"].strip
	      md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
          pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
	      pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
          controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
          mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
          dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
		  oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip 
	      if ingestMethod == 'pullHTTP'
		    file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
            ff = File.new(file)
		    ng_xml = Nokogiri::XML::Document.parse(IO.read(ff))
		    if dsid1 == 'descMetadata' 
		      obj.descMetadata.ng_xml = ng_xml
		    elsif dsid1 == 'accessMetadata' 
		      obj.accessMetadata.ng_xml = ng_xml
		    elsif dsid1 == 'rightsMetadata' 
		      obj.rightsMetadata.ng_xml = ng_xml
		    end	
            File.delete(file)
		  elsif ingestMethod == 'filepath'
		    realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
		    if File.new(realpath).size == 0
              ds.cancel		  
			  runningErrorStr.concat(" file #{realpath} empty")
		      break
		    end  
		    digest = Digest::MD5.file(realpath).hexdigest
	        if digest != md5
	          ds.cancel
			  runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		      break
              return
            end
		    file = File.new(realpath)
            obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
          elsif ingestMethod == 'pointer'
            obj.oidpointer = oidPointer		
		  end
	    end
	  end
	  if runningErrorStr.size > 0
	    objpid = obj.nil? ? "" : obj.pid
	    processmsg(i,runningErrorStr,objpid)
	    return
	  end
      obj.oid = i["oid"].to_s
	  obj.cid = i["cid"].to_s
	  obj.projid = i["pid"].to_s
	  obj.zindex = i["zindex"].to_s
	  obj.parentoid = i["_oid"].to_s
	  ppid = getParentPid(i)
	  pid_uri = "info:fedora/#{ppid}"
	  obj.add_relationship(:is_member_of,pid_uri) 
	  obj.save
	  changeztotal(i,ppid)
	rescue Exception => msg
	  objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while updating #{objpid}")
	  #cleanup database
	  logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["hpid"]}/) 
	  update = @@client.execute(%Q/update hydra_publish set hydraID='',dateHydraStart = null,dateHydraEnd = null where hpid = #{i["hpid"]}/)
	  update.do
      processerror(i,msg,objpid)
	  return
    end
	begin
	  logger.info("PID #{obj.pid} sucessfully added for #{i["oid"]} as inserted child")	
	  update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}', dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	  update.do	  
	rescue Exception => msg
      processerror(i,msg,hydraID)
	end
  end  

  def processtopleveloid(i)
    @cnt += 1
	logger.info("oid count:"+@cnt.to_s)
    logger.info("starting processtopleveloid")  
	runningErrorStr = ""
	obj = nil
	contentModel = i["contentModel"]
	if contentModel == "simple"
      obj = Simple.new 
	elsif contentModel == "complexParent"
	  obj = ComplexParent.new   
	else
      erromsg = "Error, contentModel #{contentModel} not handled"
	  objpid = obj.nil? ? "" : obj.pid
	  processmsg(i,errormsg,objpid)
	  return
	end
	obj.label = ("oid: #{i["oid"]}")
	begin
	  datastreamsArr = Array.new
	  datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/) 
	  #
	  datastreams.each do |datastream|
	    datastreamsArr.push(datastream)
	  end
	#
	  datastreamsArr.each do |datastream|
	    dsid = datastream["dsid"].strip
	    ingestMethod = datastream["ingestMethod"].strip
	    required = datastream["required"].strip
	    dsArr = Array.new#
	    ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid,OIDpointer from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
	    if required == 'y'
	      if ds.affected_rows == 0
		    ds.cancel
		    runningErrorStr.concat(" missing required datastream #{dsid}")
		    next
		  end
        end
	    ds.each(:first=>true) do |ds1|
	      dsArr.push(ds1)
	    end
	  		
	    dsArr.each do |ds1|
		  type = ds1["type"].nil? ? "" : ds1["type"].strip
	      md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
          pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
	      pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
          controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
          mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
          dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
		  oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip 
	      if ingestMethod == 'pullHTTP'
		    file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
            ff = File.new(file)
		    ng_xml = Nokogiri::XML::Document.parse(IO.read(ff))
		    if dsid1 == 'descMetadata' 
		      obj.descMetadata.ng_xml = ng_xml
		    elsif dsid1 == 'accessMetadata' 
		      obj.accessMetadata.ng_xml = ng_xml
		    elsif dsid1 == 'rightsMetadata' 
		      obj.rightsMetadata.ng_xml = ng_xml
		    end	
            File.delete(file)
		  elsif ingestMethod == 'filepath'
		    realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
		    if File.new(realpath).size == 0
              ds.cancel		  
			  runningErrorStr.concat(" file #{realpath} empty")
		      break
		    end  
		    digest = Digest::MD5.file(realpath).hexdigest
	        if digest != md5
	          ds.cancel
			  runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		      break
              return
            end
		    file = File.new(realpath)
            obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
          elsif ingestMethod == 'pointer'
            obj.oidpointer = oidPointer		
		  end
	    end
	  end  
	  if runningErrorStr.size > 0
	    objpid = obj.nil? ? "" : obj.pid
	    processmsg(i,runningErrorStr,objpid)
	    return
	  end
      obj.oid = i["oid"].to_s
	  obj.cid = i["cid"].to_s
	  obj.projid = i["pid"].to_s
	  obj.zindex = i["zindex"].to_s
	  obj.parentoid = i["_oid"].to_s
	  collection_pid = get_collection_pid(i["cid"],i["pid"])
	  if collection_pid.size==0
	    processmsg(i,"collection pid not found",obj.pid)
	    return
	  end  
	  collection_pid_uri = "info:fedora/#{collection_pid}"
	  obj.add_relationship(:is_member_of,collection_pid_uri)
	  if contentModel == "complexParent"
	    resultArr = Array.new
	    result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
	    result.each(:first=>true) do |i|
	      resultArr.push(i)
	    end
	    resultArr.each do |i|
	      obj.ztotal =  i["total"].to_s
	    end
	  end  
	  #obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error
	  obj.save
	rescue Exception => msg
	  objpid = obj.nil? ? "" : obj.pid
	  if obj.persisted? == false
        logger.error("Exception during object ingest, but pid not saved, no need for rollback.")
      else
        logger.error("Exception occured while processing #{obj.pid} Delete PID.")
        obj.delete
      end
	    #cleanup database
		logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["hpid"]}/) 
	    update = @@client.execute(%Q/update hydra_publish set hydraID='',dateHydraStart = null,dateHydraEnd = null where hpid = #{i["hpid"]}/)
	    update.do
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg,obj.pid)
	  return
    end
	logger.info("PID #{obj.pid} sucessfully created for #{i["oid"]}")	
	update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	process_children(i,obj.pid)
  end

  #ERJ error routine for exceptions 
  def processerror(i,errormsg,pid="")
    @error_cnt += 1
    linenum = errormsg.backtrace[0].split(':')[1]
	dberror = "[#{linenum}] #{errormsg}"
    logger.error("error for oid: #{i["oid"]} pid: #{pid} errormsg: #{dberror}")
	logger.error("ERROR:" + errormsg.backtrace.to_s)
	begin
	  ehid = @@client2.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},'grep error ingest.log')/)
	  ehid.insert
	rescue Exception => msg
	  unless ehid.nil? 
		ehid.cancel
	  end
      logger.error("Error processing error:#{msg}")
	  logger.error("Warning, error won't be saved in database")
	  logger.error("ERROR:" + msg.backtrace.to_s)
	end  
  end
  #ERJ error routine for message driven errors (no exceptions) 
  def processmsg(i,errormsg,pid="")
    @error_cnt += 1
    logger.error("error for oid: #{i["oid"]} pid #{pid} errormsg: #{errormsg}")
	begin
	  ehid = @@client2.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},'grep error ingest.log')/)
	  ehid.insert
	rescue Exception => msg
	  unless ehid.nil? 
		ehid.cancel
	  end
      logger.error("Error processing error:#{msg}")
      logger.error("Warning, error won't be saved in database")
	  logger.error("ERROR:" + msg.backtrace.to_s)
    end	  
  end
  
  def process_children(i,ppid)
    logger.info("process_children for #{ppid}")
	resultArr = Array.new
	result = @@client.execute("select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.zindex from dbo.hydra_publish a,dbo.hydra_content_model b where a.dateHydraStart is null and a._oid=#{i["oid"]} and a.hcmid=b.hcmid and a.action='insert' and a.priority <> 999 order by a.date")
    result.each { |j|
	  resultArr.push(j)
	}
	resultArr.each { |j|
      begin 	
	    #update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{j["hpid"]}/)
        #update.do
          error = process_child(j,ppid)
	      #break if error=="error"		
	    #update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{j["hpid"]}/)
	    #update.do
	  rescue Exception => msg
	    unless update.nil? 
		  update.cancel
		end
	    unless result.nil?
		  result.cancel
		end
	    processerror(i,msg,"")
	    return
	  end
    }  
  end
  
  def process_child(i,ppid)
    @cnt += 1
	logger.info("oid count:"+@cnt.to_s)
	logger.info("processing child oid: #{i}")  
	update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE(),attempts=(select attempts+1 from hydra_publish where hpid=#{i["hpid"]}),server='#{@server}' where hpid=#{i["hpid"]}/)
	update.do
	#
	runningErrorStr = ""
	obj = nil
	contentModel = i["contentModel"]
	if contentModel == "complexChild"
	  obj = ComplexChild.new
	else
      erromsg =  "Error, contentModel #{contentModel} not handled"
	  objpid = obj.nil? ? "" : obj.pid
	  processmsg(i,errormsg,obj.pid)
	  return
	end
	obj.label = ("oid: #{i["oid"]}")
	begin
	datastreamsArr = Array.new
	datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/)
    datastreams.each do |datastream|
      datastreamsArr.push(datastream)
	end  
	datastreamsArr.each do |datastream|
	  dsid = datastream["dsid"].strip
	  ingestMethod = datastream["ingestMethod"].strip
	  required = datastream["required"].strip
	  dsArr = Array.new
	  ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
	  if required == 'y'
	    if ds.affected_rows == 0
		  ds.cancel
		  runningErrorStr.concat(" missing required datastream #{dsid}")
		  next
		end
      end
      ds.each(:first=>true) do |ds1|
        dsArr.push(ds1)
	  end	
	  dsArr.each do |ds1|
	    type = ds1["type"].nil? ? "" : ds1["type"].strip
	    md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
        pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
	    pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
        controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
        mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
        dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
	    if ingestMethod == 'pullHTTP'
		  file = @tempdir + 'temp.xml'
            open(file, 'wb') do |f|
              f << open(pathHTTP).read
            end
          ff = File.new(file)
          #obj.add_file_datastream(ff,:controlGroup=>controlGroup,:mimeType=>mimeType,:dsid=>dsid1)
		  ng_xml = Nokogiri::XML::Document.parse(IO.read(ff))
		  if dsid1 == 'descMetadata' 
		    obj.descMetadata.ng_xml = ng_xml
		  elsif dsid1 == 'accessMetadata' 
		    obj.accessMetadata.ng_xml = ng_xml
		  elsif dsid1 == 'rightsMetadata' 
		    obj.rightsMetadata.ng_xml = ng_xml
		  end
          File.delete(file)
		elsif ingestMethod == 'filepath'
		  realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
	      #logger.info("path: #{realpath}")
		  if File.new(realpath).size == 0
            ds.cancel		  
			runningErrorStr.concat(" file #{realpath} empty")
		    break
		  end  
	      #digest = Digest::MD5.hexdigest(File.read(realpath))
		  digest = Digest::MD5.file(realpath).hexdigest
		  #logger.info("digest #{digest}")
	      if digest != md5
	        ds.cancel
			runningErrorStr.concat("failed checksum for #{type} file #{realpath}") 
		    break
            return
          end
		  file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5') 
		end
	  end
	end  
	#
    if runningErrorStr.size > 0
	  objpid = obj.nil? ? "" : obj.pid
	  processmsg(i,runningErrorStr,obj.pid)
	  return
	end
    obj.oid = i["oid"].to_s
	obj.cid = i["cid"].to_s
	obj.projid = i["pid"].to_s
	obj.zindex = i["zindex"].to_s
	obj.parentoid = i["_oid"].to_s
	pid_uri = "info:fedora/#{ppid}"
	obj.add_relationship(:is_member_of,pid_uri)
	resultArr = Array.new
	result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
	result.each do |i|
	  resultArr.push(i)
	end
	resultArr.each do |i|
	  obj.ztotal =  i["total"].to_s
	end
	#obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error
	obj.save
	rescue Exception => msg
	  objpid = obj.nil? ? "" : obj.pid
	  if obj.persisted? == false
        logger.error("Exception during object ingest, but pid not saved, no need for rollback.")
      else
        logger.error("Exception occured while processing #{obj.pid} Delete PID.")
        obj.delete
      end
	  #cleanup remaining objects associated with the oid from fedora and solr
	  #deleteParentAndChildren(i) #decided not to do this rollback
	  #cleanup database
	  logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["_oid"]} and changing action to echild/) 
	  update = @@client.execute(%Q/update hydra_publish set hydraID='',dateHydraStart = null,dateHydraEnd = null,action='echild' where hpid = #{i["hpid"]}/)
	  #logger.info(%Q/DEBUG update hydra_publish set hydraID='',dateHydraStart = null,dateHydraEnd = null where (oid = #{i["_oid"]} or _oid = #{i["_oid"]}) and action='insert'/)
	  update.do
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg,obj.pid)
	  #return "error"
    end
	logger.info("PID #{obj.pid} sucessfully created for #{i["oid"]}")	
	update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#process_children(i,obj.pid)#ERJ process a child's child here
  end
  
  def deleteParentAndChildren(i)
    logger.info("also deleting all action='insert' PIDs for oid and _oid #{i["_oid"]}") 
    rollbacks = @@client.execute(%Q/select hydraID from hydra_publish where (oid = #{i["_oid"]} or _oid = #{i["_oid"]}) and hydraID <> '' and action='insert'/)
	#logger.info(%Q/DEBUG select hydraID from hydra_publish where (oid = #{i["_oid"]} or _oid = #{i["_oid"]}) and hydraID <> '' and action='insert'/)
	rollbacksArr = Array.new
	rollbacks.each do |j|
	  rollbacksArr.push(j)
	end
    rollbacksArr.each do |j|
	  begin
	    result = ActiveFedora::Base.find(j["hydraID"]).delete
        logger.info("DELETED #{j["hydraID"]}")
	  rescue
	    logger.info("PID NOT FOUND #{j["hydraID"]}")
	  end
	end
  end
  def getParentPid(i)
    logger.info(%Q/getting parent pid using oid #{i["_oid"]}/)
    resultArr = Array.new
	result = @@client.execute(%Q/select hydraID from dbo.hydra_publish where oid = #{i["_oid"]} and action='insert'/)
	result.each(:first=>true) do |i|
	resultArr.push(i)
	end
	hydraID = ''
	resultArr.each do |i|
	  hydraID =  i["hydraID"]
	end
	hydraID
  end
  def changeztotal(i,hydraID)
    logger.info(%Q/getting ztotal for _oid #{i["_oid"]} and updating PID #{hydraID}/)
	resultArr = Array.new
	result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["_oid"]}/)
	result.each(:first=>true) do |i|
	resultArr.push(i)
	end
	ztotal = 0
	resultArr.each do |i|
	  ztotal =  i["total"].to_s
	end
	logger.info("Changing ztotal to #{ztotal} for PID #{hydraID}")
	obj = ActiveFedora::Base.find(hydraID,:cast=>true)
	obj.ztotal = ztotal
	obj.save
	obj.pid
  end  
  def get_collection_pid(cid,pid) 
    query = "cid_isi:"+cid.to_s+" && projid_isi:"+pid.to_s+" && active_fedora_model_ssim:Collection"
	#logger.info("Q:"+query)
    blacklight_solr = RSolr.connect(@blacklight_solr_config)
	#logger.info("B:"+blacklight_solr.inspect)
    response = blacklight_solr.get("select",:params=> {:q => query,:fl =>"id"})
	#logger.info("R:"+response.inspect)
	logger.error("No Collection found for cid:"+cid.to_s+" pid:"+pid.to_s) if response["response"]["numFound"] == 0
    id = response["response"]["docs"][0]["id"]
    id
  end
  #queue_query - sql getting eligible objects from hydra_publish table
  def queue_query
    str = "select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.action,a.hydraID,a.zindex "+ 
	  "from hydra_publish a, hydra_content_model b "+
	  "where a.dateHydraStart is null and a.dateReady is not null and a.priority <> 999 and a.attempts < 3 " +
	  "and (server is null or server='#{@server}') "+
	  "and ((a.action='insert' and _oid=0) or (a.action='delete' or a.action='update' or a.action='ichild' or a.action='undel')) "+ 
	  "and a.hcmid=b.hcmid "+
      "order by a.priority, a.attempts, "+
	  "case a.action "+
	    "when 'delete' then 'a' "+ 
		"when 'undel' then 'b' "+
		"when 'update' then 'c' "+
        "when 'ichild' then 'd' "+
        "when 'insert' then 'e' "+
      "end,a.dateReady"
	str
  end
end
