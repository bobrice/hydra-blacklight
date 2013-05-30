#http://viget.com/extend/protip-passing-parameters-to-your-rake-tasks
#https://github.com/rails-sqlserver/tiny_tds
#TODO after code4lib
#https://github.com/projecthydra/active_fedora/wiki/Getting-Started:-Console-Tour
#rack security update
require Rails.root.join('config/environment.rb')
namespace :yulhy do
  desc "add collection from fedora"
  task :add_collection, :cid, :pid, :title do |t, args|
    args.with_defaults(:cid => "13", :pid => "25",:title=>"Hydra Test")
	cid = args[:cid]
	pid = args[:pid]
	title = args[:title]
    puts "  cid: #{cid}"
    puts "  pid: #{pid}"
    puts "  title: #{title}"
	puts ""
	puts "WARNING you are about to add a collection object to fedora/solr!  Continue?(y/n)"
	yorn = STDIN.gets.chomp
	if yorn == "y"
	  puts "You said yes, here we go."
          obj = Collection.new
          obj.label = title
          obj.cid = cid
          obj.projid = pid
          obj.title = title
	  obj.save
          puts obj.pid
	elsif yorn == "n"
	  puts "You said no, exiting."
	elsif yorn == ""
      puts "no entered nothing, exiting, please try again."	
	else
      puts %Q/You entered '#{yorn}', exiting, try again with a 'y' or 'n'/
    end	  
    #ActiveFedora::Base.find("hydrangea:fixture_mods_article1").delete
  end
=begin
  desc "test solr"
  task :test_solr do
    #include Blacklight::SolrHelper
    cid = 2
    pid = 1
    puts get_coll_pid(cid,pid)
    #query = "cid_i:"+cid.to_s+" && projid_i:"+pid.to_s
    #blacklight_solr_config = Blacklight.solr_config
    #puts query
    #puts blacklight_solr_config
    #blacklight_solr = RSolr.connect(blacklight_solr_config)
    #response = blacklight_solr.get("select",:params=> {:fq => query,:fl =>"id"})
    #@solr_response = Blacklight::SolrResponse.new(force_to_utf8(response),{:fq => query,:fl => "id"})
    #id = @solr_response["response"]["docs"][0]["id"]
    #puts id
  end
  def get_coll_pid(cid,pid)
    query = "cid_i:"+cid.to_s+" && projid_i:"+pid.to_s+" && active_fedora_model_s:Collection"
    blacklight_solr_config = Blacklight.solr_config
    #puts query
    #puts blacklight_solr_config
    blacklight_solr = RSolr.connect(blacklight_solr_config)
    puts blacklight_solr.inspect
    response = blacklight_solr.get("select",:params=> {:fq => query,:fl =>"id"})
    #@solr_response = Blacklight::SolrResponse.new(force_to_utf8(response),{:fq => query,:fl => "id"})
    #puts "R:"+response["response"].inspect
    puts "No Collection found for cid:"+cid.to_s+" pid:"+pid.to_s if response["response"]["numFound"] == 0
    #puts "S:"+response["response"]["numFound"]
    id = response["response"]["docs"][0]["id"]
    id
  end
=end	  
end