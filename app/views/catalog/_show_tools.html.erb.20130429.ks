<%-
  # Compare with render_document_functions_partial helper, and
  # _document_functions partial. BL actually has two groups
  # of document-related tools. "document functions" by default
  # contains Bookmark functionality shown on both results and
  # item view. While "document tools" contains external export type
  # functions by default only on detail.

  #Added Bootstrap class well and 'hidden-phone' for the tools-bar 
-%>
  <ul class="nav nav-list">
      <li class="nav-header"><%= t('blacklight.tools.title') %></li>
      <li>
        <%= render_show_doc_actions @document %>
      </li>
      <% if (@document.respond_to?(:export_as_mla_citation_txt) || @document.respond_to?(:export_as_apa_citation_txt)) %>
        <li class="cite">
         <%= link_to t('blacklight.tools.cite'), citation_catalog_path(:id => @document), {:id => 'citeLink', :name => 'citation', :class => 'lightboxLink'} %>
        </li>
      <% end %>
      <% if @document.export_formats.keys.include?( :refworks_marc_txt ) %>
        <li class="refworks">
        <%= link_to t('blacklight.tools.refworks'), refworks_export_url(:id => @document)  %>        
        </li>
     <% end %>
     <% if @document.export_formats.keys.include?( :endnote ) %>
      <li class="endnote">
      <%= link_to t('blacklight.tools.endnote'), catalog_path(@document, :format => 'endnote') %>
      </li>
    <% end %>
    <% if @document.respond_to?( :to_email_text ) %>
      <li class="email">
      <%= link_to t('blacklight.tools.email'), email_catalog_path(:id => @document), {:id => 'emailLink', :name => 'email', :class => 'lightboxLink'} %>
      </li>
    <%- end -%>
    
    <% if @document.respond_to?(:to_marc) %>
      <li class="librarian_view">
        <%= link_to t('blacklight.tools.librarian_view'), librarian_view_catalog_path(@document), {:id => 'librarianLink', :name => 'librarian_view', :class => 'lightboxLink'} %>
      </li>
    <% end %>
  </ul>
