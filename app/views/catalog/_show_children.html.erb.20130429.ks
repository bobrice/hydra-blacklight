      <% # header bar for doc items in index view -%>
      <div class="documentHeader clearfix">

        <% # main title container for doc partial view -%>
	<% if @docs1 != nil && @docs1.length < 10 then @docs1.each do |value|    %>

		<%= link_to image_tag(@url1 + value.to_s  + @url2 , :height => '128', :width => '128'), @url1 + value.to_s  + @url2 %>

	<% end end %>

        <%= link_to "Show Page View", "http://libserver5.yale.edu:3000/bookreader/BookReaderDemo/index.html?oid=" + document[:oid_i].to_s %>

      </div>




