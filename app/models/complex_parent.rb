require "active-fedora"
class ComplexParent < ActiveFedora::Base
#class ComplexParent < AbstractYaleObject
  #ERJ, below for reference 
  #include ::ActiveFedora::DatastreamCollections
  #include ::ActiveFedora::Relationships
  
  belongs_to :collection, :property=> :is_member_of
  
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
  delegate :oidpointer, :to=>"propertyMetadata", :unique=>true
  delegate :server, :to=>"propertyMetadata",:unique=>true

  def to_solr(solr_doc=Hash.new)
    super(solr_doc)
    solr_doc['state_ssi'] = state
    solr_doc
  end 
  #ERJ, has datastream (from::ActiveFedora::DatastreamCollections)  not used, params not propagated to fedora 
  #has_datastream :name => 'tif', :type=>ActiveFedora::Datastream,:mimeType=>"image/tiff", :controlGroup=>'M',:checksumType=>'MD5'
  #has_datastream :name => 'jpg', :type=>ActiveFedora::Datastream,:mimeType=>"image/jpg", :controlGroup=>'M',:checksumType=>'MD5'
  #has_datastream :name => 'jp2', :type=>ActiveFedora::Datastream,:mimeType=>"image/jp2", :controlGroup=>'M',:checksumType=>'MD5'
  
  #ERJ, below for reference  
  #has_metadata :name => 'propertyMetadata', :type => ActiveFedora::MetadataDatastream do |m|
  #  m.field 'title', :string
  #end	
end
