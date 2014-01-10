require 'active_fedora'
 
module Hydra
  module Datastream
    class PdfDatastream < ActiveFedora::Datastream         
  
      def get_pdf_as_string
        #reader = PDF::Reader.new("/home/ermadmix/akubra-hdfs-abstract.pdf")
        io = open(selfurl)
        reader = PDF::Reader.new(io)
        pdf_string = ""
        reader.pages.each do |page|
          pdf_string = pdf_string + page.to_s
        end
        pdf_string
      end
      def selfurl
        fedoraconf = YAML.load_file('config/fedora.yml')
        region = fedoraconf.fetch(Rails.env)
        server = region.fetch("url")
        #url = region + "/" + self.pid + '/' + self.dsid
        url = server + "/" + self.url
        url
      end
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        solr_doc['test_ssi'] = selfurl 
        solr_doc['fulltext_tsim'] = get_pdf_as_string
        solr_doc
      end	  
    end
  end
end
