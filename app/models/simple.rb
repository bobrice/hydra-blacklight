require "active-fedora"
class Simple < ActiveFedora::Base
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

end
