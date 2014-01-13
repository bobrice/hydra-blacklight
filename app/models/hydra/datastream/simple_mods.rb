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
                  t.o_i_dateOtherType(:path=>"dateOther/@type")
		  t.o_i_dateOther(:path=>"dateOther")
		  t.o_i_copyrightDate(:path=>"copyrightDate")
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
		t.note_purpose(:path=>"note",:attributes=>{:type=>"purpose",:displayLabel=>"Purpose"})
				
		t.abstract(:path=>"abstract")
                t.genre(:path=>"genre",:attributes=>{:authority=>:none,:displayLabel=>:none})
                t.yale_genre(:path=>"genre",:attributes=>{:authority=>"yale",:displayLabel=>"Content Type"})
		t.type_of_resource(:path=>"typeOfResource")
		t.location(:path=>"location") {
		  t.phys_loc_yale(:path=>"physicalLocation",:attributes=>{:displayLabel=>"Yale Collection"})
		  t.phys_loc_origin(:path=>"physicalLocation",:attributes=>{:displayLabel=>"Collection of Origin"})
		  t.digital_collection(:path=>"physicalLocation",:attributes=>{:displayLabel=>"Digital Collection"})
		}  
		t.access_condition(:path=>"accessCondition",:attributes=>{:type=>"useAndReproduction"})
		#
		t.access_condition_restrictions(:path=>"accessCondition",:attributes=>{:type=>"restrictionsOnAccess"})
		
		#
		t.classification(:path=>"classification")
		
		t.nameRole(:path=>"name/@displayLabel")
                t.name(:path=>"name") {
		  t.namePart(:path=>"namePart") 
		  #below a test of using TerminologyBasedSolrizer, ERJ prefer to use extract to fine tune this in the model
		  #t.namePart(:path=>"namePart",:index_as=>[:searchable,:displayable]) 
		}
		
        #t.title_info(:path=>"titleInfo") {
        #  t.main_title(:path=>"title",:attributes=>{:type=>:none})
	#	  t.alt_title(:path=>"title",:attributes=>{:type=>"alternative"})
        #}
        t.title_info(:path=>"titleInfo",:attributes=>{:type=>:none}) {
          t.main_title(:path=>"title") 
        }
        t.alt_title_info(:path=>"titleInfo",:attributes=>{:type=>"alternative"}) {
          t.alt_title(:path=>"title")
        }       
        t.isbn(:path=>"identifier",:attributes=>{:type=>"isbn"}) 
        #
		t.issn(:path=>"identifier",:attributes=>{:type=>"issn"})
		
        t.subject(:path=>"subject",:attributes=>{:displayLabel=>:none}) {
          t.topic(:path=>"topic")
		  #
		  t.keyDate(:path=>"temporal",:attributes=>{:keyDate=>"yes"})
                  t.s_nameRole(:path=>"name/@displayLabel")
		  t.s_name(:path=>"name") {
		    t.s_namePart(:path=>"namePart")
		  }
                  t.s_geo_nameRole(:path=>"geographic/@displayLabel")
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

          def formatMapping(typeOfResource)
            mapped = Array.new
            typeOfResource.each { |r| 
              mapped.push("Text") if r=="text"
              mapped.push("Map") if r=="cartographic"
              mapped.push("Notated Music") if r=="notated music"
              mapped.push("Audio") if r=="sound recording"
              mapped.push("Audio") if r=="sound recording-musical"
              mapped.push("Audio") if r=="sound recording-nonmusical"
              mapped.push("Image") if r=="still image"
              mapped.push("Video") if r=="moving image"
              mapped.push("Physical Object") if r=="three dimensional object"
              mapped.push("Software") if r=="software, multimedia"
              mapped.push("Mixed Material") if r=="mixed material"
              mapped.push("Dataset") if r=="dataset"
            }
            mapped
           end  


           def appendAttr(elementVal,attrVal)
             iter = 0
             field = Array.new
             elementVal.each { |element|
               unless attrVal[iter].nil?
                 if attrVal[iter] != "none"
                   field.push(element + "  [" + attrVal[iter] + "]")
                 end
                 iter += 1
               end
             }
             field
           end

           def dontAppendAttr(elementVal,attrVal)
             iter = 0 
             field = Array.new
             elementVal.each { |element|
               unless attrVal[iter].nil?
                 if attrVal[iter] != "none"
                   field.push(element)
                 end
                 iter += 1
               end           
             }
             field
           end

           def whenAttrNone(elementVal,attrVal)
             iter = 0
             field = Array.new
             elementVal.each { |element|
               unless attrVal[iter].nil?
                 if attrVal[iter] == "none"
                   field.push(element)
                 end
                 iter += 1
               end
             }
             field
           end

           def whenAttrAuthor(elementVal,attrVal)
             iter = 0
             field = Array.new
             elementVal.each { |element|
               unless attrVal[iter].nil?
                 if attrVal[iter] == "Author"
                   field.push(element)
                 end
                 iter += 1
               end
             }
             field
           end

           def unescapeChars(array)
             unescaped = array.map { |s| s.gsub(/&amp;/,'&').gsub(/&lt;/,'<').gsub(/&gt;/,'>').gsub(/&apos;/,'\'').gsub(/&quot;/,'"') }
             unescaped
           end
           def unescapeCharsStr(str)
             unescaped = str.gsub(/&amp;/,'&').gsub(/&lt;/,'<').gsub(/&gt;/,'>').gsub(/&apos;/,'\'').gsub(/&quot;/,'"')
             unescaped
           end  


	  def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        #solr_doc['call_number_ssim'] = [classification,x].flatten 
		#sim = facet not stored (only use if index/stored is text, not string (unless blacklight is using descriptors, then sim is required)
		solr_doc['call_number_ssim'] = unescapeChars(mods.classification)
		solr_doc['accession_number_ssim'] = unescapeChars(mods.accession_number)
		solr_doc['box_number_ssm'] = unescapeChars(mods.related_item.part.detail_box.caption_box) 
		solr_doc['caption_folder_ssm'] = unescapeChars(mods.related_item.part.detail_folder.caption_folder)
		solr_doc['source_creator_tsim'] = unescapeChars(mods.related_item_host.r_i_h_name.r_i_h_namePart)

                solr_doc['creator_tsim'] = unescapeChars([whenAttrAuthor(mods.name.namePart,mods.nameRole),whenAttrNone(mods.name.namePart,mods.nameRole)].flatten)
                solr_doc['creator_sim'] = unescapeChars([mods.related_item_host.r_i_h_name.r_i_h_namePart,whenAttrAuthor(mods.name.namePart,mods.nameRole),whenAttrNone(mods.name.namePart,mods.nameRole)].flatten)
                solr_doc['assoc_names_tsim'] = unescapeChars([appendAttr(mods.name.namePart,mods.nameRole),appendAttr(mods.subject.s_name.s_namePart,mods.subject.s_nameRole)].flatten)
                solr_doc['assoc_names_sim'] = unescapeChars([appendAttr(mods.name.namePart,mods.nameRole),appendAttr(mods.subject.s_name.s_namePart,mods.subject.s_nameRole)].flatten)                 

		solr_doc['source_title_tsim'] = unescapeChars([mods.related_item_host.r_i_h_title_info.r_i_h_title].flatten)
		solr_doc['source_created_tsim'] = unescapeChars([mods.related_item_host.r_i_h_originInfo.r_i_h_place,mods.related_item_host.r_i_h_originInfo.r_i_h_publisher,mods.related_item_host.r_i_h_originInfo.r_i_h_dateIssued].flatten)
		solr_doc['source_edition_tsim'] = unescapeChars(mods.related_item_host.r_i_h_originInfo.r_i_h_edition)
		solr_doc['source_note_tsim'] = unescapeChars(mods.related_item_host.r_i_h_note)
		solr_doc['title_tsim'] = unescapeChars(mods.title_info.main_title)
		solr_doc['variant_titles_tsim'] = unescapeChars(mods.alt_title_info.alt_title)
		solr_doc['caption_ssim'] = unescapeChars(mods.display_label)
		solr_doc['edition_ssim'] = unescapeChars(mods.origin_info.o_i_edition)
		solr_doc['publishedCreated_ssim'] = unescapeChars([mods.origin_info.o_i_place,mods.origin_info.o_i_publisher,mods.origin_info.o_i_dateCreated].flatten)
		
                solr_doc['date_sim'] = unescapeChars([mods.origin_info.o_i_dateCreated,whenAttrNone(mods.origin_info.o_i_dateOther,mods.origin_info.o_i_dateOtherType)].flatten) 
		
                solr_doc['date_dtsi'] = unescapeChars(mods.origin_info.o_i_dateCreatedIso)
		solr_doc['date_depicted_ssim'] = unescapeChars(mods.subject.keyDate)
                solr_doc['date_depicted_sim'] = unescapeChars(mods.subject.keyDate)
		solr_doc['physical_description_ssim'] = unescapeChars(mods.physicalDescription.p_s_note)
		solr_doc['materials_ssim'] = unescapeChars(mods.physicalDescription.p_s_form)
		solr_doc['language_ssim'] = unescapeChars(mods.language.language_term)
                solr_doc['language_sim'] = unescapeChars(mods.language.language_term)
		solr_doc['language_of_cataloging_ssm'] = unescapeChars(mods.record_info.language_of_cataloging)
		solr_doc['notes_tsim'] = unescapeChars(mods.plain_note)
		solr_doc['abstract_tsim'] = unescapeChars(mods.abstract)
                solr_doc['subject_sim'] = unescapeChars([mods.subject.keyDate,whenAttrNone(mods.subject.s_name.s_namePart,mods.subject.s_nameRole),mods.subject.topic,whenAttrNone(mods.subject.s_geographic,mods.subject.s_geo_nameRole),mods.s_divinity].flatten)
		
                solr_doc['subject_name_tsim'] = unescapeChars(whenAttrNone(mods.subject.s_name.s_namePart,mods.subject.s_nameRole))
		solr_doc['subject_name_sim'] = unescapeChars(whenAttrNone(mods.subject.s_name.s_namePart,mods.subject.s_nameRole)) 
		
                solr_doc['subject_topic_tsim'] = unescapeChars(mods.subject.topic)
		solr_doc['subject_topic_sim'] = unescapeChars(mods.subject.topic)
		
                solr_doc['subject_geographic_tsim'] = unescapeChars(mods.subject.s_geographic)
		solr_doc['subject_geographic_sim'] = unescapeChars(mods.subject.s_geographic)
                solr_doc['subject_assoc_geo_tsim'] = unescapeChars(appendAttr(mods.subject.s_geographic,mods.subject.s_geo_nameRole))
                solr_doc['subject_assoc_geo_sim'] = unescapeChars(appendAttr(mods.subject.s_geographic,mods.subject.s_geo_nameRole))
		
                solr_doc['subject_geographic_code_ssim'] = unescapeChars(mods.subject.s_geographic_code)
		solr_doc['local_subject_tsim'] = unescapeChars(mods.s_divinity)
		solr_doc['period_style_tsim'] = unescapeChars(mods.s_style.topic)
		solr_doc['culture_tsim'] = unescapeChars(mods.s_culture.topic)
		solr_doc['scale_ssim'] = unescapeChars(mods.subject.s_cartographics.s_scale)
		solr_doc['projection_ssim'] = unescapeChars(mods.subject.s_cartographics.s_projection)
		solr_doc['coordinates_ssim'] = unescapeChars(mods.subject.s_cartographics.s_coordinates)
		solr_doc['genre_ssim'] = unescapeChars(mods.genre)
		solr_doc['format_ssim'] = unescapeChars(formatMapping(mods.type_of_resource))
                solr_doc['format_sim'] = unescapeChars(formatMapping(mods.type_of_resource))
                solr_doc['format_mods_ssim'] = unescapeChars(mods.type_of_resource)
                solr_doc['format_mods_sim'] = unescapeChars(mods.type_of_resource)  
		solr_doc['yale_collection_tsim'] = unescapeChars(mods.location.phys_loc_yale)
		solr_doc['musuem_repository_ssim'] = unescapeChars(mods.location.phys_loc_origin)
		solr_doc['digital_collection_ssim'] = unescapeChars(mods.location.digital_collection)
		solr_doc['digital_collection_sim'] = unescapeChars(mods.location.digital_collection)
		solr_doc['rights_ssm'] = unescapeChars(mods.access_condition)
		solr_doc['orbis_record_ssm'] = unescapeChars(mods.related_item.r_i_orbis)
		solr_doc['orbis_barcode_ssim'] = unescapeChars(mods.related_item.r_i_orbis_barcode)
		solr_doc['orbis_finding_aid_ssm'] = unescapeChars(mods.related_item.r_i_finding_aid)
		solr_doc['related_links_ssm'] = unescapeChars(mods.related_item.r_i_url)
		solr_doc['course_info_tsim'] = unescapeChars(mods.note_course_info)
		solr_doc['related_exhibit_tsim'] = unescapeChars(mods.note_related)
		solr_doc['job_number_ssim'] = unescapeChars(mods.note_job_number)
		solr_doc['note_citation_tsim'] = unescapeChars(mods.note_citation)
		solr_doc['series_tsim'] = unescapeChars(mods.related_item_series.r_i_s_titleInfo.r_i_s_title)
		solr_doc['isbn_ssim'] = unescapeChars(mods.isbn)
		solr_doc['issn_ssim'] = unescapeChars(mods.issn)
		solr_doc['access_restrictions_tsm'] = unescapeChars(mods.access_condition_restrictions)
		solr_doc['digital_ssim'] = unescapeChars(mods.note_digital)
		solr_doc['other_dates_ssim'] = unescapeChars(appendAttr(mods.origin_info.o_i_dateOther,mods.origin_info.o_i_dateOtherType))
                solr_doc['other_dates_sim'] = unescapeChars(appendAttr(mods.origin_info.o_i_dateOther,mods.origin_info.o_i_dateOtherType))
		solr_doc['tribe_tsim'] = unescapeChars(mods.s_tribe.topic)
		solr_doc['tribe_sim'] = unescapeChars(mods.s_tribe.topic)
		solr_doc['event_tsim'] = unescapeChars(mods.s_event.topic)
		solr_doc['event_sim'] = unescapeChars(mods.s_event.topic)
                solr_doc['yale_genre_ssim'] = unescapeChars(mods.yale_genre)
                solr_doc['yale_genre_sim'] = unescapeChars(mods.yale_genre)
                
                solr_doc['creator_sort_ssi'] = unescapeCharsStr(mods.name.namePart[0]) unless mods.name.namePart[0].nil?
                solr_doc['title_sort_ssi'] = unescapeCharsStr(mods.title_info.main_title[0]) unless mods.title_info.main_title[0].nil?
		solr_doc['copyright_tsim'] = unescapeChars(mods.origin_info.o_i_copyrightDate)
		solr_doc['purpose_tsim'] = unescapeChars(mods.note_purpose)
        solr_doc
      end	  
    end
  end
end
