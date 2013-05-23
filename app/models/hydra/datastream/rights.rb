require 'active_fedora'

# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
# this class will be renamed to Hydra::Datastream::ModsBasic in Hydra 5.0
module Hydra
  module Datastream
    class Rights < ActiveFedora::NokogiriDatastream
    end
  end
end