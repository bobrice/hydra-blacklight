require 'active_fedora'

# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
# this class will be renamed to Hydra::Datastream::ModsBasic in Hydra 5.0
module Hydra
  module Datastream
    class AccessConditions < ActiveFedora::NokogiriDatastream
	
	  set_terminology do |t|
	    t.root(:path=>"schema")
            t.object(:path=>"object") {
              t.digitalFormats(:path=>"digitalFormats",:attributes=>{:type=>"tif"}) {
                t.tif_rule_150(:path=>"rule",:attributes=>{:type=>"150"}) {
                  t.tif_code_150(:path=>{:attribute=>"code"})
		}
              }    
            }		    
	  end
    end
  end
end
