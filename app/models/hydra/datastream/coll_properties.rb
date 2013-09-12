require 'active_fedora'
   
module Hydra
  module Datastream
    class CollProperties < ActiveFedora::OmDatastream          

	  #ERJ note ladybird pid = projid, ladybird _oid = parentoid	
      set_terminology do |t|
        t.root(:path=>"root")
                
                t.collection(:path=>"collection")
                t.project(:path=>"project")
		t.cid(:path=>"CID")
		t.projid(:path=>"PID")
                t.location1(:path=>"location")
        t.address(:path=>"address") {
          t.line1(:path=>"line1")
          t.line2.(:path=>"line2")
          t.city(:path=>"city")
          t.state(:path=>"state")
          t.zip(:path=>"zip")
        }
		t.phone(:path=>"phone")
		t.email(:path=>"email")
                t.url1(:path=>"URL")
                t.title(:path=>"title")
			
	  end
	 
	def to_solr(solr_doc=Hash.new)
          super(solr_doc)
	        solr_doc['collection_ssi'] = collection
                solr_doc['project_ssi'] = project
		solr_doc['cid_isi'] = cid
		solr_doc['projid_isi'] = projid
		solr_doc['location_ssi'] = location1
		solr_doc['line1_ssi'] = address.line1
                solr_doc['line2_ssi'] = address.line2
                solr_doc['city_ssi'] = address.city
                solr_doc['state_ssi'] = address.state
                solr_doc['zip_ssi'] = address.zip
                solr_doc['phone_ssi'] = phone
                solr_doc['email_ssi'] = email
                solr_doc['url_ssi'] = url1 
		solr_doc['title_ssi'] = title
        solr_doc
      end

	  
    end
  end
end
