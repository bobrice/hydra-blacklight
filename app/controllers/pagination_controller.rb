class PaginationController < ApplicationController

  include Blacklight::Catalog

  def index
    oid = params[:oid]
    zi = params[:zi]
    if oid==nil || zi==nil
      render :text => "missing parameters"
      return
    end  
    query = "parentoid_isi:"+oid+" && zindex_isi:"+zi
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl => "id"});
    render :json => @solr_response.response
    return
  end

  def numofpages
    oid = params[:oid]
    if oid==nil
      render :text => "missing parameter"
      return
    end
    query = "oid_isi:"+oid
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl =>"ztotal_isi"});
    render :json => @solr_response.response
    return
  end

  def gettitle
    @docs1 = Array.new
    oid = params[:oid]
    if oid==nil
      render :text => "missing parameter"
      return
    end
    query = "oid_isi:"+oid
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl =>"title_tsim"});
 
    json_response = @solr_response.response
    @numFound = json_response['numFound']
    if @numFound > 0
      @docs = json_response['docs']
    end

    if @docs != nil
        @docs.each do |i|
          @h1 = Hash[*i.flatten]
          @h1.each do |key,value|
            @docs1.push value
          end
        end
      end
    render :json => @docs1[0]
    #render :json => @solr_response.response
    #render :json => @solr_response.class
    #solr_response.docs.empty?
    return
  end

  def getparentpid
    oid = params[:oid]
    if oid==nil
      render :text => "missing parameter"
      return
    end
    query = "oid_isi:"+oid
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl =>"id"});
    render :json => @solr_response.response
    return
  end

  def turndirection
    oid = params[:oid]
    if oid==nil
      #render :text => "missing parameter"
    end
    #Will have solr query here for LTR or RTL direction. Will return json solr_response.
    render :text => oid
    return
  end

  def transcript
    oid = params[:oid]
    if oid==nil
      #render :text => "missing parameter"
    end
    #Will have solr query here for transcript. Will return json solr_response.
    render :text => "false";
    return
  end


  
  #def erjtest
  #  solr_doc_params
  #end

  #for reference
  #10590519
  #pid = "libserver7:3"
  #datatype = "text"
  #pid = solr_doc_params 
    ##{:id=>nil, :qt=>"document"}
  #@solr_reponse,@document = get_solr_response_for_doc_id(pid)
  #pid = erjtest

end
