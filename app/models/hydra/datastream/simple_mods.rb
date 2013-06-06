require 'active_fedora'

# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
# this class will be renamed to Hydra::Datastream::ModsBasic in Hydra 5.0
# reference
#   https://github.com/projecthydra/solrizer
#   https://github.com/projecthydra/om/blob/master/GETTING_STARTED.textile
#   https://github.com/projecthydra/om/blob/master/COMMON_OM_PATTERNS.textile
#   
#   https://github.com/projecthydra/solrizer/blob/master/lib/solrizer/default_descriptors.rb
module Hydra
  module Datastream
    class SimpleMods < ActiveFedora::OmDatastream       
      #include YUL:OM::XML::TerminologyBasedSolrizer
	  yul_sim = Solrizer::Descriptor.new(:string,:indexed,:multivalued)
      set_terminology do |t|
        t.root(:path=>"mods", :xmlns=>"http://www.loc.gov/mods/v3", :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

		
		t.accession_number(:path=>"identifier",:attributes=>{:displayLabel=>"Accession number"})
		t.related_item(:path=>"relatedItem",:attributes=>{:type=>:none}) {
		  t.part(:path=>"part") {
		    t.detail_box(:path=>"detail",:attributes=>{:type=>"box"}) {
			  t.caption_box(:path=>"caption")
			}
			t.detail_folder(:path=>"detail",:attributes=>{:type=>"folder"}) {
			  t.caption_folder(:path=>"caption")
			}
		  }
		  t.r_i_orbis(:path=>"identifier",:attributes=>{:displayLabel=>"Link to Orbis record"})
		  t.r_i_orbis_barcode(:path=>"identifier",:attributes=>{:displayLabel=>"Orbis barcode"})
		  t.r_i_finding_aid(:path=>"identifier",:attributes=>{:displayLabel=>"Link to Finding Aid"})
		  t.r_i_url(:path=>"url")
		}
		t.related_item_series(:path=>"relatedItem",:attributes=>{:type=>"series"}) {
		  t.r_i_s_titleInfo(:path=>"titleInfo") {
		    t.r_i_s_title(:path=>"title")
		  }
		}  
		t.related_item_host(:path=>"relatedItem",:attributes=>{:type=>"host"}) {
		  t.r_i_h_name(:path=>"name") {
		    t.r_i_h_namePart(:path=>"namePart")
		  }
          t.r_i_h_title_info(:path=>"titleInfo") {
            t.r_i_h_title(:path=>"title") 
          }
          t.r_i_h_originInfo(:path=>"originInfo") {
            t.r_i_h_place(:path=>"place")
            t.r_i_h_publisher(:path=>"publisher")
            t.r_i_h_dateIssued(:path=>"dateIssued")
            t.r_i_h_edition(:path=>"edition")
          }
          t.r_i_h_note(:path=>"note")
        }
		t.origin_info(:path=>"originInfo") {
		  t.o_i_edition(:path=>"edition") 
		  t.o_i_place(:path=>"place")
		  t.o_i_publisher(:path=>"publisher")
		  t.o_i_dateCreated(:path=>"dateCreated",:attributes=>{:keyDate=>"yes",:encoding=>:none})
		  t.o_i_dateCreatedIso(:path=>"dateCreated",:attributes=>{:keyDate=>"yes",:encoding=>"iso8601"})
		  t.o_i_dateOther(:path=>"dateOther")
		}
		t.physicalDescription(:path=>"physicalDescription"){
		  t.p_s_note(:path=>"note")
		  t.p_s_form(:path=>"form",:attributes=>{:type=>"material"})
		}
		t.language(:path=>"language") {
		  t.language_term(:path=>"languageTerm",:attributes=>{:type=>"code",:authority=>"iso639-2b"})
		}
		t.record_info(:path=>"recordInfo") {
		  t.language_of_cataloging(:path=>"languageOfCataloging")
		}
		#t.plain_note(:path=>"note",:attributes=>{:type=>:none})
		t.plain_note(:path=>"note",:attributes=>{:displayLabel=>:none})
		#
		t.note_course_info(:path=>"note",:attributes=>{:displayLabel=>"Course Info"})
		t.note_related(:path=>"note",:attributes=>{:displayLabel=>"Related Exhibit or Resource"})
		t.note_job_number(:path=>"note",:attributes=>{:displayLabel=>"Job Number"})
		t.note_citation(:path=>"note",:attributes=>{:displayLabel=>"Citation"})
		#
		t.note_digital(:path=>"note",:attributes=>{:displayLabel=>"Digital"})
				
		t.abstract(:path=>"abstract")
		t.genre(:path=>"genre")
		t.type_of_resource(:path=>"typeOfResource")
		t.location(:path=>"location") {
		  t.phys_loc_yale(:path=>"physicalLocation",:attributes=>{:displayLabel=>"Yale Collection"})
		  t.phys_loc_origin(:path=>"physicalLocation",:attributes=>{:displayLabel=>"Collection of Origin"})
		}  
		t.access_condition(:path=>"accessCondition",:attributes=>{:type=>"useAndReproduction"})
		#
		t.access_condition_restrictions(:path=>"accessCondition",:attributes=>{:type=>"restrictionsOnAccess"})
		
		#
		t.classification(:path=>"classification")
		
		t.name(:path=>"name") {
		  t.namePart(:path=>"namePart") 
		  #below a test of using TerminologyBasedSolrizer, ERJ prefer to use extract to fine tune this in the model
		  #t.namePart(:path=>"namePart",:index_as=>[:searchable,:displayable]) 
		}
		
        t.title_info(:path=>"titleInfo") {
          t.main_title(:path=>"title",:attributes=>{:type=>:none})
		  t.alt_title(:path=>"title",:attributes=>{:type=>"alternative"})
        }
        t.isbn(:path=>"identifier",:attributes=>{:type=>"isbn"}) 
        #
		t.issn(:path=>"identifier",:attributes=>{:type=>"issn"})
		
        t.subject(:path=>"subject",:attributes=>{:displayLabel=>:none}) {
          t.topic(:path=>"topic")
		  #
		  t.keyDate(:path=>"temporal",:attributes=>{:keyDate=>"yes"})
		  t.s_name(:path=>"name") {
		    t.s_namePart(:path=>"namePart")
		  }
		  t.s_geographic(:path=>"geographic")
		  t.s_geographic_code(:path=>"geographicCode")  
		  t.s_cartographics(:path=>"cartographics") {
		    t.s_scale(:path=>"scale")
			t.s_projection(:path=>"projection")
			t.s_coordinates(:path=>"coordinates")	
          }
		}
		t.s_style(:path=>"subject",:attributes=>{:displayLabel=>"Style"}) {
		  t.topic(:path=>"topic")
		}
		t.s_culture(:path=>"subject",:attributes=>{:displayLabel=>"Culture"}) {
		  t.topic(:path=>"topic")
		}
		#
		t.s_divinity(:path=>"subject",:attributes=>{:displayLabel=>"Divinity Subject"})
		t.s_tribe(:path=>"subject",:attributes=>{:displayLabel=>"Tribe"}) {
		  t.topic(:path=>"topic")
		}
        t.s_event(:path=>"subject",:attributes=>{:displayLabel=>"Event"}) {
		  t.topic(:path=>"topic")
        }		  
		t.display_label(:path=>"note",:attributes=>{:displayLabel=>"caption"})	
	  end

	  def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        #solr_doc['call_number_ssim'] = [classification,x].flatten 
		#sim = facet not stored (only use of index/stored is text, not string
		solr_doc['call_number_ssim'] = mods.classification
		solr_doc['accession_number_ssim'] = mods.accession_number
		solr_doc['box_number_ssm'] = mods.related_item.part.detail_box.caption_box 
		solr_doc['caption_folder_ssm'] = mods.related_item.part.detail_folder.caption_folder
		solr_doc['source_creator_tsim'] = mods.related_item_host.r_i_h_name.r_i_h_namePart#
		solr_doc['creator_tsim'] = mods.name.namePart
		solr_doc['creator_sim'] = [mods.related_item_host.r_i_h_name.r_i_h_namePart,mods.name.namePart].flatten
		solr_doc['source_title_tsim'] = [mods.related_item_host.r_i_h_title_info.r_i_h_title].flatten
		solr_doc['source_created_tsim'] = [mods.related_item_host.r_i_h_originInfo.r_i_h_place,mods.related_item_host.r_i_h_originInfo.r_i_h_publisher,mods.related_item_host.r_i_h_originInfo.r_i_h_dateIssued].flatten
		solr_doc['source_edition_tsim'] = mods.related_item_host.r_i_h_originInfo.r_i_h_edition
		solr_doc['source_note_tsim'] = mods.related_item_host.r_i_h_note
		solr_doc['title_tsim'] = mods.title_info.main_title
		solr_doc['variant_titles_tsim'] = mods.title_info.alt_title
		solr_doc['caption_ssim'] = mods.display_label
		solr_doc['edition_ssim'] = mods.origin_info.o_i_edition
		solr_doc['publishedCreated_ssim'] = [mods.origin_info.o_i_place,mods.origin_info.o_i_publisher,mods.origin_info.o_i_dateCreated].flatten
		solr_doc['date_sim'] = [mods.origin_info.o_i_dateCreated,mods.origin_info.o_i_dateOther].flatten
		solr_doc['date_dtsi'] = mods.origin_info.o_i_dateCreatedIso
		solr_doc['date_depicted_ssim'] = mods.subject.keyDate
                solr_doc['date_depicted_sim'] = mods.subject.keyDate
		solr_doc['physical_description_ssim'] = mods.physicalDescription.p_s_note
		solr_doc['materials_ssim'] = mods.physicalDescription.p_s_form
		solr_doc['language_ssim'] =	mods.language.language_term
		solr_doc['language_of_cataloging_ssm'] = mods.record_info.language_of_cataloging
		solr_doc['notes_tsim'] = mods.plain_note
		solr_doc['abstract_tsim'] = mods.abstract
		solr_doc['subject_sim'] = [mods.subject.keyDate,mods.subject.s_name.s_namePart,mods.subject.topic,mods.subject.s_geographic,mods.s_divinity].flatten
		solr_doc['subject_name_tsim'] = mods.subject.s_name.s_namePart
		solr_doc['subject_name_sim'] = mods.subject.s_name.s_namePart
		solr_doc['subject_topic_tsim'] = mods.subject.topic
		solr_doc['subject_topic_sim'] = mods.subject.topic
		solr_doc['subject_geographic_tsim'] = mods.subject.s_geographic
		solr_doc['subject_geographic_sim'] = mods.subject.s_geographic
		solr_doc['subject_geographic_code_ssim'] = mods.subject.s_geographic_code
		solr_doc['local_subject_tsim'] = mods.s_divinity
		solr_doc['period_style_tsim'] = mods.s_style.topic
		solr_doc['culture_tsim'] = mods.s_culture.topic
		solr_doc['scale_ssim'] = mods.subject.s_cartographics.s_scale
		solr_doc['projection_ssim'] = mods.subject.s_cartographics.s_projection
		solr_doc['coordinates_ssim'] = mods.subject.s_cartographics.s_coordinates
		solr_doc['genre_ssim'] = mods.genre
		solr_doc['format_ssim'] = mods.type_of_resource
                solr_doc['format_sim'] = mods.type_of_resource
		solr_doc['yale_collection_tsim'] = mods.location.phys_loc_yale
		solr_doc['musuem_repository_ssim'] = mods.location.phys_loc_origin
		solr_doc['rights_ssm'] = mods.access_condition
		solr_doc['orbis_record_ssm'] = mods.related_item.r_i_orbis
		solr_doc['orbis_barcode_ssim'] = mods.related_item.r_i_orbis_barcode
		solr_doc['orbis_finding_aid_ssm'] = mods.related_item.r_i_finding_aid
		solr_doc['related_links_ssm'] = mods.related_item.r_i_url
		solr_doc['course_info_tsim'] = mods.note_course_info
		solr_doc['related_exhibit_tsim'] = mods.note_related
		solr_doc['job_number_ssim'] = mods.note_job_number
		solr_doc['note_citation_tsim'] = mods.note_citation
		solr_doc['series_tsim'] = mods.related_item_series.r_i_s_titleInfo.r_i_s_title
		solr_doc['isbn_ssim'] = mods.isbn
		solr_doc['issn_ssim'] = mods.issn
		solr_doc['access_restrictions_tsm'] = mods.access_condition_restrictions
		solr_doc['digital_ssim'] = mods.note_digital
		solr_doc['other_dates_ssim'] = mods.origin_info.o_i_dateOther
		solr_doc['tribe_tsim'] = mods.s_tribe.topic
		solr_doc['tribe_sim'] = mods.s_tribe.topic
		solr_doc['event_tsim'] = mods.s_event.topic
		solr_doc['event_sim'] = mods.s_event.topic
        solr_doc
      end	  
    end
  end
end
