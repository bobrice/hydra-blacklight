require Rails.root.join('config/environment.rb')
namespace :yulhy do
  desc "test using yml"
  task :test_yaml do
    lbconf = YAML.load_file ('config/ladybird.yml')
    puts lbconf.fetch("username").strip
    puts lbconf.fetch("password").strip
    puts lbconf.fetch("host").strip
    puts lbconf.fetch("database").strip
  end
  desc "test db connection"
  task :test_db do
    lbconf = YAML.load_file ('config/ladybird_pamoja_test.yml')
        lbuser = lbconf.fetch("username").strip
        lbpw = lbconf.fetch("password").strip
		#lbpw = "QPl478(^%"
        lbhost = lbconf.fetch("host").strip
        lbdb = lbconf.fetch("database").strip
		#lbdb = "pamoja_hydra"
        puts "using db:"+lbdb
		puts "user:"+lbuser
		puts "pww:"+lbpw
		puts "lbhost:"+lbhost

		@@client = TinyTds::Client.new(:username => lbuser,:password => lbpw,:host => lbhost,:database => lbdb)

    puts "client connection to db OK? #{@@client.active?}"
    if @@client.active? == false
      abort("TASK ABORTED: client1 could not connect to db")
    end
        sqlstmt = %Q/select contentModel from dbo.hydra_content_model/
        result = @@client.execute(sqlstmt)
        result.each do |i|
            puts "CM:"+ i["contentModel"]
        end
  end

end