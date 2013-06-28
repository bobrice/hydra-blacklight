<%# default partial to display solr document fields in catalog index view -%>
<dl class="dl-horizontal dl-invert">

  <% index_fields.each do |solr_fname, field| -%>
    <% if should_render_index_field? document, field %>
            <dt class="blacklight-<%= solr_fname.parameterize %>"><%= render_index_field_label :field => solr_fname %></dt>
            <dd class="blacklight-<%= solr_fname.parameterize %>"><%= render_index_field_value :document => document, :field => solr_fname %></dd>
    <% end -%>
  <% end -%>

<%= if document[:active_fedora_model_s].to_s.eql? '["ComplexParent"]' then else image_tag @url1 +  document[:id].to_s + @url2, :height => '128', :width => '128' end %>

</dl>
