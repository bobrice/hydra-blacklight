      <% # header bar for doc items in index view -%>
      <div class="documentHeader clearfix">

        <% # main title container for doc partial view -%>

             <%= link_to image_tag(@url1 + document[:id].to_s  + @url2 , :height => '128', :width => '128'), @url1 + document[:id].to_s  + @url2 %>

      </div>




