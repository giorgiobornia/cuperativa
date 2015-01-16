# -*- coding: ISO-8859-1 -*-
# file: control_net_conn.rb
# 
$:.unshift File.dirname(__FILE__) + '/..'
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'network_cockpit_view'
require 'nal_client_gfx'
require 'nal_client_spazzino_gfx'
require 'digest/md5'
require 'base64'
require "zlib" 
require 'timeout'
require 'thread'
require 'cup_strings'
require 'base/core/cup_strings'
require 'prot_parsmsg'
require 'prot_buildcmd'

#module GuiClientNet
 
##
# Control component of network connection
class ControlNetConnection
  attr_accessor :curr_user_name, :server_msg_aredebugged
 
  include ParserCmdDef
  include ProtBuildCmd
  
  # supported version on server
  SUPP_SERV_VER_MAJ = 13
  #SUPP_SERV_VER_MAJ = 2 #set to an old protocoll to update the program
  SUPP_SERV_VER_MIN = 0
  
  def initialize(cup_gui)
    @cup_gui = cup_gui
    @log = Log4r::Logger.new("coregame_log::ControlNetConnection") 
    @network_cockpit_view = nil
    @model_net_data = nil
    
    #nal gfx for remote game
    @nal_gfx_remotegame = nil
    # server received message queue
    @srv_msg_queue = []
    # mutex for accessing server message queue
    @mutex_srvmsg = Mutex.new
    # server message handler suspended flag
    @srv_msg_handler_susp = false
    
    @host_server = ''
    @port_server = 0
    @accumulated_msg = ""
    @socket_srv = nil
    
    @login_name = ""
    @password_login = "dummydu"
    @password_login_md5 = ""
    @password_saved = false
    @curr_user_name = ""
    @use_http_tunnel = false
    @id_http_session = nil
    @serv_conn_type = nil
    @server_type_http = false
    @ix_current_game = ""
    # store version of the game server
    @version_server = []
    @server_msg_aredebugged = false
  end
  
  
  ##
  # Set current model and view of cuperativa
  def set_model_view(model, view)
    @model_net_data = model
    @network_cockpit_view = view
  end
  
  ##
  # Set member variable using application settings
  def set_local_settings(app_settings)
    @log.debug "Update net_control setting"
    @host_server = app_settings["session"][:host_server]
    @port_server = app_settings["session"][:port_server]
    @login_name = app_settings["session"][:login_name]
    @password_login_md5  = app_settings["session"][:password_login]
    @password_saved = app_settings["session"][:password_saved]
    @serv_conn_type = app_settings["session"][:connect_type]
    @server_type_http = app_settings["web_http"]
    @remote_web_url = app_settings["session"][:remote_web_srv_url]
    @server_msg_aredebugged = app_settings["session"][:debug_server_messages]
  end
  
  ##
  # Overwrite application settings using local variables values
  def get_local_settings(app_settings)
    app_settings["session"][:host_server] = @host_server
    app_settings["session"][:port_server] = @port_server
    #if @login_name == @curr_user_name  
    app_settings["session"][:login_name] = @login_name# @curr_user_name
    #end 
    app_settings["session"][:password_login] = @password_login_md5 if @password_saved
    app_settings["session"][:connect_type] = @serv_conn_type
    app_settings["web_http"] = @server_type_http 
    app_settings["session"][:remote_web_srv_url] = @remote_web_url
    app_settings["session"][:password_saved] = @password_saved 
  end
  
  ##
  # Prepare an hash with connection data
  def prepare_info_conn_hash(info)
    info[:remote_web_srv_url] = @remote_web_url
    info[:connect_type] = @serv_conn_type
    
    info[:host_server] = @host_server
    info[:port_server] = @port_server
    info[:web_http] = @server_type_http 
    info[:login_name] = @login_name
    info[:password_login_md5] = @password_login_md5
    info[:password_login] = @password_login
    info[:password_saved] = @password_saved
  end
  
  
  ##
  # During a game, options are not changeable. Return true if options
  # could be changed immediately, otherwise false
  def options_changeable?
    network_state = @model_net_data.network_state
    if network_state == :state_on_localgame or
      network_state == :state_on_netgame
      return false
    else
      return true
    end
  end

  def ntfy_state_no_network
  end
  
  def ntfy_state_onupdate
  end
  
  def ntfy_state_on_localgame
  end
  
  def ntfy_state_on_netgame
  end
    
  ##
  # Notification player has logged on with success
  def ntfy_state_logged_on
    # subscribe to pending game request list
    cmd_to_send = build_cmd(:pendig_games_req2, "")
    send_data_to_server(cmd_to_send)
    @nal_gfx_remotegame = nil
  end
  
  def ntfy_state_on_table_game_end
  end
  
  def ntfy_state_ontable_lessplayers
  end
  
  ##
  # User want to resign the game
  def resign_game_cmd
    msg_details = "#{@ix_current_game}"
    cmd_to_send = build_cmd(:resign_game, msg_details)
    send_data_to_server(cmd_to_send)    
  end
  
  ##
  # User want to restart the last game
  def restart_game_cmd
    msg_details = "#{@ix_current_game}"
    cmd_to_send = build_cmd(:restart_game, msg_details)
    send_data_to_server(cmd_to_send)
  end
  
  ##
  # User want to leave the current table
  def leave_table_cmd
    @log.debug("Controller: send leave_table_cmd to the server")
    msg_details = "#{@ix_current_game}"
    cmd_to_send = build_cmd(:leave_table, msg_details)
    send_data_to_server(cmd_to_send)
    @model_net_data.event_cupe_raised(:ev_client_leave_table)
  end
  
  ##
  # Check if cuperativa update are available
  def check_update_forclient(nomeprog, ver_prog)
    @log.debug("Controller: check_update_forclient")
    net_prot_ver = [SUPP_SERV_VER_MAJ, SUPP_SERV_VER_MIN ]
    info_client = [nomeprog, ver_prog, net_prot_ver ]
    msg_details = YAML.dump(info_client)
    @log.debug "update_req: #{info_client}"
    cmd_to_send = build_cmd(:update_req, msg_details)
    send_data_to_server(cmd_to_send)
    @cup_gui.log_sometext("UPDATE: controlla se esiste una nuova versione\n")
  end
  
  ##
  # Connect to the server and send login name
  # info: info with connection information
  def connect_to_server_remote(info)
    # update connection data
    @use_http_tunnel = info[:use_http_tunnel]
    @host_server = info[:host_server]
    @port_server = info[:port_server]
    @login_name = info[:login_name]
    @password_saved = info[:password_saved] 
    use_guest_login = info[:use_guest_login]
    
    # the connect dialog provide an already coded password
    # on server password in decoded and checked against a digest string in the database
    @password_login_md5 = info[:password_login_md5]
    
    # close old connection before
    @log.debug "connect_to_server_remote"
    @socket_srv.close if @socket_srv
    @id_http_session = nil
    #p @host_server, @port_server
    status = Timeout::timeout(6) {
      # avoid to blocking for more time
      @socket_srv = TCPSocket.new(@host_server, @port_server)
    }
    # reset connection data model
    @model_net_data.reset_data
    # avoid funny characters
    #@login_name = @login_name.slice(/\w+/)
    # use the same regex as the registration (this check is also done on the server)
    @login_name = @login_name.slice(/\A\w[\w\.\-_@]+\z/)
    msg_det = "#{@login_name},#{@password_login_md5}"
    if use_guest_login
      msg_det = "ospite,ospite"
    end
    
    #send login message
    cmd_to_send = build_cmd(:login, msg_det)
    send_data_to_server(cmd_to_send)
    #start read thread
    if @use_http_tunnel
      @rd_sock_thread = Thread.new{read_data_on_http_tunnel}
    else
      @rd_sock_thread = Thread.new{ background_read }
    end
  rescue Timeout::Error
    @cup_gui.log_sometext "ERRORE: timeout connessione col server "
    @cup_gui.log_sometext " #{@host_server}:#{@port_server} (#{$!})\n"
    @socket_srv = nil
  rescue
    @cup_gui.log_sometext "Errore connessione server #{@host_server}:#{@port_server} (#{$!})\n"
    @cup_gui.log_sometext "Probabilmente il server e' offline, oppure le configurazioni del PC non consentono l'accesso ad internet\n"
    @socket_srv = nil
  end
  
  ##
  # Close remote connection with server
  def close_remote_srv_conn
    if @socket_srv
      @socket_srv.close
      @log.debug "close_remote_srv_conn requested"
      @cup_gui.log_sometext "Bye, connessione col server terminata\n"
      @rd_sock_thread.join
      @socket_srv = nil
    end
  rescue => detail
    @log.error "Server connection error (#{$!})\n"
    @log.error detail.backtrace.join("\n")
  ensure
    @socket_srv = nil 
  end
  
  ##
  # Send data to the server
  def send_data_to_server(data)
    if @use_http_tunnel
      send_data_with_http_tunnel(data)
    else
      status = Timeout::timeout(6) {
        @socket_srv.puts( data )
      }
    end
  rescue Timeout::Error
    @log.error "Timeout error on send_data_to_server"
    @cup_gui.log_sometext "ERRORE: timeout connessione col server durante l'invio di dati "
  rescue
    @log.error "Error on send_data_to_server #{data}. Detail: #{$!}"
    @cup_gui.log_sometext "Errore connessione server (#{$!})\n"
    @socket_srv = nil
  end
  
  
  ##
  # Send data using http tunnel
  def send_data_with_http_tunnel(data)
    #msg_data = Base64::encode64(data)
    #@socket_srv.print "GET /office_send_msg?#{msg_data} HTTP/1.1\r\n"
    # Zip deflate avoid to have special character in the encoded argument
    msg_data =  Zlib::Deflate.deflate( data, 1 ).unpack('H*').first 
    @socket_srv.print "GET /office_send_msg?#{msg_data} HTTP/1.1\r\n"
    #@socket_srv.print "GET /office_send_msg HTTP/1.1\r\n"
    @socket_srv.print "Host: #{@host_server}:#{@port_server}\r\n"
    @socket_srv.print "X-Cup-Session-Id: #{@id_http_session}\r\n" if @id_http_session
    @socket_srv.print "User-Agent: Mozilla/5.0\r\n"
    @socket_srv.print "Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
    @socket_srv.print "Keep-Alive: 300\r\n"
    @socket_srv.print "Connection: keep-alive\r\n"
    @socket_srv.print "\r\n" #end message
    #http_packet = 
    #@socket_srv.write(http_packet)
  end
  
  ##
  # Read response from http server
  def read_data_on_http_tunnel
    @log.debug "read_data_on_http_tunnel read start"
    while true
      dat = @socket_srv.gets
      break if dat.nil? or dat.empty?
      @log.debug "<server> #{dat.chomp}"
      # TO DO: parse message
    end
  rescue
    @log.warn "socket read end: (#{$!})"
  ensure
    @log.debug "read_data_on_http_tunnel  terminated"
    @socket_srv = nil
  end
  
  ##
  # Background read, thread handler
  def background_read
    @log.debug "Background read start"
    begin
      while true
        dat = @socket_srv.gets
        if dat.nil?
          @log.debug "data nil, terminate read"
          break
        elsif dat.empty?
          @log.debug "data empty, try to continue"
          next
        end  
        @log.debug "<server> #{dat.chomp}" if @server_msg_aredebugged
        parse_server_message(dat)
      end
    rescue
      @log.warn "socket read end: (#{$!})"
    ensure
      @log.debug "Background read terminated"
      @socket_srv = nil
      @model_net_data.event_cupe_raised(:ev_client_disconnected)
    end
  end 
  
  ##
  # Send ping response
  def send_ping_resp
    cmd_to_send = build_cmd(:ping_resp, "")
    send_data_to_server(cmd_to_send)
  end
 
  ##
  # Send crate pending game
  def send_create_pg2(msg_detail)
    info = YAML.dump(msg_detail)
    cmd_to_send = build_cmd(:pg_create2, info)
    send_data_to_server(cmd_to_send)
  end
  
  def send_listuser_req
    cmd_to_send = build_cmd(:users_connect_req, "")
    send_data_to_server(cmd_to_send)
  end
  
  def send_listviewgames_req
    info_hash = {:cmd => :req_list}
    send_view_game(info_hash)
  end
  
  ##
  # Send join pending game
  def send_join_pg(msg_detail)
    cmd_to_send = build_cmd(:pg_join, msg_detail)
    send_data_to_server(cmd_to_send)
  end
  
  def send_view_game(msg_detail)
    info = YAML.dump(msg_detail)
    cmd_to_send = build_cmd(:game_view, info)
    send_data_to_server(cmd_to_send)
  end
  
  def send_restart_withanewgame(msg_detail) 
    info = YAML.dump(msg_detail)
    cmd_to_send = build_cmd(:restart_withanewgame, info)
    send_data_to_server(cmd_to_send)
  end
  
  ##
  # Send remove pending game request
  def send_pg_remove_req(ix_pg)
    msg_detail = "#{ix_pg}"
    cmd_to_send = build_cmd(:pg_remove_req, msg_detail)
    send_data_to_server(cmd_to_send)
  end
  
  ##
  # Send join pending game with pin
  def send_join_pin_pg(ix, pin)
    msg_detail = "#{ix},#{pin}"
    cmd_to_send = build_cmd(:pg_join_pin, msg_detail)
    send_data_to_server(cmd_to_send)
  end
  
  ##
  # Send chat message to the server
  # msg: string to be sent
  # type: :chat_lobby or :chat_tavolo
  def send_chat_text(msg, type)
    if @socket_srv
      unless msg.empty? 
        cmd_to_send = build_cmd(type, msg)
        send_data_to_server(cmd_to_send)
      end
    else
      @cup_gui.log_sometext "Non collegato in rete\n"
    end
  end
  
  ##
  # Check if the message handler is suspended
  def is_msg_handler_suspended?
    return @srv_msg_handler_susp
  end
  
  ##
  # Suspend server message handler processor
  def suspend_srv_msg_handler
    unless @srv_msg_handler_susp
      # we are going to block communication with server
      # to avoid deadlock, set the time
      @srv_suspend_ini_time = Time.now
    end
    @srv_msg_handler_susp = true
    
  end
  
  ##
  # Restore server message handler processor
  def restore_srv_msg_handler
    # keep access to @srv_msg_queue exclusive
    @log.debug "restore_srv_msg_handler"
    @srv_msg_handler_susp = false
    msg = nil
    @mutex_srvmsg.synchronize{
      if @srv_msg_queue.size > 0
        msg = @srv_msg_queue.pop
      end
    }
    if msg != nil
      @log.debug "[QPROC] Restore msg, before proc queue size: #{@srv_msg_queue.size}: #{msg[0..10]}"
      process_srv_command(msg)
      @log.debug "Restore msg suspended? #{@srv_msg_handler_susp}"
      #if !is_msg_handler_suspended?
      #    restore_srv_msg_handler
      #end
    else
      @log.debug "No more messages handler queued terminating"
    end
  end
  
  ##
  # Parse  message from server
  # Q: Trouble if you receive 2 or more commands in the same message?
  # R: I think no, because the socket.puts split the message after \n
  # What happens for such strings:
  # "--- \n- ospite1\n- []\r\n". Resp: all OK
  def parse_server_message(message)
    if message =~ /#{ProtCommandConstants::CRLF}/
      # command ready to be parsed
      srv_message = @accumulated_msg
      @accumulated_msg = "" 
      srv_message += message
      # queue it
      val_susp = false
      @mutex_srvmsg.synchronize{
        @srv_msg_queue.insert(0, srv_message)
        val_susp = @srv_msg_handler_susp
      }
      if val_susp
        #message handler is suspended, do nothing until restore_srv_msg_handler is called   
        #check time of suspension
        s1 = Time.now
        if s1 - @srv_suspend_ini_time > 7.0
          # something is wrong with suspension, deadlock?
          @log.warn "Message handler was suspend too long. Why dear programmer?"
          restore_srv_msg_handler
        else
          @log.debug("Handler is suspended, just waiting a call of restore_srv_msg_handler")
          return
        end
      end
    
    else
      #accumulate the message because is not completed
      @accumulated_msg += message
      if @accumulated_msg.length > 16384
        @log.error("!!!! **** Message is too big!!****, len > 16384")
        # don't accept message that are longer than 2K
        @accumulated_msg = ""
      end
    end
  rescue => detail
    @log.error "Parser error(#{$!}) on #{message}"
    @log.error detail.backtrace.join("\n")
  end
  
  ##
  # Process next message from server. Function called when idle
  def process_next_server_message
    msg = nil
    begin
      @mutex_srvmsg.synchronize{
        if @srv_msg_queue.size > 0 and !is_msg_handler_suspended?
          msg = @srv_msg_queue.pop    
        end
      }
      if msg != nil
        #@log.debug "[QPROC] Process msg from idle"
        process_srv_command(msg)
      end 
    rescue=> detail
      @log.error "Parser error(#{$!}) on #{msg}"
      @log.error detail.backtrace.join("\n")
    end
  end
  
  ##
  # Process server message
  # srv_message: a complete server message
  def process_srv_command(srv_message)
    # command is the left part on colon
    arr_cmd_msg = srv_message.split(":")
    cmd = arr_cmd_msg.first
    # details of command
    cmd_details = arr_cmd_msg[1..-1].join(":")
    #retreive the symbol of the command handler
    meth_parsed = nil 
    ProtCommandConstants::SUPP_COMMANDS.each do |k,v|
      if v[:liter] == cmd 
        meth_parsed = v[:cmdh] 
        break
      end 
    end
    # call the command handler if the command handler is recognized
    if meth_parsed
      send meth_parsed, cmd_details.chomp
    end
  end
  
  ########### network commands handler #######################
  
  ##
  # handle command INFO
  def cmdh_info(msg_details)
    @log.debug "INFO handler called"
    @cup_gui.log_sometext("<Server>: #{msg_details}\n")
  end
  
  ##
  # handle command VER
  def cmdh_ver(msg_details)
    @log.debug "VER handler called"
    tmp = msg_details.split(".")
    if tmp.size == 2
      ver_maj = tmp[0].to_i
      ver_min = tmp[1].to_i
      @version_server = [ver_maj, ver_min]
      @log.debug("Server: #{ver_maj}.#{ver_min}. Client #{SUPP_SERV_VER_MAJ}.#{SUPP_SERV_VER_MIN}")
      @cup_gui.log_sometext("Server versione #{ver_maj}.#{ver_min}. Client supporta #{SUPP_SERV_VER_MAJ}.#{SUPP_SERV_VER_MIN}\n")
      if ver_maj > SUPP_SERV_VER_MAJ or
         (ver_maj == SUPP_SERV_VER_MAJ and  
          ver_min > SUPP_SERV_VER_MIN)
         
        str = u("ATTENZIONE: Questo programma non U+00e8 attuale. Controllo se esiste una versione recente.\n")
        @cup_gui.log_sometext(str)
        #@socket_srv.close
        res = @cup_gui.get_nameprog_swversion
        ver_prog = res[1]
        nomeprog = res[0]
        # check is a new update is present
        check_update_forclient(nomeprog, ver_prog)
    
      else
        @cup_gui.log_sometext("Versione client e versione Server compatibili: OK \n")
      end
    else
      @log.error("VER format error")
    end
  end
  
  ##
  # handle command PGCREATEREJECT
  def cmdh_pg_create_reject(msg_details)
    @log.debug "PGCREATEREJECT handler called"
    @cup_gui.log_sometext("Gioco non creato, ragione: #{msg_details}\n")
  end
  
  ##
  # handle command PGJOINREJECT2
  def cmdh_pg_join_reject2(msg_details)
    @log.debug "PGCREATEREJECT2 handler called"
    info = YAML::load(msg_details)
    ix = info[:ix]
    detail = reject_errorcode_to_text(info[:err_code])
    @cup_gui.log_sometext("***ERRORE ***. Impossibile partecipare al gioco#{ix}, ragione: #{detail}\n")
  end
  
  ##
  # Provides the description of pg_rejected error code
  def reject_errorcode_to_text(code)
    msg = "ragione sconosciuta"
    case code
      when 1
        msg = "indice gioco non trovato"
      when 2
        msg = "non e' possibile partecipare ad un gioco creato da se stessi"
      when 3
        msg = "non e' possibile partecipare al gioco privato"
      when 4
        msg = "gioco valido per la classifica, disponibile solo per giocatori registrati"
      when 5
        msg = "qualcun altro sta cercando di giocare questa partita, spiacenti la richiesta non puo' essere accettata"
      when 6
        msg = "partita non valida"
      when 7
        msg = "indice gioco non trovato"
      when 8
        msg = "solo il creatore del gioco puo' accettare giocatori"
      when 9
        msg = "creatore del gioco disconnesso"
      end
    return msg
  end

  ##
  # handle command PGJOINOK
  def cmdh_pg_join_ok(msg_details)
    # Our join message was confirmed by server and tender
    @log.debug "PGJOINOK handler called"
    index = msg_details
    @ix_current_game = index
    @game_window.log_sometext("Gioco sta per iniziare...\n") if @game_window
  end
  
  
  
  ##
  # handle command PGJOINTENDER
  def cmdh_pg_join_tender(msg_details)
    @log.debug "PGJOINTENDER handler called"
    # we are using auto accept request at the moment...
    tmp = msg_details.split(",")
    if tmp.size == 2
      user = tmp[0]
      index = tmp[1]
      @ix_current_game = index
      #@cup_gui.log_sometext("Utente #{user} vuole cominciare la partita #{index}, OK! \n")
      @game_window.log_sometext("Utente #{user} vuole cominciare la partita #{index}, OK! \n") if @game_window
      # TO DO: use global option like autoaccept and eventually ask the user
      # if he want to accept the tender
      # accept it, resend back msg_details. We are using auto accept default
      cmd_to_send = build_cmd(:pg_join_ok, msg_details)
      send_data_to_server(cmd_to_send)      
    else
      @log.error("Tender request is malformed (server message PGJOINTENDER)")
    end
  end
  
  ##
  # Login ok LOGINOK
  def cmdh_loginok(msg_details)
    @log.debug "LOGINOK handler called, logged on as: #{msg_details}"
    @curr_user_name = msg_details
    @model_net_data.event_cupe_raised(:ev_login_ok)
  end
  
  ##
  # Login error LOGINERROR
  def cmdh_loginerror(msg_details)
    @log.debug "LOGINERROR handler called"
    tmp  = msg_details.split(",")
    if tmp.size != 2
      return
    end
    err_code = tmp[0].to_i
    name = tmp[1]
    info_str = "errore generico nel login"
    case err_code
      when 1
        info_str = "Password oppure login errato."
      when 2
        info_str = u"Utente #{name} giU+00e0  connesso al server, collegamenti multipli con lo stesso account non sono possibili."
      when 3
        info_str = u"Ospite #{name} giU+00e0  connesso al server, collegamento non ammesso."
    end
     
    @cup_gui.log_sometext("<Server ERRORE>:#{info_str}\n")
  end
  
  ##
  # handle command CHATLOBBY
  def cmdh_chatlobby(msg_details)
    @log.debug "CHATLOBBY handler #{msg_details}"
    # message is a string: "user>blabla...."
    user_name, msg_content = msg_details.split(">")
    @cup_gui.render_chat_lobby "[#{user_name}] #{msg_content}\n"
  end
  
  ##
  # handle command CHATTAVOLO
  def cmdh_chattavolo(msg_details)
    @log.debug "CHATTAVOLO handler"
    # message is a string: "user>blabla...."
    user_name, msg_content = msg_details.split(">")
    if @game_window
      #@cup_gui.render_chat_tavolo "[#{user_name}] #{msg_content}\n"
      @game_window.render_chat_tavolo "[#{user_name}] #{msg_content}\n"
    end
  end
  
  ##
  # handle command SRVERROR
  def cmdh_srv_error(msg_details)
    @log.debug "SRVERROR handler"
    err_code = msg_details.to_i
    info_str = srv_error_info(err_code)
    @cup_gui.log_sometext("<Server ERRORE>:#{info_str}\n")
  end

  def handle_listremove_pendinggames(info)
    ix_data = @model_net_data.parse_list2remove_pg(info)
    @network_cockpit_view.table_remove_pg_game(ix_data)
  end
    
  def handle_listadd_pendinggames(info)
    ix_game = @model_net_data.parse_list2add_pg(info)
    if ix_game
      @network_cockpit_view.table_add_pgitem2(ix_game)
    end
  end
  
  def handle_list_pendinggames(info)
    state, eol_flag = @model_net_data.parse_list2(info)
    case state
      when :first_slice
        @network_cockpit_view.clear_pgtable
        @network_cockpit_view.pushfront_pgitem_data2(@model_net_data.get_last_pglist_data)
      when :data_slice
        @network_cockpit_view.pushfront_pgitem_data2(@model_net_data.get_last_pglist_data)
      when :list_empty
        @network_cockpit_view.clear_pgtable
      when :error
        @log.error("pg_list handler error")
    end
    if eol_flag
      # request list of user
      @log.debug "users_connect_req"
      send_listviewgames_req
    end
  end
  
  def handle_listadd_viewgames(info)
    ix_game = @model_net_data.parse_list2add_gameview(info)
    if ix_game
      @network_cockpit_view.table_add_viewgame(ix_game)
    end
  end
  
  def handle_listremove_viewgames(info)
    ix_data = @model_net_data.parse_list2remove_viewgame(info)
    @network_cockpit_view.table_remove_viewgame(ix_data)
  end
  
  def handle_list_viewgames(info)
    state, eol_flag = @model_net_data.parse_list2(info)
    case state
      when :first_slice
        @network_cockpit_view.clear_userlist_table
        @network_cockpit_view.pushfront_viewgames_data(@model_net_data.get_last_viewgame_data)
      when :data_slice
        @network_cockpit_view.pushfront_viewgames_data(@model_net_data.get_last_viewgame_data)
      when :list_empty
        @network_cockpit_view.clear_userlist_table
      when :error
        @log.error("pg_list handler error")
    end
    if eol_flag
      # request list of user
      @log.debug "users_connect_req"
      send_listuser_req
    end
  end
  
  ##
  # handle command LIST2
  def cmdh_list2(msg_details)
    #@log.debug "LIST2 handler"
    info = YAML::load(msg_details)
    type = info[:type]
    if type == :pgamelist
      handle_list_pendinggames(info)
    elsif type == :gameviewlist
      handle_list_viewgames(info)
    else
      @log.error "LIST2 type not specified"
    end
  end
  
  def cmdh_list2_remove(msg_details)
    @log.debug "LIST2REMOVE remove handler"
    info = YAML::load(msg_details)
    type = info[:type]
    if type == :pgamelist
      handle_listremove_pendinggames(info[:detail])
    elsif type == :gameviewlist
      handle_listremove_viewgames(info[:detail])
    else
      @log.error "LIST2REMOVE type not specified"
    end
    
  end
    
  ##
  # handle command LIST2ADD
  def cmdh_list2_add(msg_details)
    @log.debug "LIST2ADD handler"
    info = YAML::load(msg_details)
    type = info[:type]
    if type == :pgamelist
      handle_listadd_pendinggames(info[:detail])
    elsif type == :gameviewlist
      handle_listadd_viewgames(info[:detail])
    else
      @log.error "LIST2ADD type not specified"
    end
   
  end
  
  def cmdh_game_view(msg_details)
    info = YAML::load(msg_details)
    @log.debug "GAMEVIEW handler cmd #{info[:cmd]}"
  end
  
  def cmdh_player_reconnect(msg_details)
    info = YAML::load(msg_details)
    @log.debug "TODO.... PLAYERRECONNECT handler cmd #{info[:cmd]}"
  end
 
  ##
  # handle command USERLIST
  def cmdh_user_list(msg_details)
    @log.debug "USERLIST handler"
    # parse the message
    state, eol_flag = @model_net_data.parse_user_list(msg_details)
    case state
      when :first_slice
        @network_cockpit_view.clear_userlist_table
        @network_cockpit_view.pushfront_users_data(@model_net_data.get_last_users_parsed)
      when :data_slice
        @network_cockpit_view.pushfront_users_data(@model_net_data.get_last_users_parsed)
      when :list_empty
        @network_cockpit_view.clear_userlist_table
      when :error
        @log.error("user_list handler error")
    end
  end
  
  ##
  # handle command USERADD
  def cmdh_user_add(msg_details)
    @log.debug "USERADD handler"
    nick_name = @model_net_data.parse_user_add(msg_details)
    @network_cockpit_view.table_add_userdata(nick_name) if nick_name
  end
  
  ##
  # handle command USERREMOVED
  def cmdh_user_removed(msg_details)
    @log.debug "USERREMOVED handler"
    nick_name = @model_net_data.parse_user_remove(msg_details)
    @network_cockpit_view.table_remove_user(nick_name) if nick_name
  end
  
  ##
  # handle command LEAVETABLENTFY
  def cmdh_leave_table_ntfy(msg_details)
    @log.debug "LEAVETABLENTFY handler"
    tmp = msg_details.split(",")
    unless tmp.size == 2
      @log.error("LEAVETABLENTFY format error")
      return
    end
    user_name = tmp[1]
    # ignore ix game because we support only one game
    #@cup_gui.current_game_gfx.player_leave(user_name)
    if @game_window
      @game_window.current_game_gfx.player_leave(user_name) 
    
      #@cup_gui.log_sometext("Il giocatore #{user_name} ha lasciato il tavolo\n")
      @game_window.log_sometext("Il giocatore #{user_name} ha lasciato il tavolo\n")
    end
    @model_net_data.event_cupe_raised(:ev_playerontable_leaved)
  end
  
  ##
  # handle command RESTARTGAMENTFY
  def cmdh_restart_game_ntfy(msg_details)
    @log.debug "RESTARTGAMENTFY handler"
    #@cup_gui.log_sometext("La rivincita sta per iniziare...")
    @game_window.log_sometext("La rivincita sta per iniziare...") if @game_window
    tmp = msg_details.split(",")
    unless tmp.size == 2
      @log.error("RESTARTGAMENTFY format error")
      return
    end
    user_name = tmp[1]
    # ignore ix game because we support only one game
    @current_game_gfx.player_ready_to_start(user_name)
    if @game_window
      strmsg = "Il giocatore #{user_name} pronto per cominciare una nuova partita\n"
      @game_window.log_sometext(strmsg) 
      @game_window.render_chat_tavolo("[CUPERATIVA] #{strmsg}")
    end
  end
  
  def cmdh_restart_withanewgame(msg_details)
    @log.debug "RESTARTWITHNEWGAME handler"
    info = YAML.load(msg_details)
    @log.debug "TODO...... #{info}"
  end
  
  ##
  # handle command UPDATERESPTWO
  # This make the cmdh_update_resp obsolete. cmdh_update_resp should be implemented
  # only on old client. The server still sent both message for compatibility and 
  # on the client we need to implement only ONE.
  def cmdh_update_resp2(msg_details)
    @log.debug "UPDATERESPTWO handler"
    info = YAML::load(msg_details)
    case info[:type] 
      when :platf_update
        # need a platform update
        @log.debug "Platform update is needed"
        str =   "ATTENZIONE:  questo client necessita di un aggiornamento manuale per giocare in internet.\n"
        str +=  "             Vai su cuperativa.invido.it per maggiorni informazioni.\n"
        str +=  "             Senza una versione recente, il gioco in rete non funziona.\n"
        str +=  "             *********** L'ultima versione aggiornata di cuperativa si scarica da: **************\n"
        str +=  "             #{info[:link_platf]}\n"
        str +=  "             *********************************************************\n"
        @cup_gui.log_sometext(str)  
        #close connection
        @socket_srv.close if @socket_srv
        return
      when :nothing
        # no update, client is OK
        @log.debug "Client already updated"
        strtext = u"Il programma U+00e8 giU+00e0 all'ultima versione.\n"
        @cup_gui.log_sometext(strtext)
        return
      when :appli_update
        # need to update the application
        server_name = info[:server].gsub('http://', "")
        package_name = info[:file ]
        updater = ClientUpdaterCtrl.new
        updater.set_package_src(server_name, package_name)
        updater.gui_progress = @cup_gui
        updater.net_controller = self
        updater.info_package = info
        begin 
          #updater.install_package
          @model_net_data.event_cupe_raised(:ev_startupdate)
          updater.install_package_question(@model_net_data)
        rescue
          @cup_gui.log_sometext("ERRORE: Update non riuscito\n")
          @cup_gui.log_sometext("Riprova l'update, oppure installa la versione completa aggiornata di cuperativa (www.invido.it).\n")
          @socket_srv.close if @socket_srv
        end
      else
        @log.error 'Update type not recognized'
    end#case
  end#cmdh_update_resp2
  
  ##
  # Handle command PINGREQ
  def cmdh_ping_req(msg_details)
    @log.debug "PINGREQ handler"
    # response back
    send_ping_resp
  end
  
  ##
  # Apply a patch to the current installed client
  # patch_filename: tgz patch filename
  def apply_update_patch(patch_filename)
    updater = ClientUpdaterCtrl.new
    updater.gui_progress = @cup_gui
    updater.net_controller = self
    begin 
      #updater.install_package_patch(patch_filename)
      updater.begin_install_patch(@model_net_data, patch_filename)
    rescue
      @cup_gui.log_sometext("ERRORE: Update non riuscito\n")
    end
     
  end
  
  def game_window_destroyed
    @game_window = nil
    @current_game_gfx = nil
  end
  
  
  ##
  # Log function for warning messages
  def log_warn(str)
    @log.warn(str)
  end
  
  ###################### ALGORITHM CALLBACKS
  
  ##
  # handle command ONALGNEWMATCH
  # Trigger a new match. Create Nal objects and initialize gfx stuff
  def cmdh_onalg_new_match(msg_details)
    @log.debug "ONALGNEWMATCH handler"
    #@net_table_dlg.hide
    #@tabbook.setCurrent(0)
    
    info = YAML::load(msg_details)
    unless info.size == 3
      @log.error "ONALGNEWMATCH format error"
      return
    end
    nome_game = info[0]
    all_players = info[1]
    options_remote = info[2]
    
    @cup_gui.initialize_current_gfx(nome_game)
    #p "Nome gioco: #{nome_game}"
    #p @cup_gui.current_game_gfx
    #p @cup_gui.current_game_gfx.nal_client_gfx_name
    
    # create a network adapter layer to enable communication from remote server 
    # to the gfx local client.
    # Options are here a little confusing: we need @app_settings for local user options
    # but also the remote server need options. We should know, for example, how many segni are in the game and points target.
    #p @cup_gui.app_settings
    
    unless @game_window
      @game_window = @cup_gui.create_new_singlegame_window(:online)
      @current_game_gfx = @game_window.current_game_gfx  if @game_window
      @info_for_newmatch = {:all_players => all_players, :options_remote => options_remote}
      # set timout because window window is created and raise risize event, so we ha to to wait build gfx components
      @avoid_suspend = false
      @cup_gui.registerTimeout(500, :OnTimeoutGameWindowCreated, self)
      suspend_srv_msg_handler if @avoid_suspend == false #chek because ontimeout could go throw, i.e in robot
      @log.debug "Wait a little to popup the game window. Suspend processing"
      return 
    end
    
    return unless @current_game_gfx
    
    continue_alg_newmatch(all_players, options_remote)
  end
  
  def OnTimeoutGameWindowCreated
    continue_alg_newmatch(@info_for_newmatch[:all_players], @info_for_newmatch[:options_remote])
    @log.debug "Restore msg processing"
    if @srv_msg_handler_susp
      restore_srv_msg_handler
    end
    @avoid_suspend = true 
  end
  
  def continue_alg_newmatch(all_players, options_remote)
    @nal_gfx_remotegame = eval(@current_game_gfx.nal_client_gfx_name).new(self, @game_window.current_game_gfx, @cup_gui.app_settings.dup)
    
    # create network abstract layer core game. We need to redirect message from client gfx
    # directed to core game, to the remote core located on the server.
    nal_core = NalClientCore.new(self)
    
    #change state
    # use event to change a state
    @model_net_data.event_cupe_raised(:ev_start_network_game)
    
    # let nal gfx to start a new match
    @nal_gfx_remotegame.onalg_new_match(@curr_user_name, 
                all_players, nal_core, 
                options_remote) if @nal_gfx_remotegame
   
  end
  
  
  ##
  # handle command ONALGNEWGIOCATA
  def cmdh_onalg_new_giocata(msg_details)
    @log.debug "ONALGNEWGIOCATA handler"
    @nal_gfx_remotegame.onalg_new_giocata(msg_details.split(",")) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGNEWMAZZIERE
  def cmdh_onalg_new_mazziere(msg_details)
    @log.debug "ONALGNEWMAZZIERE handler"
    @nal_gfx_remotegame.onalg_new_mazziere(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGNEWMANO
  def cmdh_onalg_newmano(msg_details)
    @log.debug "ONALGNEWMANO handler"
    @nal_gfx_remotegame.onalg_newmano(msg_details) if @nal_gfx_remotegame
  end
  
  
  ##
  # handle command ONALGHAVETOPLAY
  def cmdh_onalg_have_to_play(msg_details)
    @log.debug "ONALGHAVETOPLAY handler"
    @nal_gfx_remotegame.onalg_have_to_play(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPLAYERHASPLAYED
  def cmdh_onalg_player_has_played(msg_details)
    @log.debug "ONALGPLAYERHASPLAYED handler"
    @nal_gfx_remotegame.onalg_player_has_played(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPLAYERHASTAKEN
  def cmdh_onalg_player_has_taken(msg_details)
    @log.debug "ONALGPLAYERHASTAKEN handler"
    @nal_gfx_remotegame.onalg_player_has_taken(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPLAYERHASDECLARED
  def cmdh_onalg_player_has_declared(msg_details)
    @log.debug "ONALGPLAYERHASDECLARED handler"
    @nal_gfx_remotegame.onalg_player_has_declared(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPESCACARTA
  def cmdh_onalg_pesca_carta(msg_details)
    @log.debug "ONALGPESCACARTA handler"
    @nal_gfx_remotegame.onalg_pesca_carta(msg_details) if @nal_gfx_remotegame
  end
  
  def cmdh_onalg_player_pickcards(msg_details)
    @log.debug "ONALGPICKCARDS handler"
    @nal_gfx_remotegame.onalg_player_pickcards(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGMANOEND
  def cmdh_onalg_manoend(msg_details)
    @log.debug "ONALGMANOEND handler"
    @nal_gfx_remotegame.onalg_manoend(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGGIOCATAEND
  def cmdh_onalg_giocataend(msg_details)
    @log.debug "ONALGGIOCATAEND handler"
    @nal_gfx_remotegame.onalg_giocataend(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGGAMEEND
  def cmdh_onalg_game_end(msg_details)
    @log.debug "ONALGGAMEEND handler"
    @nal_gfx_remotegame.onalg_game_end(msg_details) if @nal_gfx_remotegame
    # for action on this class for game end we are using the callback
    # from gfx. Look on function game_end in file cuperativa_gui.rb
  end
  
  ##
  # handle command ONALGPLAYERHASCHANGEDBRISC
  def cmdh_onalg_player_has_changed_brisc(msg_details)
    @log.debug "ONALGPLAYERHASCHANGEDBRISC handler"
    @nal_gfx_remotegame.onalg_player_has_changed_brisc(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPLAYERHASGETPOINTS
  def cmdh_onalg_player_has_getpoints(msg_details)
    @log.debug "ONALGPLAYERHASCHANGEDBRISC handler"
    @nal_gfx_remotegame.onalg_player_has_getpoints(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGGAMEINFO
  def cmdh_onalg_gameinfo(msg_details)
    @log.debug "ONALGGAMEINFO handler"
    @nal_gfx_remotegame.onalg_gameinfo(msg_details) if @nal_gfx_remotegame
  end
  
  ##
  # handle command ONALGPLAYERCARDSNOTALLOWED
  def cmdh_onalg_player_cardsnot_allowed(msg_details)
    @log.debug "ONALGPLAYERCARDSNOTALLOWED handler"
    @nal_gfx_remotegame.onalg_player_cardsnot_allowed(msg_details) if @nal_gfx_remotegame
  end
  
end #end GuiClientNet
