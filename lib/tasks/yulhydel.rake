#http://viget.com/extend/protip-passing-parameters-to-your-rake-tasks
#https://github.com/rails-sqlserver/tiny_tds
#TODO after code4lib
#https://github.com/projecthydra/active_fedora/wiki/Getting-Started:-Console-Tour
#rack security update
require Rails.root.join('config/environment.rb')
namespace :yulhy do
  desc "refresh hydra_publish and hydra_publish_error tables for testing"
  task :hydra_publish_refresh do
	lbconf = YAML.load_file ('config/ladybird_pamoja_test.yml')
	lbuser = lbconf.fetch("username").strip
	lbpw = lbconf.fetch("password").strip
	lbhost = lbconf.fetch("host").strip
	lbdb = lbconf.fetch("database").strip
	puts "using db:"+lbdb
	@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)
    
    puts "connection to db OK? #{@@client.active?}"
    if @@client.active? == false
      abort("TASK ABORTED: could not connect to db")
    end
	puts %Q/update dbo.hydra_publish set dateHydraStart=null,dateHydraEnd=null,hydraId=null/
    update = @@client.execute(%Q/update dbo.hydra_publish set dateHydraStart=null,dateHydraEnd=null,hydraId=null/)
    puts "affected_rows " + update.do.to_s
    puts %Q/delete from dbo.hydra_publish_error/
    update = @@client.execute(%Q/delete from dbo.hydra_publish_error/)
    puts "affected_rows " + update.do.to_s
	@@client.close
  end
  
  desc "delete objects from fedora"
  task :delete_fedora, :ns, :start, :end do |t, args|
    args.with_defaults(:ns => "changeme", :start => "1",:end=>"1")
	ns = args[:ns]
	start = args[:start]
	finish = args[:end]
    puts "  namespace: #{ns}"
    puts "  firstpid: #{start}"
	puts "  lastpid: #{finish}"
	puts ""
	puts "WARNING you are about to delete from fedora and solr!  Continue?(y/n)"
	yorn = STDIN.gets.chomp
	if yorn == "y"
	  puts "You said yes, here we go with the delete."
	  cnt = start
	  for cnt in start..finish 
        pid = ns+":"+cnt
        #puts pid
		begin
		  result = ActiveFedora::Base.find(pid).delete
		  #puts result
		  puts "DELETED #{pid}"
		rescue
		  puts "SKIPPING #{pid}"
		end  
	  end
	elsif yorn == "n"
	  puts "You said no, exiting."
	elsif yorn == ""
      puts "no entered nothing, exiting, please try again."	
	else
      puts %Q/You entered '#{yorn}', exiting, try again with a 'y' or 'n'/
    end	  
    #ActiveFedora::Base.find("hydrangea:fixture_mods_article1").delete
  end	  
end