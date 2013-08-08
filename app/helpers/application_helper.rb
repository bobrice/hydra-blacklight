module ApplicationHelper
	extend ActiveSupport::Concern
	include Blacklight::SearchFields
	include Blacklight::Configurable

	require 'net/http'
	#require 'NET/HTTP'

	def my_helper_method args
		args[:document][args[:field]].reverse
	end

	def cut_creator args
		@cut_creator = Array.new
		@cut_creator = args[:document][args[:field]]
		#@cut_creator = args[:value]
	end

    def get_oid_pointer args
        @oid_pointer = args[:document][args[:field]].to_s
        @pid_ptr_url = 'http://ladybird.library.yale.edu/service_hydraid.aspx?oid=' + @oid_pointer
        uri = URI(@pid_ptr_url)

        res = Net::HTTP.get_response(uri)
        @pid = res.body.to_s

    end
	#def render_document_show_field_value args
 	#	value = args[:value]
 	#	value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
 	#	return value.map { |v| html_escape v }.join "" if value.is_a? Array
 	#	html_escape value
 	#end
end
