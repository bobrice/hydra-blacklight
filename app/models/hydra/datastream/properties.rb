require 'active_fedora'

# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
# this class will be renamed to Hydra::Datastream::ModsBasic in Hydra 5.0
# reference
#   https://github.com/projecthydra/solrizer
#   https://github.com/projecthydra/om/blob/master/GETTING_STARTED.textile
#   https://github.com/projecthydra/om/blob/master/COMMON_OM_PATTERNS.textile
#   
module Hydra
  module Datastream
    class Properties < ActiveFedora::NokogiriDatastream       
      #include YUL:OM::XML::TerminologyBasedSolrizer   

	  #ERJ note ladybird pid = projid, ladybird _oid = parentoid	
      set_terminology do |t|
        t.root(:path=>"root")

		t.oid(:path=>"oid")
		t.cid(:path=>"cid")
		t.projid(:path=>"projid")
		t.zindex(:path=>"zindex")
		t.parentoid(:path=>"parentoid")
		t.ztotal(:path=>"ztotal")
		t.oidpointer(:path=>"oidpointer")
			
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
            xml.oidpointer			
		  end
		end.doc
	  end
	  
	  def extract_oid
        terms = {}
        self.find_by_terms(:oid).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "oid_i",term.text)		  
        end
        return terms
      end

	  def extract_cid
        terms = {}
        self.find_by_terms(:cid).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "cid_i",term.text)		  
        end
        return terms
      end
	  
	  def extract_projid
        terms = {}
        self.find_by_terms(:projid).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "projid_i",term.text)		  
        end
        return terms
      end
	  def extract_zindex
        terms = {}
        self.find_by_terms(:zindex).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "zindex_i",term.text)		  
        end
        return terms
      end
      def extract_parentoid
        terms = {}
        self.find_by_terms(:parentoid).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "parentoid_i",term.text)		  
        end
        return terms
      end

      def extract_ztotal
        terms = {}
        self.find_by_terms(:ztotal).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "ztotal_i",term.text)		  
        end
        return terms
      end

	  def extract_oidpointer
        terms = {}
        self.find_by_terms(:oidpointer).each do |term| 
          ::Solrizer::Extractor.insert_solr_field_value(terms, "oidpointer_i",term.text)		  
        end
        return terms
      end
	  
	  def to_solr(solr_doc=Hash.new)
        super(solr_doc)
	  	solr_doc.merge!(extract_oid)
	    solr_doc.merge!(extract_cid)
        solr_doc.merge!(extract_projid)
		solr_doc.merge!(extract_zindex)
		solr_doc.merge!(extract_parentoid)
		solr_doc.merge!(extract_ztotal)
		solr_doc.merge!(extract_oidpointer)
        solr_doc
      end

#ERJ testing with override of TerminologyBasedSolrizerMethod	  
=begin
      class << self
        def solrize_node(node_value, doc, term_pointer, term, solr_doc = Hash.new, field_mapper = nil, opts = {})
          return solr_doc unless term.index_as && !term.index_as.empty?
		  generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
		  create_and_insert_terms(generic_field_name_base, node_value, term.index_as, solr_doc)
		end
      end
=end	  
    end
  end
end
