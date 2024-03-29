require "active-fedora"
class ComplexChild < ActiveFedora::Base
  belongs_to :complex_parent, :property=> :is_member_of
  
  has_metadata :name => 'descMetadata', :type => Hydra::Datastream::SimpleMods
  has_metadata :name => 'accessMetadata', :type => Hydra::Datastream::AccessConditions
  has_metadata :name => 'rightsMetadata', :type => Hydra::Datastream::Rights
  has_metadata :name => 'propertyMetadata', :type => Hydra::Datastream::Properties
  
  delegate :oid, :to=>"propertyMetadata", :unique=>true
  delegate :projid, :to=>"propertyMetadata", :unique=>true
  delegate :cid, :to=>"propertyMetadata", :unique=>true
  delegate :zindex, :to=>"propertyMetadata", :unique=>true
  delegate :parentoid, :to=>"propertyMetadata", :unique=>true
  delegate :ztotal, :to=>"propertyMetadata", :unique=>true
  delegate :server, :to=>"propertyMetadata",:unique=>true 

  def to_solr(solr_doc=Hash.new)
    super(solr_doc)
    solr_doc['state_ssi'] = state
    solr_doc
  end

end
