require '/home/ermadmix/hy_projs/diggit-hydra/config/environment.rb'

obj = ComplexParent.new
#file = File.new('mods_service_full.xml')
#file = File.new('/home/ermadmix/10681633_metadata.xml')
#file = File.new('/home/ermadmix/mods.xml')
#file = File.new('/home/ermadmix/daymission.xml')
#file = File.new('/home/ermadmix/durandMetadata.xml')
file = File.new('/home/ermadmix/10733824_metadata.xml')
ng_xml = Nokogiri::XML::Document.parse(IO.read(file))
obj.descMetadata.ng_xml = ng_xml

file = File.new('/home/ermadmix/access_conditions.xml')
ng_xml = Nokogiri::XML::Document.parse(IO.read(file))
obj.accessMetadata.ng_xml = ng_xml

file = File.new('/home/ermadmix/rights.xml')
ng_xml = Nokogiri::XML::Document.parse(IO.read(file))
obj.rightsMetadata.ng_xml = ng_xml
#obj.add_relationship(:is_member_of,"info:fedora/changeme:74")
#obj.save
#puts obj.pid
obj.oid = "1234"
obj.cid = "2345"
obj.projid = "3456"
obj.zindex = "4567"
obj.parentoid = "5678"
obj.ztotal = "6789"
obj.oidpointer = "7890"

#obj.add_relationship(:is_member_of,"info:fedora/changeme:74")
#tiffile = File.new('/home/ermadmix/libshare/ladybird/project25/publish/BAG/10592589/data/4005429a.tif')
#jpgfile = File.new('/home/ermadmix/libshare/ladybird/project25/publish/DL/10592589/4005429a.jpg')
#jp2file = File.new('/home/ermadmix/libshare/ladybird/project25/publish/DL/10592589/4005429a.jp2')

#obj.add_file_datastream(tiffile,:dsid=>'tif',:mimeType=>"image/tiff", :controlGroup=>'M',:checksumType=>'MD5')
#obj.add_file_datastream(jpgfile,:dsid=>'jpg',:mimeType=>"image/jpg", :controlGroup=>'M',:checksumType=>'MD5')
#obj.add_file_datastream(jp2file,:dsid=>'jp2',:mimeType=>"image/jp2", :controlGroup=>'M',:checksumType=>'MD5')


#obj.add_file_datastream(jpgfile,:dsid=>'jpg',:label=>'jpg oid',:mimeType=>"image/jpg", :controlGroup=>'M',:checksumType=>'MD5',:checksum=>'b607a3cdd700a3148b5cbeb83ef39711')

#obj.save

#ds = obj.create_datastream('ActiveFedora::Datastream','tif',:mimeType=>'image/tiff',:controlGroup=>'M',:dsLabel=>'TIFF oid #',:dsLocation=>'http://lbfiles.library.yale.edu/10590509.tif')
#obj.add_datastream(ds)
#ds = obj.create_datastream('ActiveFedora::Datastream','jpg',:mimeType=>'image/jpg',:controlGroup=>'M',:dsLabel=>'JPG oid #',:dsLocation=>'http://lbfiles.library.yale.edu/10590509.jpg')
#obj.add_datastream(ds)
#ds = obj.create_datastream('ActiveFedora::Datastream','jp2',:mimeType=>'image/jp2',:controlGroup=>'M',:dsLabel=>'jp2 oid #',:dsLocation=>'http://lbfiles.library.yale.edu/10590509.jp2')
#obj.add_datastream(ds)

obj.save
puts obj.pid
