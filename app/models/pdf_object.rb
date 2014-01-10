require "active-fedora"
class PdfObject < ActiveFedora::Base
  
  has_metadata :name => 'pdf', :type => Hydra::Datastream::PdfDatastream

  def to_solr(solr_doc=Hash.new)
    super(solr_doc)
    #solr_doc['state_ssi'] = state
    solr_doc
  end

end
