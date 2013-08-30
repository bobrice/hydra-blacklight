require Rails.root.join('config/environment.rb')
RAILS_ROOT = Rails.root
Rails.logger = Logger.new("#{RAILS_ROOT}/log/ingest.log")
namespace :yulhy5 do
  desc "ingest from ladybird"
  task :ingest do
    logger.info("START: Running ladybird ingest")
	@start = Time.now
    logger.info("Start Time:"+@start.to_s)
	logger.info("requirement: root of share must be 'ladybird'")

	lbconf = YAML.load_file ('config/ladybird.yml')
	lbuser = lbconf.fetch("username").strip
	lbpw = lbconf.fetch("password").strip
	lbhost = lbconf.fetch("host").strip
	lbdb = lbconf.fetch("database").strip
	logger.info("user:"+lbuser)
	logger.info("pw:"+lbpw)
	logger.info("lbhost:"+lbhost)
	logger.info("db:"+lbdb)
	@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
	@@client2 = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)

    logger.info("client1 connection to db OK? #{@@client.active?}")
    if @@client.active? == false
      abort("TASK ABORTED: client1 could not connect to db")
    end

    logger.info("client2 connection to db OK? #{@@client2.active?}")
    if @@client2.active? == false
      abort("TASK ABORTED: client2 could not connect to db")
    end

	@mountroot = "/home/ermadmix/libshare/"
	logger.info("batch mounted as " + @mountroot)
	@tempdir = "/home/ermadmix/"
	logger.info("temp directory" + @tempdir)
	@blacklight_solr_config = Blacklight.solr_config
	logger.info("solr host:" + @blacklight_solr_config.inspect)
	#@blacklight_fedora_config = Blacklight.solr_config
	#logger.info("fedora host:" + @blacklight_fedora_config.inspect)
	@cnt=0
	@error_cnt = 0
    processoids()
    @@client.close
	@@client2.close

	@finish = Time.now
    logger.info("End Time:"+@finish.to_s)
	@elapse = @finish - @start
	logger.info("Elapsed Time:"+@elapse.to_s)
  end

  def processoids()
    if @error_cnt > 20
	  logger.info("Stopping due to too many errors.")
	  abort("TASK ABORTED, too many errors")
	end	   
	@cnt += 1
	logger.info("queue counter:"+@cnt.to_s)
    if @cnt%1000==0
	   logger.info("resetting runaway stopper")
       @error_cnt = 0#reset runaway error count every 1000
    end	
	result = @@client.execute("select top 1 a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid from dbo.hydra_publish a, dbo.hydra_content_model b where a.dateHydraStart is null and a.dateReady is not null and a._oid=0 and a.hcmid is not null and a.hcmid=b.hcmid and a.action='insert' order by a.dateReady")
    result.fields.to_s
	if result.affected_rows == 0
	  result.cancel#
      @@client.close
	  @@client2.close
      
	  logger.info("DONE")
	  @finish = Time.now
      logger.info("End Time:"+@finish.to_s)
	  @elapse = @finish - @start
	  logger.info("Elapsed Time:"+@elapse.to_s)
	  abort("DONE, no more baghydra rows to process")
    else
      resultArr = Array.new#	
      result.each(:first=>true) do |i|
        resultArr.push(i)  
      end
	  resultArr.each do |i|
        begin
          processparentoid(i)
        rescue Exception => msg
          processerror(i,msg)
        end		  
      end
	  if @cnt > 0
	    @@client.close
	    @@client2.close
	    logger.info("Count exceeded "+@cnt+" at "+Time.now.to_s)
	    abort("stopped at a hard limit to prevent infinite loop")
	  end	  
      processoids()
    end
  end
  
  def processparentoid(i)
	logger.info("processing top level oid: #{i}")  
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
          obj.add_file_datastream(file,:dsid=>dsid,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
        elsif ingestMethod == 'pointer'
          obj.oidpointer = oidPointer		
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
    obj.oid = i["oid"].to_s
	obj.cid = i["cid"].to_s
	obj.projid = i["pid"].to_s
	obj.zindex = i["zindex"].to_s
	obj.parentoid = i["_oid"].to_s
	collection_pid = get_collection_pid(i["cid"],i["pid"])
	if collection_pid.size==0
	  processmsg(i,"collection pid not found")
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
	  if obj.persisted? == false
        logger.error("Exception during object ingest, but pid not saved, no need for rollback.")
      else
        logger.error("Exception occured while processing #{obj.pid} Delete PID.")
        obj.delete
      end
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg)
	  return
    end
	logger.info("PID #{obj.pid} sucessfully created for #{i["oid"]}")	
	update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	process_children(i,obj.pid)
  end

  #ERJ error routine for exceptions 
  def processerror(i,errormsg)
    @error_cnt += 1
    linenum = errormsg.backtrace[0].split(':')[1]
	dberror = "[#{linenum}] #{errormsg}"
    logger.error("error for oid: #{i["oid"]} errormsg: #{dberror}")
	logger.error("ERROR:" + errormsg.backtrace.to_s)
	begin
	  ehid = @@client2.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},'grep Error ingest.log')/)
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
  def processmsg(i,errormsg)
    @error_cnt += 1
    logger.error("error for oid: #{i["oid"]} errormsg: #{errormsg}")
	begin
	  ehid = @@client2.execute(%Q/insert into dbo.hydra_publish_error (hpid,date,oid,error) values (#{i["hpid"]},GETDATE(),#{i["oid"]},'grep Error ingest.082913.log')/)
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
	result = @@client.execute("select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.zindex from dbo.hydra_publish a,dbo.hydra_content_model b where a.dateHydraStart is null and a._oid=#{i["oid"]} and a.hcmid=b.hcmid and a.action='insert' order by a.date")
    result.each { |j|
	  resultArr.push(j)
	}
	resultArr.each { |j|
      begin 	
	    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{j["hpid"]}/)
        update.do
          process_child(j,ppid)
			
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
	    return
	  end
    }  
  end
  
    def process_child(i,ppid)
	logger.info("processing child oid: #{i}")  
	update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#
	runningErrorStr = ""
	obj = nil
	contentModel = i["contentModel"]
	if contentModel == "complexChild"
	  obj = ComplexChild.new
	else
      erromsg =  "Error, contentModel #{contentModel} not handled"
	  processmsg(i,errormsg)
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
	  if obj.persisted? == false
        logger.error("Exception during object ingest, but pid not saved, no need for rollback.")
      else
        logger.error("Exception occured while processing #{obj.pid} Delete PID.")
        obj.delete
      end
	  unless result.nil? 
		result.cancel
	  end
      processerror(i,msg)
	  return
    end
	logger.info("PID #{obj.pid} sucessfully created for #{i["oid"]}")	
	update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
	update.do
	#process_children(i,obj.pid)#ERJ process a child's child here
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

end