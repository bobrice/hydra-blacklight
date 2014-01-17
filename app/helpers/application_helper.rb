module ApplicationHelper

    require 'net/http'

    def my_helper_method args
        args[:document][args[:field]].reverse
    end

    def cut_creator args
        @cut_creator = Array.new
        @cut_creator = args[:document][args[:field]]
    end

    def get_oid_pointer args
        @oid_pointer = args[:document][args[:field]].to_s

        @pid = ""

        query = "oid_isi:"+ @oid_pointer + " && state_ssi:A"
        @solr_response = find(blacklight_config.qt,{:fq => query,:fl =>"id", :rows => 1});

        @pid_arr = @solr_response.response['docs']

        @pid_arr.each do |i|
        i.each do |key,value|
            @pid = value
           end
        end
        @pid

    end

    def find(*args)
        path = blacklight_config.solr_path
        response = blacklight_solr.get(path, :params=> args[1])
        Blacklight::SolrResponse.new(force_to_utf8(response), args[1])
        rescue Errno::ECONNREFUSED => e
        raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to Solr instance using #{blacklight_solr.inspect}")
    end

    def blacklight_solr
        @solr ||=  RSolr.connect(blacklight_solr_config)
    end

    def force_to_utf8(value)
        case value
            when Hash
                value.each { |k, v| value[k] = force_to_utf8(v) }
            when Array
                value.each { |v| force_to_utf8(v) }
            when String
                value.force_encoding("utf-8")  if value.respond_to?(:force_encoding)
        end
        value
    end
end
