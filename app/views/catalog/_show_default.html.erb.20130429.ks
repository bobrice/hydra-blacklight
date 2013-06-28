<%# default partial to display solr document fields in catalog show view -%>
<dl class="dl-horizontal  dl-invert">

  <% document_show_fields.each do |solr_fname, field| -%>
    <% if should_render_show_field? document, field %>
            <dt class="blacklight-<%= solr_fname.parameterize %>"><%= render_document_show_field_label :field => solr_fname %></dt>
            <dd class="blacklight-<%= solr_fname.parameterize %>"><%= render_document_show_field_value :document => document, :field => solr_fname %></dd>

    <% end -%>
  <% end -%>
<% if @docs != nil then end%> 

	<%= if document[:active_fedora_model_s].to_s.eql? '["ComplexParent"]' then render :partial => 'show_children', :locals => {:document => document} else  render :partial => 'show_simple_object', :locals => {:document => document} end %>

</dl>
