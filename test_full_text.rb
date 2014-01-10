require '/home/ermadmix/hy_projs/diggit-hydra/config/environment.rb'

#reader = PDF::Reader.new("/home/ermadmix/akubra-hdfs-abstract.pdf")

#pdf_string = ""
#reader.pages.each do |page|
#  pdf_string = pdf_string + page.to_s
#end
#puts reader.pages[0].to_s
#puts pdf_string

obj = PdfObject.new
file = File.new("/home/ermadmix/akubra-hdfs-abstract.pdf")
obj.add_file_datastream(file,:dsid=>'pdf',:mimeType=>'application/pdf',:controlGroup=>'M',:checksumType=>'MD5',:type=>Hydra::Datastream::PdfDatastream)
obj.save
puts obj.pid
