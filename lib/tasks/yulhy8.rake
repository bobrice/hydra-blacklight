require Rails.root.join('config/environment.rb')
RAILS_ROOT = Rails.root
Rails.logger = Logger.new("#{RAILS_ROOT}/log/ingest.log",10,200.megabytes)
Rails.logger.formatter = Logger::Formatter.new
namespace :yulhy8 do
  desc "ingest from ladybird"
  task :ingest do
    #initialization
    initialize_ingest

    #set configuration
    config_file = 'config/ingest.yml'
    configure(config_file)

    #check if any rows to process, if no rows then abort
    rows = check_if_any_rows_to_process
    if rows == 0
      close_and_exit("no rows to process upfront")
    end

    #if script reaches here, there ARE rows to process, send email that ingest has started
    @subject = "Ingest Started"
    @message = "Ingest Started at #{@start}"
    mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
    mail.deliver

    #main processing loop
    main_processing_loop(rows)

    #if script reaches here there are no more rows to process, close connections, send email,and abort
    ingest_complete
  end
  
  #methods
  def initialize_ingest
    logger.info("START: Running ladybird ingest")
    @start = Time.now
    logger.info("Start Time:"+@start.to_s)
    @cnt = 0
    @error_cnt = 0
    @success_cnt = 0
  end

  def configure(config_file = 'config/ingest.yml')
    #environment (development, test, or production)
    environment = Rails.env
    logger.info("Environment: " + Rails.env)
    #configuration of ladybird sqlserver database
    config = YAML.load_file('config/ingest.yml')
    if environment == 'development'
      lbuser = config.fetch("username_d").strip
      lbpw = config.fetch("password_d").strip
      lbhost = config.fetch("host_d").strip
      lbdb = config.fetch("database_d").strip
    elsif environment == 'test'
      lbuser = config.fetch("username_t").strip
      lbpw = config.fetch("password_t").strip
      lbhost = config.fetch("host_t").strip
      lbdb = config.fetch("database_t").strip
    elsif environment == 'production'
      lbuser = config.fetch("username_p").strip
      lbpw = config.fetch("password_p").strip
      lbhost = config.fetch("host_p").strip
      lbdb = config.fetch("database_p").strip
    else
      abort("TASK ABORTED, region is neither development, test, or production")
    end
    logger.info("user:" + lbuser)
    logger.info("pw:" + lbpw)
    logger.info("lbhost:" + lbhost)
    logger.info("db:" + lbdb)

    #create 2 connections to SQLSERVER database using TinyTds client and check connections
	#TinyTds documentation: https://github.com/rails-sqlserver/tiny_tds
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

    #configure location of ladybird storage
    @mountroot = config.fetch("mountroot")
    logger.info("batch mounted as: " + @mountroot)

    #configure directory for transient IO operation
    @tempdir = config.fetch("tempdir")
    logger.info("temp directory: " + @tempdir)

    #configure solr host
    @blacklight_solr_config = Blacklight.solr_config
    logger.info("solr host:" + @blacklight_solr_config.inspect)

    #configure fedora host
    fedoraconf = YAML.load_file('config/fedora.yml')
    region = fedoraconf.fetch(environment)
    @server = region.fetch("url")
    logger.info("fedora host: " + @server)

	#configure email notification list
    @email_list = config.fetch("email_list")
    logger.info("email list:")
    @email_list.each do |email|
      logger.info("  " + email)
    end

    #configure stop count
    @stop_count = config.fetch("stop_count")
    logger.info("stop count: " + @stop_count.to_s)

    #configure max number of errors to allow per 1000
    @error_max = config.fetch("error_max")
    logger.info("error max: " + @error_max.to_s)

    #configure error sleep time
    @error_sleep_time = config.fetch("error_sleep_time")
    logger.info("error sleep time (hours): " + @error_sleep_time.to_s)

    #configure checksums enabled
    @checksums_enabled = config.fetch("checksums_enabled")
    logger.info("checksums enabled: " + @checksums_enabled.to_s)

    #ingest server
	@ingest_server = config.fetch("ingest_server")
	logger.info("ingest server: " + @ingest_server)
  end

  def check_if_any_rows_to_process
    result = @@client.execute(queue_query)
    logger.info(queue_query)
    result.each
    rows = result.affected_rows
    result.fields.to_s
    logger.info("number of rows to process in hydra publish table:"+rows.to_s)
    result.cancel
    rows
  end

  def check_if_insert_oid_already_ingested(oid)
    already_ingested = false
	str = "select hpid from hydra_publish where hydraID <> '' and (action = 'insert' or action = 'ichild' or action = 'echild') and oid = #{oid}"
    result = @@client.execute(str)
    logger.info(str)
    result.each
    rows = result.affected_rows
    result.fields.to_s
	result.cancel
    logger.info("(if already ingested this oid is > 0):"+rows.to_s)
	already_ingested = true if rows > 0 
    already_ingested
  end
  

  def get_highest_priority_row_and_rows_remaining
    result = @@client.execute(queue_query)
    result.fields.to_s 
    resultArr = Array.new	
    result.each(:first=>true) do |i|
      resultArr.push(i)  
    end
    rows = result.affected_rows
    result.cancel
    return resultArr,rows
  end

  def main_processing_loop(rows)
    while rows > 0
      logger.info("Inside Loop to process rows. Number of top level rows remaining to process in hydra publish table:"+rows.to_s)
      resultArr,rows = get_highest_priority_row_and_rows_remaining
      resultArr.each do |i|
        counter_check
        begin
          processqueue(i)
        rescue Exception => msg
          processerror(i,msg,"")
        end

        #forced abort at a limit (for testing purposes)
        if @cnt == @stop_count
          logger.info("Count exceeded "+@cnt.to_s+" at "+Time.now.to_s)
          close_and_exit("Forced abort at " + @cnt.to_s + "limit")  
        end
      end
      #rows -= 1
	  resultArr,rows = get_highest_priority_row_and_rows_remaining
    end
  end	

  #code to pause ingest if too many errors occur
  def counter_check
    logger.info("count of rows processed:"+@cnt.to_s)

    if @error_cnt > @error_max
      logger.info("More than " + @error_max.to_s + " errors per 1000, stopping for " + @error_sleep_time.to_s + " hour(s).")
      puts("More than " + @error_max.to_s + " errors per 1000, stopping for " + @error_sleep_time.to_s + " hour(s).")

      @subject = "Ingest Suspended"
      susTime = Time.now
      @message = "Ingest Suspended for #{@error_sleep_time.to_s} hours to do errors at #{susTime}"
      mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
      mail.deliver
      @error_cnt = 0
      sleep(@error_sleep_time.to_s + ".hours")
    end	   

    if @cnt%1000==0
	  logger.info("resetting runaway stopper")
      @error_cnt = 0
    end	
  end

  def processqueue(i)
    logger.info("processing queue oid: #{i}")
    #sql to set dateHydraStart, increment attempts, and record server
    hydra_start(i)

    action = i["action"]
    if action == "purge"
      purgeoid(i)
    elsif action == "delete"
      deleteoid(i)
    elsif action == "undel"
      undeleteoid(i)	
    elsif action == "update"
      updateoid(i)	
    elsif action == "ichild"
      insertchild(i)
    elsif action == "echild"
      insertchild(i)  
    elsif action == "insert"
      processtopleveloid(i)
    else
      errormsg = "Error, action #{action} not handled"
      processmsg(i,errormsg,"")	  
      return
    end
  end

  def purgeoid(i)
    hydraID = i["hydraID"]
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("starting purgeoid for #{hydraID}")
    begin	
      obj = ActiveFedora::Base.find(hydraID,:cast=>true)
      obj.delete

      logger.info("PID #{obj.pid} sucessfully purged for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end  
  end

  def deleteoid(i)
    hydraID = i["hydraID"]
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("starting deleteoid for #{hydraID}")
    begin	
      obj = ActiveFedora::Base.find(hydraID,:cast=>true)
      obj.inner_object.state = 'I'
      obj.save

      logger.info("PID #{obj.pid} sucessfully inactivated for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end  
  end

  def undeleteoid(i)
    hydraID = i["hydraID"]
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("starting undeleteoid for #{hydraID}")
    begin
      obj = ActiveFedora::Base.find(hydraID,:cast=>true)
      obj.inner_object.state = 'A'
      obj.save

      logger.info("PID #{obj.pid} sucessfully activated for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end  
  end

  def updateoid(i)
    hydraID = i["hydraID"]
    contentModel = i["contentModel"]
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("starting updateoid for #{hydraID}")
	
    runningErrorStr = ""
    obj = nil
    begin
      #get object from fedora to update
      obj = ActiveFedora::Base.find(hydraID,:cast=>true)

      dsArr = get_hydra_publish_path_rows_by_hpid(i)

      dsArr.each do |ds1|
        #get variables for a row
        type = ds1["type"].nil? ? "" : ds1["type"].strip
        md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
        pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
        pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
        controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
        mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
        dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
        ingestMethod = ds1["ingestMethod"].nil? ? "" : ds1["ingestMethod"].strip
        oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip 
        #create xml datastreams retrieved via http
        if ingestMethod == 'pullHTTP'
          ng_xml = get_xml_via_http(pathHTTP)
          obj = set_xml_datastreams(dsid1,ng_xml,obj)
          #create content datastreams from files in mounted ladybird directory
        elsif ingestMethod == 'filepath'
          realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
          #check that size isn't 0
          zero,message = check_filesize_not_zero(realpath)
          if zero
            runningErrorStr.concat(message)
            break
          end
          #validate checksums if enabled via config
          if @checksums_enabled
            valid,message = validate_checksums(realpath,md5,type)
            if valid == false
              runningErrorStr.concat(messsage) 
              break
            end
          end
          file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
          #add oidpointer as object property
        elsif ingestMethod == 'pointer'
          obj.oidpointer = oidPointer		
        end
      end
      #process caught errors
      if runningErrorStr.size > 0
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,runningErrorStr,objpid)
        return
      end
      #add object properties
      obj.oid = i["oid"].to_s
      obj.cid = i["cid"].to_s
      obj.projid = i["pid"].to_s
      obj.zindex = i["zindex"].to_s
      obj.parentoid = i["_oid"].to_s
      if contentModel == "complexParent"
        obj.ztotal = get_ztotal(i)
      end  
      #obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error 
      obj.save
    #rescue any exceptions during building of the object  
    rescue Exception => msg
      objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while updating #{objpid}")
      reset_hydra_publish_table(i)
      processerror(i,msg,objpid)
      rollback_pid(obj)
      return
    end
    #update hydra_publish that pid was successfully updated
    begin
	  logger.info("PID #{obj.pid} sucessfully updated for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end
  end

  #handles both action=ichild and action=echild
  def insertchild(i)
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
	action = i["action"]
    logger.info(%Q/starting #{action} for #{i["oid"]}/)
	#skip if already ingested
	if check_if_insert_oid_already_ingested(i["oid"])
      logger.info("This oid #{i["oid"]} has already been ingested, skip")
	  flag_duplicate(i)
	  return
	end  
	
    runningErrorStr = ""
    obj = nil
    begin
      #create new object
      contentModel = i["contentModel"]
      if contentModel == "complexChild"
        obj = ComplexChild.new 
      else
        erromsg = "Error, contentModel #{contentModel} not handled in insert child"
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,errormsg,objpid)
        return
      end

      #add label
      obj.label = "oid: #{i["oid"]}"

      #get expected datastreams for contentmodel and process each
      datastreamsArr = get_contentmodel_datastreams(contentModel)
      datastreamsArr.each do |datastream|
        #get variables for contentmodel datastreams
        dsid = datastream["dsid"].strip
        ingestMethod = datastream["ingestMethod"].strip
        required = datastream["required"].strip
        #get actual datastream
        missing,message,dsArr = query_hydra_publish_path_for_datastream(i,dsid,required)
        if missing
          runningErrorStr.concat(message)
          next
        end  
        #process datastream	
        dsArr.each do |ds1|
          #get datasream variables
          type = ds1["type"].nil? ? "" : ds1["type"].strip
          md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
          pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
          pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
          controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
          mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
          dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
          oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip
          #create xml datastreams retrieved via http as per content model
          if ingestMethod == 'pullHTTP'
            ng_xml = get_xml_via_http(pathHTTP)
            obj = set_xml_datastreams(dsid1,ng_xml,obj)
            #create content datastreams from files in mounted ladybird directory	
          elsif ingestMethod == 'filepath'
            realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
            #check that size isn't 0
            zero,message = check_filesize_not_zero(realpath)
            if zero
              runningErrorStr.concat(message)
              break
			end
            #validate checksums if enabled via config
            if @checksums_enabled
              valid,message = validate_checksums(realpath,md5,type)
              if valid == false
                runningErrorStr.concat(messsage) 
                break
              end
            end
		    file = File.new(realpath)
            obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
          #add oidpointer as object property
          elsif ingestMethod == 'pointer'
            obj.oidpointer = oidPointer		
          end
        end
      end
	  #process caught errors
      if runningErrorStr.size > 0
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,runningErrorStr,objpid)
        return
      end
      #add object properties
      obj.oid = i["oid"].to_s
      obj.cid = i["cid"].to_s
      obj.projid = i["pid"].to_s
      obj.zindex = i["zindex"].to_s
      obj.parentoid = i["_oid"].to_s
      #add parent relationship
      ppid = getParentPid(i)
      pid_uri = "info:fedora/#{ppid}"
      obj.add_relationship(:is_member_of,pid_uri)

      obj.save
      #changeztotal in parent 
      changeztotal(i,ppid)
    rescue Exception => msg
      objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while inserting #{objpid}")
      reset_hydra_publish_table(i)
      processerror(i,msg,objpid)
      rollback_pid(obj)
      return
    end
    #update hydra_publish that child was successfully inserted
    begin
      logger.info("PID #{obj.pid} sucessfully added for #{i["oid"]} as inserted child")
	  str = ""
	  if action == 'echild'
        str = %Q/update dbo.hydra_publish set hydraID='#{obj.pid}', dateHydraEnd=GETDATE(),action='insert' where hpid=#{i["hpid"]}/
	  elsif action == 'ichild'
	    str = %Q/update dbo.hydra_publish set hydraID='#{obj.pid}', dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/
	  end
      update = @@client.execute(str)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end
  end  

  def processtopleveloid(i)
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("starting processtopleveloid")
	#skip if already ingested
	if check_if_insert_oid_already_ingested(i["oid"])
      logger.info("This oid #{i["oid"]} has already been ingested, skip")
	  flag_duplicate(i)
	  return
	end 
	
    runningErrorStr = ""
    obj = nil
    contentModel = i["contentModel"]
    begin
      #create new object
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
      #add label
      obj.label = "oid: #{i["oid"]}"
      #get expected datastreams for contentmodel and process each
      datastreamsArr = get_contentmodel_datastreams(contentModel)
      datastreamsArr.each do |datastream|
        #get variables for contentmodel datastreams
        dsid = datastream["dsid"].strip
        ingestMethod = datastream["ingestMethod"].strip
        required = datastream["required"].strip
        #get actual datastream
        missing,message,dsArr = query_hydra_publish_path_for_datastream(i,dsid,required)
        if missing
          runningErrorStr.concat(message)
          next
        end  
        #process datastream
        dsArr.each do |ds1|
          #get datasream variables
          type = ds1["type"].nil? ? "" : ds1["type"].strip
          md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
          pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
          pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
          controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
          mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
          dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
          oidPointer = ds1["OIDpointer"].nil? ? "" : ds1["OIDpointer"].to_s.strip 
          #create xml datastreams retrieved via http as per content model
          if ingestMethod == 'pullHTTP'
            ng_xml = get_xml_via_http(pathHTTP)
            obj = set_xml_datastreams(dsid1,ng_xml,obj)
          #create content datastreams from files in mounted ladybird directory	
          elsif ingestMethod == 'filepath'
            realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
            #check that size isn't 0
            zero,message = check_filesize_not_zero(realpath)
            if zero
              runningErrorStr.concat(message)
              break
            end
            #validate checksums if enabled via config
            if @checksums_enabled
              valid,message = validate_checksums(realpath,md5,type)
              if valid == false
                runningErrorStr.concat(messsage) 
                break
              end
            end
            file = File.new(realpath)
          obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5')
          #add oidpointer as object property
          elsif ingestMethod == 'pointer'
            obj.oidpointer = oidPointer		
          end
        end
      end
      #process caught errors 
      if runningErrorStr.size > 0
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,runningErrorStr,objpid)
        return
      end
      #add object properties
      obj.oid = i["oid"].to_s
      obj.cid = i["cid"].to_s
      obj.projid = i["pid"].to_s
      obj.zindex = i["zindex"].to_s
      obj.parentoid = i["_oid"].to_s
      if contentModel == "complexParent"
        obj.ztotal = get_ztotal(i)
      end
      #add parent relationship - as this is a top level object, this is the collection (pid) 
      collection_pid = get_collection_pid(i["cid"],i["pid"])
      if collection_pid.size==0
        processmsg(i,"collection pid not found",obj.pid)
        return
      end  
      collection_pid_uri = "info:fedora/#{collection_pid}"
      obj.add_relationship(:is_member_of,collection_pid_uri)

      #obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error
      obj.save
    rescue Exception => msg
	  objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while inserting parent object #{objpid}")
      reset_hydra_publish_table(i)
      processerror(i,msg,obj.pid)
      rollback_pid(obj)
      return
    end
    #update hydra_publish that toplevelobject was successfully inserted
    begin
      logger.info("top level PID #{obj.pid} sucessfully created for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end
    #process children of this top level object
    process_children(i,obj.pid)
  end

  def process_children(i,ppid)
    logger.info("process_children for #{ppid}")
    resultArr = get_children_rows(i)
    resultArr.each do |j| 	
      process_child(j,ppid)
    end
  end

  def process_child(i,ppid)
    @cnt += 1
    logger.info("row count:"+@cnt.to_s)
    logger.info("processing child oid: #{i}")
    #sql to set dateHydraStart, increment attempts, and record server
    hydra_start(i)
	#skip if already ingested
	if check_if_insert_oid_already_ingested(i["oid"])
      logger.info("This oid #{i["oid"]} has already been ingested, skip")
	  flag_duplicate(i)
	  return
	end 

    runningErrorStr = ""
    obj = nil
    contentModel = i["contentModel"]
   begin
      #create new object
      if contentModel == "complexChild"
        obj = ComplexChild.new
      else
        erromsg =  "Error, contentModel #{contentModel} not handled"
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,errormsg,obj.pid)
        return
      end
      #add label
      obj.label = "oid: #{i["oid"]}"
      #get expected datastreams for contentmodel and process each
      datastreamsArr = get_contentmodel_datastreams(contentModel)  
      datastreamsArr.each do |datastream|
        #get variables for contentmodel datastream
        dsid = datastream["dsid"].strip
        ingestMethod = datastream["ingestMethod"].strip
        required = datastream["required"].strip
        #get actual datastream
        missing,message,dsArr = query_hydra_publish_path_for_datastream(i,dsid,required)
        if missing
          runningErrorStr.concat(message)
          next
        end  
        #process datastream
        dsArr.each do |ds1|
          #get datasream variables
          type = ds1["type"].nil? ? "" : ds1["type"].strip
          md5 = ds1["md5"].nil? ? "" : ds1["md5"].strip
          pathUNC = ds1["pathUNC"].nil? ? "" : ds1["pathUNC"].strip
          pathHTTP = ds1["pathHTTP"].nil? ? "" : ds1["pathHTTP"].strip
          controlGroup = ds1["controlGroup"].nil? ? "" : ds1["controlGroup"].strip
          mimeType = ds1["mimeType"].nil? ? "" : ds1["mimeType"].strip
          dsid1 = ds1["dsid"].nil? ? "" : ds1["dsid"].strip
          #create xml datastreams retrieved via http as per content model
          if ingestMethod == 'pullHTTP'
            ng_xml = get_xml_via_http(pathHTTP)
            obj = set_xml_datastreams(dsid1,ng_xml,obj)
          #create content datastreams from files in mounted ladybird directory  
          elsif ingestMethod == 'filepath'
            realpath = @mountroot + pathUNC[pathUNC.rindex('ladybird'),pathUNC.length].gsub(/\\/,'/')
            #check that size isn't 0
            zero,message = check_filesize_not_zero(realpath)
            if zero
              runningErrorStr.concat(message)
              break
            end
            #validate checksums if enabled via config
            if @checksums_enabled
              valid,message = validate_checksums(realpath,md5,type)
              if valid == false
                runningErrorStr.concat(messsage) 
                break
              end
            end
            file = File.new(realpath)
            obj.add_file_datastream(file,:dsid=>dsid1,:mimeType=>mimeType, :controlGroup=>controlGroup,:checksumType=>'MD5') 
          end
        end
      end  
      #process caught errors
      if runningErrorStr.size > 0
        objpid = obj.nil? ? "" : obj.pid
        processmsg(i,runningErrorStr,obj.pid)
        return
      end
      #add object properties
      obj.oid = i["oid"].to_s
      obj.cid = i["cid"].to_s
      obj.projid = i["pid"].to_s
      obj.zindex = i["zindex"].to_s
      obj.parentoid = i["_oid"].to_s
      #add parent relationship
      pid_uri = "info:fedora/#{ppid}"
      obj.add_relationship(:is_member_of,pid_uri)
      #placeholder for ztotal of grandchildren 
      #obj.ztotal = get_ztotal(i)
      #obj.add_relationship(:is_member_off,"info:fedora/fakepid:74") #to test error
      obj.save
    rescue Exception => msg
      objpid = obj.nil? ? "" : obj.pid
      logger.error("Exception occured while inserting #{objpid}")
      reset_hydra_publish_table_echild(i)
      #deleteParentAndChildren(i) #decided not to do this 
      processerror(i,msg,obj.pid)
      rollback_pid(obj)
      return
    end
    #update hydra_publish
    begin
      logger.info("PID #{obj.pid} sucessfully created for #{i["oid"]}")	
      update = @@client.execute(%Q/update dbo.hydra_publish set hydraID='#{obj.pid}',dateHydraEnd=GETDATE() where hpid=#{i["hpid"]}/)
      update.do
      @success_cnt += 1
    rescue Exception => msg
      processerror(i,msg,hydraID)
    end
      #process_children(i,obj.pid)#process a child's child here
  end

  def get_hydra_publish_path_rows_by_hpid(i)
    ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid,ingestMethod,OIDpointer from dbo.hydra_publish_path where hpid=#{i["hpid"]}/)
    dsArr = Array.new
    ds.each do |ds1|
      dsArr.push(ds1)
    end
    ds.cancel
    dsArr
  end

  def get_xml_via_http(pathHTTP)
    file = @tempdir + 'temp.xml'
    open(file, 'wb') do |f|
      f << open(pathHTTP).read
    end
    ff = File.new(file)
    ng_xml = Nokogiri::XML::Document.parse(IO.read(ff))
    File.delete(file)
    ng_xml
  end

  def set_xml_datastreams(dsid1,ng_xml,obj)
    if dsid1 == 'descMetadata' 
      obj.descMetadata.ng_xml = ng_xml
    elsif dsid1 == 'accessMetadata' 
      obj.accessMetadata.ng_xml = ng_xml
    elsif dsid1 == 'rightsMetadata' 
      obj.rightsMetadata.ng_xml = ng_xml
    end
    obj
  end

  #design decision - this method is not used - not worth rolling back a whole parent/child
  def deleteParentAndChildren(i)
    logger.info("also deleting all action='insert' PIDs for oid and _oid #{i["_oid"]}") 
    rollbacks = @@client.execute(%Q/select hydraID from hydra_publish where (oid = #{i["_oid"]} or _oid = #{i["_oid"]}) and hydraID <> '' and action='insert'/)
    rollbacksArr = Array.new
    rollbacks.each do |j|
      rollbacksArr.push(j)
    end
    rollbacks.cancel
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
    result.cancel
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
    result.cancel
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

  def check_filesize_not_zero(path)
    message = ""
    zero = false	
    if File.new(path).size == 0		  
      message = " file #{path} empty"
      zero = true 
    end
    return zero,message
  end

  def validate_checksums(path,md5,type)
    message = ""
    valid = true
    digest = Digest::MD5.file(path).hexdigest
    if digest != md5
      message = "failed checksum for #{type} file #{path}"
      valid = false
    end
    return valid,message
  end

  def get_ztotal(i)
    ztotal = 0
    resultArr = Array.new 
    result = @@client.execute(%Q/select max(zindex) as total from dbo.hydra_publish where _oid = #{i["oid"]}/)
    result.each(:first=>true) do |i|
      resultArr.push(i)
    end
    result.cancel
    resultArr.each do |i|
      ztotal =  i["total"].to_s
    end
   ztotal
  end

  def reset_hydra_publish_table(i)
    logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["hpid"]}/) 
    update = @@client.execute(%Q/update hydra_publish set dateHydraStart = null,dateHydraEnd = null where hpid = #{i["hpid"]}/)
    update.do
  end
  
  def reset_hydra_publish_table_echild(i)
    logger.error(%Q/resetting hydra_publish hydraID,dateHydraStart and dateHydra end for #{i["hpid"]} and changing action to echild/) 
    update = @@client.execute(%Q/update hydra_publish set dateHydraStart = null,dateHydraEnd = null, action = 'echild' where hpid = #{i["hpid"]}/)
    update.do
  end

  def get_contentmodel_datastreams(contentModel)
    datastreamsArr = Array.new
    datastreams = @@client.execute(%Q/select hcmds.dsid as dsid,hcmds.ingestMethod as ingestMethod, hcmds.required as required from dbo.hydra_content_model hcm, dbo.hydra_content_model_ds hcmds where hcm.contentModel = '#{contentModel}' and hcm.hcmid = hcmds.hcmid/)
    datastreams.each do |datastream|
      datastreamsArr.push(datastream)
    end
    datastreams.cancel
    datastreamsArr
  end

  def query_hydra_publish_path_for_datastream(i,dsid,required)
    dsArr = Array.new
    message = ""
    missing = false	 
    ds = @@client.execute(%Q/select type,pathHTTP,pathUNC,md5,controlGroup,mimeType,dsid,OIDpointer from dbo.hydra_publish_path where hpid=#{i["hpid"]} and dsid='#{dsid}'/)
    if required == 'y'
      if ds.affected_rows == 0
        ds.cancel
        message = " missing required datastream #{dsid}"
        missing = true
        return missing,message,dsArr
      end
    end
    ds.each(:first=>true) do |ds1|		
      dsArr.push(ds1)
    end
    ds.cancel
    return missing,message,dsArr
  end

  def get_children_rows(i)
    resultArr = Array.new
    result = @@client.execute("select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.zindex from dbo.hydra_publish a,dbo.hydra_content_model b where a.dateHydraStart is null and a._oid=#{i["oid"]} and a.hcmid=b.hcmid and a.action='insert' and a.priority <> 999 order by a.date")
    result.each { |j|
      resultArr.push(j)
    }
    result.cancel
    resultArr
  end
  
  def hydra_start(i)
    #sql to set dateHydraStart, increment attempts, a record server
    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE(),attempts=(select attempts+1 from hydra_publish where hpid=#{i["hpid"]}),server='#{@server}',ingestServer='#{@ingest_server}' where hpid=#{i["hpid"]}/)
    update.do
  end

  def flag_duplicate(i)
    #sql to set action='duplicate' if already if action='insert'
    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=GETDATE(),dateHydraEnd=GETDATE(),action='duplic',server='#{@server}' where hpid=#{i["hpid"]}/)
    update.do
  end

  #queue_query - sql getting eligible objects from hydra_publish table
  def queue_query
    str = "select a.hpid,a.oid,a.cid,a.pid,b.contentModel,a._oid,a.action,a.hydraID,a.zindex "+ 
      "from hydra_publish a, hydra_content_model b "+
      "where a.dateHydraStart is null and a.dateReady is not null and a.priority <> 999 and a.attempts < 3 " +
      "and (server is null or server='#{@server}') "+
      "and ((a.action='insert' and _oid=0) "+
      "or (a.action='purge' or a.action='delete' or a.action='update' or a.action='ichild' or a.action='undel' or a.action='echild')) "+ 
      "and a.hcmid=b.hcmid "+
      "order by a.priority, a.attempts, "+
      "case a.action "+
	  "when 'purge' then 'a' "+
      "when 'delete' then 'b' "+ 
      "when 'undel' then 'c' "+
      "when 'update' then 'd' "+
      "when 'ichild' then 'e' "+
      "when 'insert' then 'f' "+
	  "when 'echild' then 'g' "+
      "end,a.dateReady"
    str
  end

  def rollback_pid(obj)
    if obj.persisted? == false
      logger.error("Exception during object ingest, but pid not saved, no need for rollback.")
    else
      logger.error("Exception occured while processing #{obj.pid} Delete PID.")
      obj.delete
    end
  end

  #method for processing exceptions 
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

  #method for processing errors (not exceptions)
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

  def ingest_complete
    logger.info("DONE")
    @finish = Time.now
    logger.info("End Time:"+@finish.to_s)
    @elapse = @finish - @start
    logger.info("Elapsed Sec:"+@elapse.to_s)
	logger.info("Total Row Count:"+@cnt.to_s)
	logger.info("Success Row Count:"+@success_cnt.to_s)
    @subject = "Ingest Complete"
    @message = "Ingest Started at #{@start}   Ingest Completed at #{@finish}   Elapsed Sec #{@elapse}   Row Count #{@cnt}   Success Row Count #{@success_cnt} "
    mail = ActionMailer::Base.mail(to: @email_list,subject: @subject,message: @message)
    mail.deliver
    close_and_exit("DONE, no more hydra_publish to process")
  end

  def close_and_exit(abort_message = "aborting")
    @@client.close
    @@client2.close
    abort(abort_message)
  end
end  