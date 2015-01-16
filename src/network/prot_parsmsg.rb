# prot_parsmsg.rb
############## genereic application client/server commands #######

$:.unshift File.dirname(__FILE__)

require 'prot_constants'


module ParserCmdDef
  
  
  ##
  # Provides the error code as string  using key
  # key: error code key. e.g. pg_remov_req_fail
  def srv_error_code(key)
    info = ProtCommandConstants::SERVER_ERROR_INFO[key]
    if info
      return info[:code].to_s
    end
    return "0"
  end
  
  ##
  # Provides error string for the given code
  # code: server code as integer
  def srv_error_info(code)
    ProtCommandConstants::SERVER_ERROR_INFO.each do |k,info|
      if info[:code] == code
        return info[:info]
      end
    end
    return "Server Error code not found"
  end
                
  ########### commands handler #######################

  # avoid biolerplate code, define commeted methods below, with only few code 
  ProtCommandConstants::SUPP_COMMANDS.each do |k,v| 
    module_eval( 
    %{def #{v[:cmdh].to_s}(msg_details, player=nil)
       log_warn("#{v[:liter]} handler not implemented\n")
      end
    } )
  end
  

end

