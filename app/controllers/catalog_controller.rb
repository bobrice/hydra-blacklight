# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController
  include BlacklightGoogleAnalytics::ControllerExtraHead
  

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  #CatalogController.solr_search_params_logic += [:exclude_unwanted_models]


  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :rows => 10,
      :fq => 'active_fedora_model_ssim:ComplexParent || active_fedora_model_ssim:Simple'
    }


   #  config.default_solr_params = {
   #   :qt => 'search',
   #   :rows => 10,
   # }


    # solr field configuration for search results/index views
    config.index.show_link = 'title_tsim'
    config.index.record_tsim_type = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'title_tsim'
    config.show.heading = 'title_tsim'
    config.show.display_type = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field solr_name('format', :facetable), :label => 'Format'
    config.add_facet_field solr_name('date', :facetable), :label =>'Date'
    config.add_facet_field solr_name('language', :facetable), :label => 'Language', :limit => 10 
    config.add_facet_field solr_name('creator', :facetable), :label => 'Creator'  
    config.add_facet_field solr_name('subject', :facetable), :label => 'Subject', :limit => 20 
    # config.add_facet_field solr_name('subject_geographic', :facetable), :label => 'Region' 
    #config.add_facet_field solr_name('date_depicted', :facetable), :label => 'Era'  
    config.add_facet_field solr_name('digital_collection', :facetable), :label => 'Digital Collection', :limit => 20 

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'creator_tsim', :label => 'Creator:' 
    config.add_index_field 'publishedCreated_ssim', :label => 'Published/Created:'
    config.add_index_field 'oidpointer_isi', :label => 'oidpointer_isi', :helper_method => :get_oid_pointer
    config.add_index_field 'id', :label => 'PID:'
    # config.add_index_field solr_name('format', :symbol), :label => 'Format:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'oid_isi', :label => 'OID:' 
    config.add_show_field 'id', :label => 'PID:'
    config.add_show_field 'oidpointer_isi', :label => 'oid pointer:'
    config.add_show_field 'variant_titles_tsim', :label => 'Variant Titles:'
    config.add_show_field 'creator_tsim', :label => 'Creator:'
    config.add_show_field 'publishedCreated_ssim', :label => 'Published/Created:'
    config.add_show_field 'date_depicted_ssim', :label => 'Date Depicted:'
    config.add_show_field 'edition_ssim', :label => 'Edition:'
    config.add_show_field 'physical_description_ssim', :label => 'Physical Description:'
    config.add_show_field 'materials_ssim', :label => 'Materials:'
    config.add_show_field 'notes_tsim', :label => 'Notes:'
    config.add_show_field 'abstract_tsim', :label => 'Abstract:' 
    config.add_show_field 'subject_name_tsim', :label => 'Subjects:'
    config.add_show_field 'subject_topic_tsim', :label => 'Subjects:'
    config.add_show_field 'subject_geographic_tsim', :label => 'Subjects:'
    config.add_show_field 'local_subject_tsim', :label => 'Subjects:'
    config.add_show_field 'event_tsim', :label => 'Subjects:'
    config.add_show_field 'call_number_ssim', :label => 'Call Number:'
    config.add_show_field 'accession_number_ssim', :label => 'Accession Number:'
    config.add_show_field 'box_number_ssm', :label => 'Box number:'
    config.add_show_field 'caption_folder_ssm', :label => 'Folder Name:'
    config.add_show_field 'caption_ssim', :label => 'Caption:'
    config.add_show_field 'source_creator_tsim', :label => 'Source Creator:'
    config.add_show_field 'source_title_tsim', :label => 'Source Title:'
    config.add_show_field 'source_created_tsim', :label => 'Source Created:'
    config.add_show_field 'source_edition_tsim', :label => 'Source Edition:'
    config.add_show_field 'source_note_tsim', :label => 'Source Note:'
    config.add_show_field 'language_ssim', :label => 'Language:'
    config.add_show_field 'period_style_tsim', :label => 'Period/Style:'
    config.add_show_field 'culture_tsim', :label => 'Culture:'
    config.add_show_field 'scale_ssim', :label => 'Scale:'
    config.add_show_field 'projection_ssim', :label => 'Projection:'
    config.add_show_field 'coordinates_ssim', :label => 'Coordinates:'
    config.add_show_field 'genre_ssim', :label => 'Genre:'
    config.add_show_field 'format_ssim', :label => 'Format:'
    config.add_show_field 'yale_collection_tsim', :label => 'Yale Collection:'
    config.add_show_field 'musuem_repository_ssim', :label => 'Museum/Repository:'
    config.add_show_field 'rights_ssm', :label => 'Rights:'
    config.add_show_field 'orbis_record_ssm', :label => 'Orbis Record:'
    config.add_show_field 'orbis_barcode_ssim', :label => 'Orbis Barcode:'
    config.add_show_field 'orbis_finding_aid_ssm', :label => 'Finding Aid:'
    config.add_show_field 'related_links_ssm', :label => 'Related Links:'
    config.add_show_field 'related_exhibit_tsim', :label => 'Related Exhibit or Resource:'
    config.add_show_field 'note_citation_tsim', :label => 'Citation:'
    config.add_show_field 'series_tsim', :label => 'Series:'
    config.add_show_field 'isbn_ssim', :label => 'ISBN:'
    config.add_show_field 'issn_ssim', :label => 'ISSN:'
    config.add_show_field 'access_restrictions_tsim', :label => 'Access Restrictions:'
    config.add_show_field 'digital_ssim', :label => 'Digital:'
    config.add_show_field 'other_dates_ssim', :label => 'Other Dates:'
    config.add_show_field 'tribe_tsim', :label => 'Tribe:'
    config.add_show_field 'digital_collection_ssim', :label => 'Digital Collection:'
    config.add_show_field 'ztotal_isi', :label => 'Number of Pages:'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    config.add_search_field 'all_fields', :label => 'All Fields'
    

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
    
    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = { 
        :qf => '$author_qf',
        :pf => '$author_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    #config.add_sort_field 'score desc, date_dtsim desc, title_tsim asc', :label => 'relevance'
    #config.add_sort_field 'date_dtsim desc, title_tsim asc', :label => 'year'
    #config.add_sort_field 'title_tsim asc, date_dtsim desc', :label => 'title'
    #config.add_sort_field 'creator_tsim asc, title_tsim asc', :label => 'author'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end



end 
