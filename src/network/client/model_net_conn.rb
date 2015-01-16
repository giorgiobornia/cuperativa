# -*- coding: ISO-8859-1 -*-
#file: model_net_conn.rb
# Model data to store data exchangend between client and server

require 'rubygems'

##
# Data model for network session
class ModelNetData
  
  attr_accessor :network_state
  
  def initialize
    ## logger for debug
    @log = Log4r::Logger["coregame_log"]
    # store pg_items. key uses the game pending index
    @pg_data_table = {}
    @gameview_data_table = {}
    # store data from the last pg_list message. Each item is also an array
    # e.g. [ ["1","Pioppa", "Mariazza", "4 segni, vittoria 41"],... ]
    @last_parsed_pglist_data = []
    @last_parsed_gameview_data = []
    # store the list of a user
    @last_parsed_userlist_data = []
    # user list hash where the nickname is a key
    @userlist_table = {}
    # observer list, hash with key the name to identify observer and as argument the observer
    @observ_list = {}
    # initial state
    @network_state = :state_init
  end
  
  ##
  # Add an observer to the state change notification
  # obs: observer instance
  # name: observer name
  def add_observer(name, obs)
    @observ_list[name] = obs
  end
  
  def remove_observer(name, obs)
    @observ_list[name] = nil
  end
  
  ##
  # Reset all data collected during a network session
  def reset_data
    @pg_data_table = {}
    @gameview_data_table = {}
    @userlist_table = {}
    @last_parsed_pglist_data = []
    @last_parsed_userlist_data = []
  end
  
  ##
  # Parse message user_add
  # msg_details: message detail, something like: "pioppa,4,G,-"
  def parse_user_add(msg_details)
    raw_data = msg_details.split(",")
    unless raw_data.size == 4
      return nil
    end
    user_info_hash = {:name => raw_data[0], 
            :lag => raw_data[1], :type => raw_data[2], :stat => raw_data[3]}
    
    nick = user_info_hash[:name]
    @userlist_table[nick] = user_info_hash
    return nick     
  end
  
  ##
  # Add a pg_item.
  # info: an hash with options (e.g. {:index => ix, :user => user, :game => gamesym, 
  #                 :prive => bprive, :class => bclass, :opt_game => opt_game, :players =>[pioppa]})
  def parse_list2add_pg(info)
    if info.class != Hash
      @log.error("add_pgitem2 message format wrong because is not an hash.")
      return 
    end
    
    ix_gp = info[:index]
    if ix_gp
      record = info
      @log.debug "add pg_item with index #{ix_gp}"
      @pg_data_table[ix_gp] = record
    else
      @log.error "pg_item without a valid index"
    end
    return ix_gp
  end
  
  def parse_list2add_gameview(info)
    if info.class != Hash
      @log.error("parse_list2add_gameview message format wrong because is not an hash.")
      return 
    end
    
    ixgame = info[:index]
    if ixgame
      record = info
      @log.debug "add gameview with index #{ixgame}"
      @gameview_data_table[ix_gp] = record
    else
      @log.error "gameview without a valid index"
    end
    return ixgame
  end
   
  def get_record_pg2(ix_pg)
    return @pg_data_table[ix_pg]
  end
  
  def get_record_viewgame(ix)
    return @gameview_data_table[ix]
  end
  
  ##
  # Provides detailed information as hash of the requested user
  def get_record_username(user_name)
    return @userlist_table[user_name]
  end
    
  
  ##
  # Parse user list information. This is a little different from pg_items.
  # If you change the protocoll and you send more thant 4 field into a single
  # record, remember to change also record processing in this function.
  def parse_user_list(msg_details)
    # we expect records separated by ;
    eol_flag = false
    state = :data_slice
    records_part = msg_details.split(";")
    if records_part.size == 0
      @log.error("user_list format error")
      state = :error
      eol_flag = false
      return state, eol_flag
    end
    records_part.reverse!
    header_part = records_part.pop
  
    header_arr = header_part.split(",")
    if header_arr.size >= 2
      # a list is empty if the third elemt is the string "empty"
      # format is: "0,eof,empty"
      if header_arr[1] =~ /empty/
        # list is empty
        @log.debug("user_list is empty")
        state = :list_empty
        eol_flag = true
        return state, eol_flag
      end
    else
      @log.error("user_list header format error")
      state = :error
      eol_flag = false
      return state, eol_flag
    end

    #exams header
    list_ix = header_arr[0].to_i
    # check if it is the first list slice
    if list_ix == 0
       state = :first_slice
    end 

    # process records
    @last_parsed_userlist_data = []
    record_item = records_part.pop
    while record_item
      record_data = record_item.split(",")
      if record_data
        if record_data.size == 4
          user_info_hash = {:name => record_data[0], 
            :lag => record_data[1], :type => record_data[2], :stat => record_data[3]}
          @last_parsed_userlist_data <<  user_info_hash
          # update also the global pg_list
          nick = record_data[0]
          @userlist_table[nick] = user_info_hash
        else
          @log.warn "user_list: ignored record malformed #{record_item}"
        end 
      end
      record_item = records_part.pop
    end

    # insert recognized records
    if @last_parsed_userlist_data.size > 0
      @log.debug "user_list: recognized #{@last_parsed_userlist_data.size} users"
    else
      @log.error "user_list: no user found, but list not empty"
    end

    # if the list of pending game is terminated then request a list of user
    if header_arr[1] =~ /eof/
      eol_flag = true
    end
    return state, eol_flag
  end
  
  ##
  # Provide once data of the last parsed pglist 
  def get_last_pglist_data
    return @last_parsed_pglist_data
  end
  
  def get_last_viewgame_data
    return @last_parsed_gameview_data
  end
  
  ##
  # Provides last user parsed
  def get_last_users_parsed
    return @last_parsed_userlist_data
  end
  
  ##
  # Parse a pg item from a record inserted in the pg_list message
  # record_item: record row e.g. "33,pioppa,mariazza,<vittoria 61, segni 1>,{galu,toro}" 
  def parse_record_pglist(record_item)  
    # isolate options
    # NOTE: this parser works only if fields don't use  characters <>
    ## Chracters , and ; are available only in the option field
    fields_arr = record_item.split(/<.*>/)
    unless fields_arr.size == 2
      @log.error("record_item format error")
      return nil
    end
    ix_user_game_arr = fields_arr[0].split(",") 
    unless ix_user_game_arr.size == 3
      @log.error("record_item,ix_user_game_arr format error")
      return nil
    end
    record = []
    
    record << ix_user_game_arr[0] #ix_gp
    record << ix_user_game_arr[1] #user
    record << ix_user_game_arr[2] #game
    
    # options
    options = ""
    if record_item =~ /<(.*)>/
      # recognize options
      options = $1
    end
    record << options
    
    # player list connected to the game
    player_list = ""
    if fields_arr[1] =~ /\{(.*)\}/
      # recognize list of players
      player_list = $1
    end
    record << player_list
    
    return record
  end #end parse_record_pglist

  ##
  # Parse remove a pg item
  # msg_details: detailed message sent over the network
  def parse_list2remove_pg(info)
    ix_to_remove = info[:index]
    @pg_data_table.delete(ix_to_remove)
    return ix_to_remove
  end 
  
  def parse_list2remove_viewgame(info)
    ix_to_remove = info[:index]
    @gameview_data_table.delete(ix_to_remove)
    return ix_to_remove
  end
  
  ##
  # Parse user remove command
  # msg_details: detailed message sent over the network
  def parse_user_remove(msg_details)
    username = msg_details
    @userlist_table[username] = nil
    return username
  end 
  
  ##
  # An event was raised. State machine are usually implemented
  # using a case for each state and inside on each state when another
  # case for each event. 
  def event_cupe_raised(event)
    @log.debug "event_cupe_raised in state#{@network_state}, event: #{event}"
    case @network_state
    # STATE: INIT
      when :state_init
        case event
          when :ev_gui_controls_created
            state_no_network
        end
    # STATE: NO_NETWORK
      when :state_no_network
        case event
          when :ev_login_ok
            state_logged_on
          when :ev_start_local_game
            state_on_localgame
        end
    # STATE: ON_LOCALGAME
      when :state_on_localgame
        case event
          when :ev_gfxgame_end
            state_no_network
        end 
    # STATE: LOGGED_ON
      when :state_logged_on
        case event
          when :ev_start_network_game
            state_on_netgame
          when :ev_client_disconnected
            state_no_network
          when :ev_startupdate
            state_on_updateclient
        end
    # STATE: ON_UPDATECLIENT
      when :state_on_updateclient
        case event
          when :ev_update_terminated
            state_logged_on
          when :ev_client_disconnected
            state_no_network
        end
    # STATE: ON_NETGAME    
      when :state_on_netgame
        case event
          when :ev_gfxgame_end
            state_on_table_game_end
          when :ev_client_disconnected
            state_no_network
          when :ev_playerontable_leaved
            state_ontable_lessplayers
        end
    # STATE: ON_TABLE_GAME_END
      when :state_on_table_game_end
        case event
          when :ev_client_disconnected
            state_no_network
          when :ev_playerontable_leaved
            state_ontable_lessplayers
          when :ev_client_leave_table
            state_logged_on
          when :ev_start_network_game
            state_on_netgame
        end
    # STATE: ON_TABLE_LESSPLAYERS
      when :state_ontable_lessplayers
        case event
          when :ev_client_disconnected
            state_no_network
          when :ev_client_leave_table
            state_logged_on
        end
    end #end @network_state case

  end #end event_cupe_raised
  
  # when a state in the model changes, all observer are notified.
  # Notifications are:
  # ntfy_state_no_network, ntfy_state_on_localgame, ntfy_state_logged_on
  # ntfy_state_on_netgame, ntfy_state_on_table_game_end, 
  # ntfy_state_ontable_lessplayers
  def make_state_change_ntfy(meth_to_call)
    @observ_list.each do |name, obser|
      #p name
      #p obser
      next unless obser
      if obser.respond_to?(meth_to_call)
        obser.send(meth_to_call)
      else
        #crash
        @log.warn("Net_state: observer #{name} don't support method #{meth_to_call}")
      end 
    end
  end
  
  ##
  # There is no network communication
  def state_no_network
    @log.debug("Net_state: change to state state_no_network")
    @network_state = :state_no_network
    make_state_change_ntfy(:ntfy_state_no_network)
  end
  
  ##
  # Client is inide the update process
  def state_on_updateclient
    @log.debug("Net_state: change to state state_on_updateclient")
    @network_state = :state_on_updateclient
    make_state_change_ntfy(:ntfy_state_onupdate)
  end
  
  ##
  # Playing on against the local cpu
  def state_on_localgame
    @log.debug("Net_state: change to state state_on_localgame")
    @network_state = :state_on_localgame
    make_state_change_ntfy(:ntfy_state_on_localgame)
  end
  
  ##
  # Player logged on
  def state_logged_on
    @log.debug("Net_state: change to state state_logged_on")
    @network_state = :state_logged_on
    make_state_change_ntfy(:ntfy_state_logged_on)
  end
  
  ##
  # Playing  against remote user
  def state_on_netgame
    @log.debug("Net_state: change to state state_on_netgame")
    @network_state = :state_on_netgame
    make_state_change_ntfy(:ntfy_state_on_netgame)
  end
  
  ##
  # Network game is terminated. Now we can start a new one, continue to chat
  # or leave the table
  def state_on_table_game_end
    @log.debug("Net_state: change to state state_on_table_game_end")
    @network_state = :state_on_table_game_end
    make_state_change_ntfy(:ntfy_state_on_table_game_end)
  end
  
  ##
  # We are still on table but a player has leaved the table 
  def state_ontable_lessplayers
    @log.debug("Net_state: change to state state_ontable_lessplayers")
    @network_state = :state_ontable_lessplayers
    make_state_change_ntfy(:ntfy_state_ontable_lessplayers)
  end
 
  ##
  # Handler of pg_list2 message
  # msg_details: :type => :pgamelist | :userlist | :gameviewlist
  #           :slice => 0...N
  #           :detail => [{....pg_add2 hash ...}] stesso del messaggio pg_add2},..., ]
  #           }
  def parse_list2(msg_details)
    # we expect records separated by ;
    eol_flag = false
    state = :data_slice
    
    arr_pgs = msg_details[:detail]
    type_list = msg_details[:type]
    slice_nr = msg_details[:slice]
    slice_state = msg_details[:slice_state]
    
    if arr_pgs.size == 0
      # list is empty
      @log.debug("list2 is empty")
      state = :list_empty
      eol_flag = true
      return state, eol_flag
    end
    
    # check if it is the first list slice
    if slice_nr == 0
       state = :first_slice
    end 
    
    # process records
    if type_list == :pgamelist
      parse_list_msg_pg(arr_pgs)
    elsif type_list == :gameviewlist
      parse_list_msg_viewgames(arr_pgs)
    end
    
    # if the list of pending game is terminated set eol fflag
    if slice_state == :last
      eol_flag = true
    end
    return state, eol_flag
  end #end parse_pg_list_message2
  
private
  
  def parse_list_msg_pg(arr_pgs)
    @last_parsed_pglist_data = []
    arr_pgs.each do |pg_item|
      ix_gp = pg_item[:index]
      if ix_gp
        record = pg_item
        @last_parsed_pglist_data << record 
        # update also the global pg_list
        @pg_data_table[ix_gp] = record
      end
    end
    
    # insert recognized records
    if @last_parsed_pglist_data.size > 0
      @log.debug "pg_list: recognized #{@last_parsed_pglist_data.size} pg_item"
    else
      @log.error "pg_list: no pg_items found, but list not empty"
    end
  end
  
  def parse_list_msg_viewgames(arr_pgs)
    @last_parsed_gameview_data = []
      arr_pgs.each do |pg_item|
        ix_gp = pg_item[:index]
        if ix_gp
          record = pg_item
          @last_parsed_gameview_data << record 
          # update also the global pg_list
          @gameview_data_table[ix_gp] = record
        end
      end
  end
  
end #end ModelNetData





