#file: prot_constants.rb

module ProtCommandConstants
  CRLF        = "\r\n"
  SUPP_COMMANDS = {
    :info => {:liter => "INFO", :cmdh => :cmdh_info},
    :ver => {:liter => "VER", :cmdh => :cmdh_ver}, 
    :submit_login => {:liter => "ASKLOGIN", :cmdh => :cmdh_asklogin}, 
    :login =>  {:liter => "LOGIN", :cmdh => :cmdh_login}, 
    :player_leave => {:liter => "PLAYERLEAVE", :cmdh => :cmdh_playerleave},
    :chat_lobby => {:liter => "CHATLOBBY", :cmdh => :cmdh_chatlobby},
    :chat_tavolo => {:liter => "CHATTAVOLO", :cmdh => :cmdh_chattavolo},
    :login_ok => {:liter => "LOGINOK", :cmdh => :cmdh_loginok},
    :login_error => {:liter => "LOGINERROR", :cmdh => :cmdh_loginerror},
    :player_reconnect => {:liter => "PLAYERRECONNECT", :cmdh => :cmdh_player_reconnect},
    
    # list
    :list2 => {:liter => "LIST2", :cmdh => :cmdh_list2},
    :list2_add => {:liter => "LIST2ADD", :cmdh => :cmdh_list2_add},
    :list2_remove => {:liter => "LIST2REMOVE", :cmdh => :cmdh_list2_remove},
    
    #pending games
    :pendig_games_req2 => {:liter => "PENDINGGAMESREQ2", :cmdh => :cmdh_pendig_games_req2},
    :pg_remove_req => {:liter => "PGREMOVEREQ", :cmdh => :cmdh_pg_remove_req},
    :pg_create2 => {:liter => "PGCREATE2", :cmdh => :cmdh_pg_create2},
    :pg_create_reject => {:liter => "PGCREATEREJECT", :cmdh => :cmdh_pg_create_reject},
    :pg_join => {:liter => "PGJOIN", :cmdh => :cmdh_pg_join},
    :pg_join_pin => {:liter => "PGJOINPIN", :cmdh => :cmdh_pg_join_pin},
    :pg_join_ok => {:liter => "PGJOINOK", :cmdh => :cmdh_pg_join_ok},
    :pg_join_tender => {:liter => "PGJOINTENDER", :cmdh => :cmdh_pg_join_tender},
    :pg_join_reject => {:liter => "PGJOINREJECT", :cmdh => :cmdh_pg_join_reject},
    :pg_join_reject2 => {:liter => "PGJOINREJECT2", :cmdh => :cmdh_pg_join_reject2},
    # view game
    :game_view => {:liter => "GAMEVIEW", :cmdh => :cmdh_game_view},
    # users
    :users_connect_req => {:liter => "USERSCONNECTREQ", :cmdh => :cmdh_users_connect_req},
    :user_list => {:liter => "USERLIST", :cmdh => :cmdh_user_list},
    :user_removed => {:liter => "USERREMOVED", :cmdh => :cmdh_user_removed},
    :user_add => {:liter => "USERADD", :cmdh => :cmdh_user_add},
    :user_list_unsub => {:liter => "USERLISTUNSUB", :cmdh => :cmdh_user_list_unsub},
    # algorithm callbacks
    :onalg_new_giocata => {:liter => "ONALGNEWGIOCATA", :cmdh => :cmdh_onalg_new_giocata},
    :onalg_new_match => {:liter => "ONALGNEWMATCH", :cmdh => :cmdh_onalg_new_match},
    :onalg_newmano => {:liter => "ONALGNEWMANO", :cmdh => :cmdh_onalg_newmano},
    :onalg_have_to_play => {:liter => "ONALGHAVETOPLAY", :cmdh => :cmdh_onalg_have_to_play},
    :onalg_player_has_played => {:liter => "ONALGPLAYERHASPLAYED", :cmdh => :cmdh_onalg_player_has_played},
    :onalg_player_has_declared => {:liter => "ONALGPLAYERHASDECLARED", :cmdh => :cmdh_onalg_player_has_declared},
    :onalg_pesca_carta => {:liter => "ONALGPESCACARTA", :cmdh => :cmdh_onalg_pesca_carta},
    :onalg_player_pickcards=> {:liter => "ONALGPICKCARDS", :cmdh => :cmdh_onalg_player_pickcards},
    :onalg_manoend => {:liter => "ONALGMANOEND", :cmdh => :cmdh_onalg_manoend},
    :onalg_giocataend => {:liter => "ONALGGIOCATAEND", :cmdh => :cmdh_onalg_giocataend},
    :onalg_game_end => {:liter => "ONALGGAMEEND", :cmdh => :cmdh_onalg_game_end},
    :onalg_player_has_changed_brisc => {:liter => "ONALGPLAYERHASCHANGEDBRISC", :cmdh => :cmdh_onalg_player_has_changed_brisc},
    :onalg_player_has_getpoints => {:liter => "ONALGPLAYERHASGETPOINTS", :cmdh => :cmdh_onalg_player_has_getpoints},
    :onalg_player_cardsnot_allowed => {:liter => "ONALGPLAYERCARDSNOTALLOWED", :cmdh => :cmdh_onalg_player_cardsnot_allowed},
    :onalg_player_has_taken => {:liter => "ONALGPLAYERHASTAKEN", :cmdh => :cmdh_onalg_player_has_taken},
    :onalg_new_mazziere => {:liter => "ONALGNEWMAZZIERE", :cmdh => :cmdh_onalg_new_mazziere},
    :onalg_gameinfo => {:liter => "ONALGGAMEINFO", :cmdh => :cmdh_onalg_gameinfo},
    # core game callbacks
    :alg_player_change_briscola => {:liter => "ALGPLAYERCHANGEBRISCOLA", :cmdh => :cmdh_alg_player_change_briscola}, 
    :alg_player_declare => {:liter => "ALGPLAYERDECLARE", :cmdh => :cmdh_alg_player_declare}, 
    :alg_player_cardplayed => {:liter => "ALGPLAYERCARDPLAYED", :cmdh => :cmdh_alg_player_cardplayed},
    :alg_player_cardplayed_arr => {:liter => "ALGPLAYERCARDPLAYEDARR", :cmdh => :cmdh_alg_player_cardplayed_arr},
    :gui_new_segno => {:liter => "GUINEWSEGNO", :cmdh => :cmdh_gui_new_segno},
    # net game agnostic  commands
    :resign_game => {:liter => "RESIGNGAME", :cmdh => :cmdh_resign_game},
    :restart_game => {:liter => "RESTARTGAME", :cmdh => :cmdh_restart_game},
    :restart_game_ntfy => {:liter => "RESTARTGAMENTFY", :cmdh => :cmdh_restart_game_ntfy},
    :leave_table => {:liter => "LEAVETABLE", :cmdh => :cmdh_leave_table},
    :leave_table_ntfy => {:liter => "LEAVETABLENTFY", :cmdh => :cmdh_leave_table_ntfy},
    :restart_withanewgame => {:liter => "RESTARTWITHNEWGAME", :cmdh => :cmdh_restart_withanewgame},
    # update commands
    :update_req => {:liter => "UPDATEREQ", :cmdh => :cmdh_update_req},
    :update_resp => {:liter => "UPDATERESP", :cmdh => :cmdh_update_resp},
    :update_resp2 => {:liter => "UPDATERESPTWO", :cmdh => :cmdh_update_resp2},
    # keep alive
    :ping_req => {:liter => "PINGREQ", :cmdh => :cmdh_ping_req},
    :ping_resp => {:liter => "PINGRESP", :cmdh => :cmdh_ping_resp},
    # errors
    :srv_error => {:liter => "SRVERROR", :cmdh => :cmdh_srv_error}      
  }
  
  SERVER_ERROR_INFO = {
    :generic_error => {:code => 0, :info => "Errore sul server generico"},
    :pg_remov_req_fail => {:code => 1, :info => "Errore nella rimozione del gioco"},
    :pg_remov_req_fail2 => {:code => 2, :info => "Non autorizzato a rimuovere il gioco"},
  }
  
end                
  
  
  