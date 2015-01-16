# -*- coding: ISO-8859-1 -*-
#file: check_web_serv.rb

require 'rubygems'
require 'net/http'
require 'rexml/document'
require 'log4r'

##
# module used to check the web service for cuperativa server
module Client_Cup_Webserv
  
  ##
  # GET the web service to retrieve server address and port
  def pick_info_fromremote_url(web_srv_url)
    info_serv = {}
    url = "http://#{web_srv_url}"
    @log.debug "Check url #{url}"
    uri = URI::parse(url)
    if @use_proxy
      http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass).start(uri.host, uri.port)
    else
      http = Net::HTTP.start(uri.host, uri.port)
    end
    response = http.post(uri.request_uri, "")
    #@log.debug response.body
    arr_infoserv = []
    cupsrv  = REXML::Document.new(response.body)
    cupsrv.elements.each("cupsrv")  do |content|
      # note: we have only one cupsrv tag
      content.each_element do |node|
        # iterate the content of <cupsrv>
        info_serv = {}
        #p node.name
        if node.has_elements?
          # an <entry> node because there are children
          node.each_element do |entry_det|
            @log.debug "#{entry_det.name}: #{entry_det.text}"
            info_serv[entry_det.name] = entry_det.text 
          end
          # store only entries
          arr_infoserv << info_serv
        else
          @log.debug "#{node.name}: #{node.text}"
        end
         
      end
    end
    return arr_infoserv
  rescue
    @log.error("pick_info_fromremote_url: #{$!}")
    return {}
  end
  
end

if $0 == __FILE__
  include Log4r
  
  class TestChecker
    include Client_Cup_Webserv
    def initialize
      @log = Log4r::Logger.new("checker")
      @log.outputters << Outputter.stdout
      @use_proxy = false
      #@proxy_host = '127.0.0.1'
      #@proxy_port = 5865
      
      @proxy_user = nil
      @proxy_pass = nil
    end
  end
  
  test = TestChecker.new
  host = "igor.railsplayground.com"
  #host = "127.0.0.1:3303"
  test.pick_info_fromremote_url("#{host}/cuperativa/cuperativa.xml")
end