require 'active_fedora'
   
module Hydra
  module Datastream
    class CollProperties < ActiveFedora::OmDatastream          

	  #ERJ note ladybird pid = projid, ladybird _oid = parentoid	
      set_terminology do |t|
        t.root(:path=>"root")

		t.oid(:path=>"oid")
		t.cid(:path=>"cid")
		t.projid(:path=>"projid")
		t.zindex(:path=>"zindex")
		t.parentoid(:path=>"parentoid")
		t.ztotal(:path=>"ztotal")
                t.title(:path=>"title")
			
	  end
	  
	  def self.xml_template
	    Nokogiri::XML::Builder.new do |xml|
          xml.root do
		    xml.oid
			xml.cid
			xml.projid
			xml.zindex
            xml.parentoid
            xml.ztotal
            xml.title			
		  end
		end.doc
	  end
	 
	  def to_solr(solr_doc=Hash.new)
        super(solr_doc)
	  	solr_doc['oid_isi'] = oid
		solr_doc['cid_isi'] = cid
		solr_doc['projid_isi'] = projid
		solr_doc['zindex_isi'] = parentoid
		solr_doc['ztotal_isi'] = ztotal
		solr_doc['title_ssi'] = title
        solr_doc
      end

	  
    end
  end
end
