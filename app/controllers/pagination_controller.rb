class PaginationController < ApplicationController

  include Blacklight::Catalog

  def index
    oid = params[:oid]
    zi = params[:zi]

    if oid==nil || zi==nil
      render :text => "missing parameters"
      return
    end  

    element = (zi.to_i - 1)
    #So, I got the parent. How do I know that the zindex returned pid is active?
    #Need to add to response: :sort =>"zindex_isi asc", :start =>zi, :rows =>1
    #Need to add to query: state_ssi:A
    #Take away zindex_isi (dont need). Plug query in solr to test
    #query = "parentoid_isi:"+oid+" && zindex_isi:"+zi
    query = "parentoid_isi:"+oid+" && state_ssi:A"
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl => "id", :start => element.to_s, :sort => "zindex_isi asc", :rows => 1});
    render :json => @solr_response.response
    return
  end

  def numofpages
    oid = params[:oid]
    if oid==nil
      render :text => "missing parameter"
      return
    end
    #query = "oid_isi:"+oid+ " && state_ssi:A"
    query = "parentoid_isi:"+oid+" && state_ssi:A"
    @solr_response = find(blacklight_config.qt,{:fq => query,:fl =>"ztotal_isi"});
    json_response = @solr_response.response
    @numFound = json_response['numFound']
    render :json => @numFound.to_s
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

  def getrailsenv
    if Rails.env.to_s == 'development' then
      #render :text => "http://imageserver.library.yale.edu/libserver7.yale.edu:8082/"
      render :text => "http://imageserver.library.yale.edu/"
    elsif Rails.env.to_s == 'test' then
      render :text => "http://imageserver.library.yale.edu/libserver7.yale.edu:8082/"
    else
      render :text => "http://imageserver.library.yale.edu/"
    end
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

end
