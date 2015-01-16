#require 'net/http'
require 'net/https'

require 'facebooker/parser'
module Facebooker
  class Service
    def initialize(api_base, api_path, api_key)
      @api_base = api_base
      @api_path = api_path
      @api_key = api_key
    end
    
    # TODO: support ssl 
    def post(params)
      # ISS on facebook.auth.getSession using https
      if params[:method] == '**facebook.auth.getSession'
        uri = urlssh
        p "using ssh with #{uri.host}"
        request = Net::HTTP.new(uri.host, uri.port)
        request.use_ssl = true
        request.verify_mode = OpenSSL::SSL::VERIFY_NONE
        reqpost = Net::HTTP::Post.new(uri.path)
        reqpost.form_data = params
        #responce = request.post_form(urlssh, params)
        p responce =  request.request(reqpost)
        
        Parser.parse(params[:method],responce)
      else
        #p urlssh
        Parser.parse(params[:method], Net::HTTP.post_form(url, params))
      end
    end
    
    def post_file(params)
      Parser.parse(params[:method], Net::HTTP.post_multipart_form(url, params))
    end
    
    private
      def url
        URI.parse('http://'+ @api_base + @api_path)      
      end
      
      def urlssh
        URI.parse('https://'+ @api_base + @api_path)      
      end
  end
end