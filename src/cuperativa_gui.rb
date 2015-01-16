#cuperativa_gui.rb
# Startup file GUI application cuperativa client
# Start file 

$:.unshift File.dirname(__FILE__)

require 'rubygems'

require 'fox16'
require 'log4r'
require 'singleton' 
require 'socket'
require 'yaml'

require 'network/prot_parsmsg'
require 'network/client/control_net_conn'
require 'network/client/net_connect_dlg'
require 'network/client/net_createpg_dlg'
require 'network/client/net_joinprivate_dlg'
require 'network/client/net_ongame_cmds'
require 'network/client/client_updater'
require 'network/client/swupdate_dlg'
require 'network/client/chat_table_view'

require 'base/options/cuperat_options_dlg'
require 'network/client/model_net_conn'
require 'base/gfx_general/listgames_dlg'
require 'base/gfx_general/about_dlg'
require 'base/core/gameavail_hlp'
require 'base/gfx_general/gfx_gamewindow'
require 'base/gfx_general/modal_msg_box'
require 'base/core/sound_manager'


# other method could be inspect the  Object::PLATFORM or RUBY_PLATFORM
$g_os_type = :win32_system
begin
  require 'win32/sound'
  include Win32
rescue LoadError
  $g_os_type = :linux
end

include Log4r
include Fox

# scommenta le 3 linee seguenti per un debug usando la console
#require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
#Debugger.start
#debugger
## oppure per usare rudebug (ma non va)
#Debugger.wait_connection = true
#Debugger.start_remote


#publish a new game <mynewgame>:
# 1) create a new gfx class, core, alg in the sub directory games
# 2) Crea un file yaml game_info.yaml per il nuovo gioco
# 4) ? implement the init function delcared in yaml game_info.yaml (maybe, init_local_game should do it for all)
# 5) modifica il server
# 5.a) In cup_serv_core aggiungi un require nalgames/mynewgame
# 5.b) In cup_serv_core aggiungi il nuovo hash in @@games_available
# 5.c) Crea il file NalServer.... <mynewgame>

##
# Class for a fox gui Cuperativa 
class CuperativaGui < FXMainWindow
  attr_accessor :giochimenu, :settings_filename, :icons_app, :app_settings, :sound_manager
  attr_accessor :restart_need, :corelogger, :last_selected_gametype, :banned_words, :main_app
  
  
  include ModalMessageBox
  
  # aplication name
  APP_CUPERATIVA_NAME = "Cuperativa"
  # version string (if you change format, spaces points..., chenge also parser)
  VER_PRG_STR = "Ver 0.8.2 08112010"
  # yaml version, useful for restoring old version
  CUP_YAML_FILE_VERSION = '6.18'   # to be changed only when SETTINGS_DEFAULT_APPGUI structure is changed            
  # settings file
  FILE_APP_SETTINGS = "app_options.yaml"
  # logger mode
  LOGGER_MODE_FILE = "log_mode.yaml"
  LOGGER_MODE_FILE_VERSION = '1.1'
  
  # NOTE: changes on this structure (not value) also need a change  in versionyaml
  #       otherwise it could happens that after an update we load a yaml file with
  #       an incorrect layout
  SETTINGS_DEFAULT_APPGUI = { "guigfx" =>{ :ww_mainwin => 800,
                                           :hh_mainwin => 520,
                                           :splitter => 0,
                                           :splitter_log_network => 358,
                                           :splitter_network => 138,
                                           :splitter_horiz => 0}, 
                              "deck_name" => :piac,   # note:
                              "versionyaml" => CUP_YAML_FILE_VERSION, # change this version 
                                                      #if you change SETTINGS_DEFAULT_APPGUI
                              "curr_game" => :briscola_game,
                              "players" => [
                                  {:name => "Toro", :type => :human_local },  #1
                                  {:name => "Gino B.", :type => :cpu_local }, #2
                                  {:name => "Galu", :type => :cpu_local },    #3
                                  {:name => "Svarz", :type => :cpu_local },   #4
                                  {:name => "Piopa", :type => :cpu_local },   #5
                                  {:name => "Mario", :type => :cpu_local },   #6
                                  {:name => "Mino", :type => :cpu_local },    #7
                                  {:name => "Ricu", :type => :cpu_local },    #8
                                  {:name => "Torace", :type => :cpu_local },  #9
                                  {:name => "Miliu", :type => :cpu_local },    #10
                                  {:name => "Cavallin", :type => :cpu_local }    #11
                                  ],
                              "session" => {
                                :host_server => 'invido.it',
                                :port_server => 20606,
                                :login_name => '',
                                :password_login => '',
                                :password_saved => false,
                                :debug_server_messages => false,
                                :connect_type => :simple,
                                :auto_create_game => true,
                                :remote_web_srv_url => 'igor.railsplayground.com/cuperativa/cuperativa.xml',
                              },
                              "autoplayer" =>{
                                :auto_gfx => false,
                                :auto_gamename_gfx => :mariazza_game ,
                              },
                              "cpualgo" => {:predefined => false, :saved_game => '', :giocata_num => 0, :player_name => '' },
                              "web_http" => {:use_webconn => false, :use_proxy => false, :proxy_host=> '127.0.0.1', :proxy_port => 8080, :proxy_user => "", :proxy_pasw => "", :proxy_auth=> :basic },
                              "sound" => {:play_intro_netwgamestart => true, :use_sound_ongame => true},
                              "games" => {
                                  :briscola_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :mariazza_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :scopetta_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :spazzino_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :tombolon_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 590},
                                  :scacchi_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :briscolone_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                                  :tressette_game =>
                                  { :ww_mainwin => 997, :hh_mainwin => 701, :splitter => 544, :jump_distr_cards => false},
                                  :briscola5_game =>
                                  { :ww_mainwin => 900, :hh_mainwin => 701, :splitter => 541},
                              },
  }
  
  ##
  # Init controls
  def initialize(anApp)
    super(anApp, APP_CUPERATIVA_NAME, nil, nil, DECOR_ALL, 30, 20, 640, 480)
    @main_app = anApp 
    @app_settings = {}
    #@settings_filename =  File.join(File.dirname(__FILE__) + '/..', FILE_APP_SETTINGS)
    @settings_filename =  File.join(File.dirname(__FILE__), FILE_APP_SETTINGS)
    # initialize logger
    @corelogger = Log4r::Logger.new("coregame_log")
    # restart needed flag
    @restart_need = false
  
    @logger_mode_filename = File.join(File.dirname(__FILE__), LOGGER_MODE_FILE)
    @log_detailed_info = load_loginfo_from_file(@logger_mode_filename)
    @log_device_output = :default
    @log_device_output = @log_detailed_info[:shortcut][:val] if @log_detailed_info[:shortcut][:is_set]
    
    # don't use stdout because dos popup in windows is not pretty
    mylogfname = "cuperativa_app#{Time.now.strftime("%Y_%m_%d_%H_%M_%S")}.log" 
    curr_day = Time.now.strftime("%Y_%m_%d")
    log_base_dir_set = @log_detailed_info[:base_dir_log]
    base_dir_log = "#{log_base_dir_set}/#{curr_day}"
    FileUtils.mkdir_p(base_dir_log)
    
    if @log_device_output == :debug
      @corelogger.outputters << Outputter.stdout
      ## nei miei test voglio un log anche sul file
      out_log_name = File.join(base_dir_log,  mylogfname )
      FileOutputter.new('coregame_log', :filename=> out_log_name) 
      Logger['coregame_log'].add 'coregame_log'
    elsif @log_device_output == :nothing
      @corelogger.outputters.clear
    elsif @log_device_output == :default
      out_log_name = File.join(base_dir_log,  mylogfname )
      #out_log_name = File.expand_path(File.dirname(__FILE__) + "/../../#{mylogfname}")
      Log4r::Logger['coregame_log'].level = INFO
      FileOutputter.new('coregame_log', :filename=> out_log_name) 
      Log4r::Logger['coregame_log'].add 'coregame_log'
    end
    
    # load supported games
    @supported_game_map = {}
    load_supported_games
    
    # canvas painting event
    @canvast_update_started = false
    
    # array of button for command panel
    @game_cmd_bt_list = []
    
    # Menubar
    @menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    
    @giochimenu = FXMenuPane.new(self)
    @networkmenu = FXMenuPane.new(self)
    @updatemenu = FXMenuPane.new(self)
    helpmenu = FXMenuPane.new(self)
    
    # Menu Giochi
    # Defined in custom menu of gfx engine
    @menu_giochi_list = FXMenuCommand.new(@giochimenu, "Lista giochi...")
    @menu_giochi_list.connect(SEL_COMMAND, method(:mnu_giochi_list ))
    @menu_giochi_save = FXMenuCommand.new(@giochimenu, "Salva Partita")
    @menu_giochi_save.connect(SEL_COMMAND, method(:mnu_giochi_savegame ))
    @menu_giochi_end = FXMenuCommand.new(@giochimenu, "Fine Partita")
    @menu_giochi_end.connect(SEL_COMMAND, method(:mnu_maingui_fine_part ))
    
    # Menu Network
    @menu_netw_coll = FXMenuCommand.new(@networkmenu, "&Collegamento...")
    @menu_netw_coll.connect(SEL_COMMAND, method(:mnu_network_con ))
    @menu_netw_disc = FXMenuCommand.new(@networkmenu, "&Disconnetti")
    @menu_netw_disc.connect(SEL_COMMAND, method(:mnu_close_serverconnection))
    
    # Menu Update 
    @menu_update_check = FXMenuCommand.new(@updatemenu, "Controlla nuova versione in rete...")
    @menu_update_check.connect(SEL_COMMAND, method(:mnu_update_check ))
    @menu_update_patch = FXMenuCommand.new(@updatemenu, "Applica nuova versione...")
    @menu_update_patch.connect(SEL_COMMAND, method(:mnu_update_applypatch))
     
    #Menu Help
    @menu_help = FXMenuCommand.new(helpmenu, "&Help")
    @menu_help.connect(SEL_COMMAND, method(:mnu_cuperativa_help))
    @menu_info = FXMenuCommand.new(helpmenu, "Sulla #{APP_CUPERATIVA_NAME}...")
    @menu_info.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    #@menu_test = FXMenuCommand.new(helpmenu, "Test")
    #@menu_test.connect(SEL_COMMAND, method(:mnu_cuperativa_test))
    
    # Titles on menupanels 
    FXMenuTitle.new(@menubar, "&Giochi", nil, @giochimenu)
    FXMenuTitle.new(@menubar, "&Rete", nil, @networkmenu)
    FXMenuTitle.new(@menubar, "Aggiorna", nil, @updatemenu)
    FXMenuTitle.new(@menubar, "&Info", nil, helpmenu)
    
    ###  toolbar
    FXHorizontalSeparator.new(self, SEPARATOR_GROOVE|LAYOUT_FILL_X)
    vv_main = self
    toolbarShell = FXToolBarShell.new(self)
    toolbar = FXToolBar.new(vv_main, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
    @icons_app = {}
    @icons_app[:icon_app] = loadIcon("icona_asso_trasp.png")
    @icons_app[:icon_start] = loadIcon("start2.png")
    @icons_app[:icon_close] = loadIcon("stop.png")
    @icons_app[:card_ass] = loadIcon("asso_ico.png")
    @icons_app[:crea] = loadIcon("crea.png")
    @icons_app[:nomi] = loadIcon("nomi2.png")
    @icons_app[:options] = loadIcon("options2.png")
    @icons_app[:icon_network] = loadIcon("connect.png")
    @icons_app[:disconnect] = loadIcon("disconnect.png")
    @icons_app[:leave] = loadIcon("leave.png")
    @icons_app[:perde] = loadIcon("perde.png")
    @icons_app[:revenge] = loadIcon("revenge.png")
    @icons_app[:gonext] = loadIcon("go-next.png")
    @icons_app[:apply] = loadIcon("apply.png")
    @icons_app[:giocatori_sm] = loadIcon("giocatori.png")
    @icons_app[:netview_sm] = loadIcon("net_view.png")
    @icons_app[:cardgame_sm] = loadIcon("cardgame.png")
    @icons_app[:start_sm] = loadIcon("star.png")
    @icons_app[:listgames] = loadIcon("listgames.png")
    @icons_app[:info] = loadIcon("documentinfo.png")
    @icons_app[:ok] = loadIcon("ok.png")
    @icons_app[:forum] = loadIcon("forum.png")
    @icons_app[:home] = loadIcon("home.png")
    @icons_app[:mail] = loadIcon("mail.png")
    @icons_app[:help] = loadIcon("help_index.png")
    @icons_app[:lock] = loadIcon("lock.png")
    @icons_app[:rainbow] = loadIcon("rainbow.png")
    @icons_app[:icon_update] = loadIcon("update.png")
    @icons_app[:rosette] = loadIcon("rosette.png")
    @icons_app[:computer] = loadIcon("computer.png")
    @icons_app[:user] = loadIcon("user.png")
    @icons_app[:numero_uno] = loadIcon("digit_1_icon.gif")
    @icons_app[:numero_due] = loadIcon("digit_2_icon.gif")
    @icons_app[:numero_tre] = loadIcon("digit_3_icon.gif")
    @icons_app[:user_female] = loadIcon("user_female.png")
    @icons_app[:eye] = loadIcon("eye.png")
    setIcon(@icons_app[:icon_app])
    
    ##### Toolbar buttons
    # options button
    @btoptions= FXButton.new(toolbar, "\tOpzioni\tOptioni", @icons_app[:options], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btoptions.connect(SEL_COMMAND, method(:mnu_cuperativa_options))
    # info button
    @btinfo= FXButton.new(toolbar, "\tInfo\tInfo", @icons_app[:info], nil,0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)#,0, 0, 0, 0, 10, 10, 5, 5)
    @btinfo.connect(SEL_COMMAND, method(:mnu_cuperativa_info))
    
    # try to set a label on in the midlle of the toolbar
    @lbl_table_title = FXLabel.new(toolbar, "", nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X|JUSTIFY_CENTER_Y|LAYOUT_FILL_Y)
    
    # buttons for network and table
    @bt_net_viewselect = FXButton.new(toolbar, "Rete", @icons_app[:netview_sm],nil, 0,ICON_BEFORE_TEXT|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    @bt_net_viewselect.connect(SEL_COMMAND, method(:view_select_network))
    @bt_table_viewselect = FXButton.new(toolbar, "Inizio", @icons_app[:start_sm],nil, 0,ICON_BEFORE_TEXT|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    @bt_table_viewselect.connect(SEL_COMMAND, method(:view_select_table))
    ###### Toolbar end
    
    #--------------------- tabbook - start -----------------
    # Switcher
    @tabbook = FXTabBook.new(vv_main, nil, 0, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_LEFTTABS)#TABBOOK_BOTTOMTABS)
    @tabbook.connect(SEL_COMMAND, method(:tab_table_clicked))
    # (1)tab - chat table
    @tab1 = FXTabItem.new(@tabbook, "", @icons_app[:start_sm])
    
    # presentation zone
    # buttons
    center_pan = FXVerticalFrame.new(@tabbook, LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    
    btdetailed_frame = FXVerticalFrame.new(center_pan, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    
    
    # local game
    @btstart_button = FXButton.new(btdetailed_frame, "Gioca in Internet", icons_app[:icon_network], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btstart_button.connect(SEL_COMMAND, method(:mnu_network_con))
    @btstart_button.iconPosition = (@btstart_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    
    # change game
    @btgamelist = FXButton.new(btdetailed_frame, "Cambia gioco contro il computer", icons_app[:listgames], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btgamelist.connect(SEL_COMMAND, method(:mnu_giochi_list))
    @btgamelist.iconPosition = (@btgamelist.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    
    # network game
    @btnetwork_button = FXButton.new(btdetailed_frame, "Gioca contro il computer", icons_app[:icon_start], self, 0,
              LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @btnetwork_button.connect(SEL_COMMAND, method(:mnu_start_offline_game))
    @btnetwork_button.iconPosition = (@btnetwork_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # logger
    log_panel = FXHorizontalFrame.new(center_pan, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @logText = FXText.new(log_panel, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logText.editable = false
    @logText.backColor = Fox.FXRGB(231, 255, 231)
        
    # (2)tab - chat lobby network
    @tab2 = FXTabItem.new(@tabbook, "", @icons_app[:netview_sm])
    @split_horiz_netw = FXSplitter.new(@tabbook, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                       LAYOUT_FILL_Y|SPLITTER_HORIZONTAL|SPLITTER_TRACKING))
    
    
    sunkenFrame = FXHorizontalFrame.new(@split_horiz_netw, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    group2 = FXVerticalFrame.new(sunkenFrame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    @txtrender_lobby_chat = FXText.new(group2, self, 3, TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y) #FXTextField.new(group2,2, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @txtrender_lobby_chat.backColor = Fox.FXRGB(255, 250, 205)
    @txtrender_lobby_chat.textColor = Fox.FXRGB(0, 0, 0)
    
    matrix = FXMatrix.new(group2, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    @txtchat_lobby_line = FXTextField.new(matrix, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
    @txtchat_lobby_line.connect(SEL_COMMAND, method(:onBtSend_chat_lobby_text))
    
    # MODEL / VIEW / CONTROLLER
    
    # network control
    @control_net_conn = ControlNetConnection.new(self)
    # network state model
    @model_net_data = ModelNetData.new
    # network cockpit view
    group3 = FXVerticalFrame.new(@split_horiz_netw, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @splitter_ntw_log = FXSplitter.new(group3, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
                       LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_TRACKING))
    
    @network_cockpit_view = NetworkCockpitView.new("Giochi disponibili sul server", 
             @splitter_ntw_log, self, @control_net_conn, @model_net_data)
    @control_net_conn.set_model_view(@model_net_data, @network_cockpit_view) 
    # add observer for network state change notification
    @model_net_data.add_observer("cuperativa_gui", self)
    @model_net_data.add_observer("control_net", @control_net_conn)
    @model_net_data.add_observer("network_cockpit_view", @network_cockpit_view)
    
     # logger network
    log_panel_ntw = FXHorizontalFrame.new(@splitter_ntw_log, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @logTextNtw = FXText.new(log_panel_ntw, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logTextNtw.editable = false
    @logTextNtw.backColor = Fox.FXRGB(231, 255, 231)
    
    @tab1.tabOrientation = TAB_LEFT #TAB_BOTTOM
    @tab2.tabOrientation = TAB_LEFT #TAB_BOTTOM
    
    @tabbook.setCurrent(0)
    @bt_table_viewselect.state = STATE_DOWN
    #--------------------- tabbook - END -----------------
    
    # Make a tool tip
    FXToolTip.new(getApp(), TOOLTIP_NORMAL)
    
    # array of PlayerOnGame
    #@players_on_table = []
    ## number of players that play the current game
    #@num_of_players = 0
   
    # container of all installed gfx games
    @coll_game_gfx = {}
    
    # quit callback also when the user close the application using the window menu
    self.connect(SEL_CLOSE, method(:onCmdQuit))
    
    # last selected game type
    @last_selected_gametype = nil
    # timeout callback info hash
    @timeout_cb = {:locked => false, :queue => []}
    
    init_banned_words
    
    srand(Time.now.to_i)
    
    load_application_settings
    
    @dialog_sw = DlgSwUpdate.new(self, "Aggiorna software", "")
    
    @sound_manager = SoundManager.new
    
    if $g_os_type == :win32_system
      submit_idle_handler # on fxruby 1.6.6 on windows repeat => true is not available
    else
      # idle routine
      anApp.addChore(:repeat => true) do |sender, sel, data|
        if @control_net_conn
          @control_net_conn.process_next_server_message
        end
      end
    end
    
  end #end  initialize
  
  def self.prgversion
    return VER_PRG_STR
  end
  
  def submit_idle_handler
    tgt = FXPseudoTarget.new
    tgt.pconnect(SEL_CHORE, nil, method(:onChore))
    @main_app.addChoreOrig(tgt, 0)
  end
  
  def onChore(sender, sel, data)
    #p 'chore is called'
    if @control_net_conn
      @control_net_conn.process_next_server_message
    end
    submit_idle_handler
  end
  
  ##
  # Shows username on the title
  def show_username(str_name)
    self.title =  "#{APP_CUPERATIVA_NAME} - Utente: #{str_name}" 
    #@lbl_username.text = "#{@comment_init} - Utente: #{str_name}" 
  end
  
  def show_prg_name
    self.title =  "#{APP_CUPERATIVA_NAME} - #{VER_PRG_STR}"
  end
  ##
  # Button Start game was clicked
  # start the current offline selected game
  def mnu_start_offline_game(sender, sel, ptr)
    initialize_current_gfx(@last_selected_gametype)
    create_new_singlegame_window(:offline)
  end
  
  ##
  # game_network_type: :offline or :online
  def create_new_singlegame_window(game_network_type)
    game_info = @supported_game_map[@last_selected_gametype]
    options = {:game_network_type => game_network_type, :app_options => @app_settings,
        :model_data => @model_net_data,
        :game_type => @last_selected_gametype,
        :owner => self, :comment => game_info[:desc], 
        :num_of_players => game_info[:num_of_players],
        :control_net_conn => @control_net_conn,
        :gfx_enginename =>game_info[:class_name].to_s 
    }
    
    @singe_game_win =  CupSingleGameWin.new(options)
    @singe_game_win.create
    return @singe_game_win
  end
  
  ##
  # Init banned words
  def init_banned_words
    # to generate this array use the script server\banned\check_parole.rb
    tmp = ["QW5kaWNhcHBh\n", "QmFnYXNjaWE=\n", "YmFsZHJhY2Nh\n", "YmFsZHJhYw==\n", "YmFzdGFyZA==\n", "YmF0dG9uYQ==\n", "Ym9jY2hpbmFyYQ==\n", "Ym9jY2hpbm8=\n", "Ym9jY2hpbg==\n", "Y2FnYXJl\n", "Y2FnYXI=\n", "Y2FnYXRh\n", "Y2FnYXQ=\n", "Y2F6eg==\n", "Y2hpYXZpY2E=\n", "Y2l1Y2NpYW1p\n", "Y2l1Y2NpYQ==\n", "Y2x1YiBkZWwgZ2lvY28=\n", "Y2x1YiBnaW9jbw==\n", "Y2x1YmRlbGdpb2Nv\n", "Q29nbGlvbmU=\n", "Y29nbGlvbg==\n", "Y29ybnV0\n", "Y3JldGlubw==\n", "Y3JldGlu\n", "Y3VsYXR0b24=\n", "Q3Vsbw1kZWZpY2VudGU=\n", "RG93bg==\n", "ZGlvIGJvaQ==\n", "ZGlvIGNhbg==\n", "ZGlvIG1haWFs\n", "ZmFuY3Vsbw==\n", "Zmlub2NjaGlv\n", "Zm90dGVyZQ==\n", "Zm90dGVy\n", "Zm90dGk=\n", "Zm90dHV0\n", "ZnJlZ25h\n", "ZnJvY2k=\n", "ZnVjaw==\n", "aWdub3Jhbg==\n", "aW5jaGlhcHBldHQ=\n", "a2F6em8=\n", "bGVjY2FjdWxv\n", "bGVzYmljYQ==\n", "bGVzYmlj\n", "bWVyZGE=\n", "bWlnbm90dA==\n", "TWluY2hpYQ==\n", "TWluY2hpbw==\n", "bW9uZ29sb2lkZQ==\n", "TW9ydGFjY2k=\n", "bW9ydGFjYw==\n", "bmVncm8=\n", "bmVyY2hpYQ==\n", "bydjdWw=\n", "cGlybGE=\n", "cG9tcGluYXJh\n", "cG9tcGlubw==\n", "cG9tcGlu\n", "cG9yY2E=\n", "cG9yY28=\n", "cG9yYw==\n", "cmVjY2hpb25l\n", "cmVjY2hpb24=\n", "UmljY2hpb25l\n", "cmljY2hpb24=\n", "cmluY29nbGlvbml0bw==\n", "cm9tcGlwYWxsZQ==\n", "c2JvcnJh\n", "c2JvcnJvbmU=\n", "c2NhbGRhY2F6eg==\n", "U2NlbW8=\n", "c2NvcGFyZQ==\n", "c2NvcGFyIA==\n", "c2NvcmVnZ2lh\n", "c2NvcnJlZ2dpYQ==\n", "c2Nyb2Zh\n", "c2ZhY2NpbQ==\n", "c21hbmRyYXBwYQ==\n", "c29yY2E=\n", "c3BvbXBpbmE=\n", "c3Ryb256\n", "U3RydW56\n", "U3R1cGlkbw==\n", "c3R1cGlk\n", "c3VjY2hpYW1p\n", "c3VjY2hpYQ==\n", "c3VrYW1l\n", "c3VrYW1p\n", "c3VrYQ==\n", "c3Vra2lh\n", "dXR0YW5h\n", "VHJvaWE=\n", "dHJvbWJhcmU=\n", "dHJvbWJhcg==\n", "dWNjZWxsbw==\n", "VmFmZg==\n", "d3d3LmNsdWJkZWxnaW9jby5pdA==\n", "emlvIGNhbmU=\n", "em9jY29sYQ==\n"]
    @banned_words = []
    tmp.each{|e| @banned_words << Base64::decode64(e)}
  end
  
  ##
  # Send  lobby chat line to the server
  def onBtSend_chat_lobby_text(sender, sel, ptr)
    msg = @txtchat_lobby_line.text
    @banned_words.each do |word|
      msg.gsub!(word, "****")
    end
    @control_net_conn.send_chat_text(msg, :chat_lobby)
    @txtchat_lobby_line.text = ""
  end
  
  ##
  # Render text in the render lobby chat control
  def render_chat_lobby(msg)
    @txtrender_lobby_chat.text += msg
    # ugly autoscrolling... 
    @txtrender_lobby_chat.makePositionVisible(
              @txtrender_lobby_chat.rowStart(@txtrender_lobby_chat.getLength))
  end
  
  ##
  # Provides modaless dialogbox for update progress
  def get_sw_dlgdialog
    return @dialog_sw
  end
  
  
  ##
  # Load all supported games
  def load_supported_games
    @supported_game_map = InfoAvilGames.info_supported_games(@corelogger)
    #p @supported_game_map
    # execute require 'mygame'
    @app_settings[:games] = {}
    @supported_game_map.each_value do |game_item|
      if game_item[:enabled] == true
        # game enabled
        require game_item[:file_req]
        @corelogger.debug("Game #{game_item[:name]} is enabled")
        name_key = game_item[:name].downcase.to_sym
        @app_settings[:games][name_key] = game_item[:opt]
      end
    end
  end #end load_supported_games
  
  ##
  # Provides info about supported game
  def get_supported_games
    return @supported_game_map
  end
 
  ##
  # Set an initial text on table
  def initial_board_text
    @lbl_table_title.text = "Gioco selezionato: "
  end
  
  ##
  # Generic funtion for gfx game initialization
  def init_local_game(game_type)
    game_info = @supported_game_map[game_type]
    @lbl_table_title.text += game_info[:name]
    @num_of_players = game_info[:num_of_players]

  end
  
  ##
  # Notification from current gfx that game is started
  def ntfy_gfx_gamestarted 
    hide_startbutton
  end
  ##
  # Hide the start button
  def hide_startbutton
    @btstart_button.disable
  end
  
  # shows start button
  def show_startbutton
    @btstart_button.enable
  end
  
  ##
  # Register a timer. Register only one timer, all other are queued and submitted
  # after timeout
  # timeout: timeout time in milliseconds
  # met_sym_tocall: method to be called after timeout
  # met_notifier: object that implement method after timeout event
  #def registerTimeout(timeout, met_sym_tocall, met_notifier=@current_game_gfx)
  def registerTimeout(timeout, met_sym_tocall, met_notifier)
    #p "register timer for msec #{timeout}"
    unless @timeout_cb[:locked]
      # register only one timeout at the same time
      @timeout_cb[:meth] = met_sym_tocall
      @timeout_cb[:notifier] = met_notifier
      @timeout_cb[:locked] = true
      getApp().addTimeout(timeout, method(:onTimeout))
    else
      #@corelogger.debug("registerTimeout on timeout pending, put it on the queue")
      # store info about timeout in order to submit after  a timeout
      @timeout_cb[:queue] << {:timeout => timeout, 
                              :meth => met_sym_tocall, 
                              :notifier => met_notifier, 
                              :started => Time.now
      }
    end
  end
  
  ##
  # Timer exausted
  def onTimeout(sender, sel, ptr)
    #p "Timeout"
    #p @timeout_cb
    #@current_game_gfx.send(@timeout_cb)
    @timeout_cb[:notifier].send(@timeout_cb[:meth])
    # pick a queued timer
    next_timer_info = @timeout_cb[:queue].slice!(0)
    if next_timer_info
      # submit the next timer
      @timeout_cb[:meth] = next_timer_info[:meth]
      @timeout_cb[:notifier] = next_timer_info[:notifier]
      @timeout_cb[:locked] = true
      timeout_orig = next_timer_info[:timeout]
      # remove already elapsed time
      already_elapsed_time_ms = (Time.now - next_timer_info[:started]) * 1000
      timeout_adjusted = timeout_orig - already_elapsed_time_ms
      # minimum timeout always set
      timeout_adjusted = 10 if timeout_adjusted <= 0
      getApp().addTimeout(timeout_adjusted, method(:onTimeout))
      #@corelogger.debug("Timer to register found in the timer queue (Resume with timeout #{timeout_adjusted})")
    else
      # no more timer to submit, free it
      #@corelogger.debug("onTimeout terminated ok")
      @timeout_cb[:locked] = false
      @timeout_cb[:queue] = []
    end
    return 1
  end
 
  
  ##
  # Update the game canvas display
  def update_dsp
    #@canvas_disp.update
  end
  
  ##
  # Recalculate the canvas. This is needed when a new control is added
  # and the canvas need to be recalculated
  def activate_canvas_frame
    #@canvasFrame.show
    #@canvasFrame.recalc
    #@canvas_disp.recalc
  end
  
  def deactivate_canvas_frame
    #@canvasFrame.hide
    #@canvasFrame.recalc 
    #@canvas_disp.recalc if @canvas_disp
  end
  
  ##
  # Paint event on canvas
  def onCanvasPaint(sender, sel, event)
    
  end
  
  ##
  # Mouse left up event on canvas
  def onLMouseUp(sender, sel, event)
    #p 'onLMouseUp'
    #@current_game_gfx.onLMouseUp(event)
  end
  
  ##
  # Mouse left down event on canvas
  def onLMouseDown(sender, sel, event)
    #log_sometext("onLMouseDown\n")
    # @current_game_gfx.onLMouseDown(event)
  end
  
  def onLMouseMotion(sender, sel, event)
    #@current_game_gfx.onLMouseMotion(event)
  end
  
  ##
  # Size of canvas is changing
  def OnCanvasSizeChange(sender, sel, event)
    
  end
  
  # Load the named icon from a file
  def loadIcon(filename)
    begin
      #dirname = File.join(File.dirname(__FILE__), "/../res/icons")
      dirname = File.join(get_resource_path, "icons")
      filename = File.join(dirname, filename)
      icon = nil
      File.open(filename, "rb") { |f|
        if File.extname(filename) == ".png"
          icon = FXPNGIcon.new(getApp(), f.read)
        elsif File.extname(filename) == ".gif"
          icon = FXGIFIcon.new(getApp(), f.read)
        end
      }
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end
 
  ##
  #
  def detach
    super
    #@current_game_gfx.detach
  end
  
  ##
  # Load debug info from yaml file.
  # return the shortcut mode (:debug, :default, :nothing)
  def load_loginfo_from_file(fname)
    base_dir_log = File.expand_path( File.dirname(__FILE__) + "/../clientlogs" )
    info_hash = {:is_set_by_user => false, 
         :stdout => false, :logfile => false,
         :base_dir_log => base_dir_log, 
         :version => LOGGER_MODE_FILE_VERSION ,
         :level => INFO, :shortcut => {:is_set => false, :val =>  :default}}
    
    yamloptions = {}
    prop_options = {}
    yaml_need_to_be_created = true
    if File.exist?( fname )
      yamloptions = YAML::load_file(fname)
      if yamloptions.class == Hash
        if yamloptions[:version] == LOGGER_MODE_FILE_VERSION
          prop_options = yamloptions
          yaml_need_to_be_created = false
        end
      end
    end
    if yaml_need_to_be_created
      File.open( fname, 'w' ) do |out|
        YAML.dump( info_hash, out )
      end
    end
    
    log_info_detailed = {}
    info_hash.each do |k,v|
      if prop_options[k] != nil
        # use settings from yaml
        log_info_detailed[k] = prop_options[k]
      else
        # use default settings
        log_info_detailed[k] = v
      end
    end
     
    return log_info_detailed
  end
  
  def load_application_settings
    yamloptions = {}
    prop_options = {}
    yamloptions = YAML::load_file(@settings_filename) if File.exist?( @settings_filename )
    if yamloptions.class == Hash
      # check if the yaml file is up to date
      #p yamloptions["versionyaml"]
      #p SETTINGS_DEFAULT_APPGUI["versionyaml"]
      if yamloptions["versionyaml"] == SETTINGS_DEFAULT_APPGUI["versionyaml"]
        @corelogger.debug("Yaml file is uptodate")
        prop_options = yamloptions
      else
        @corelogger.debug("Yaml file is NOT for this client version, merge default with it")
        #set to the last version to avoid merge next time
        yamloptions["versionyaml"] = SETTINGS_DEFAULT_APPGUI["versionyaml"] 
        #p prop_options = merge_options(SETTINGS_DEFAULT_APPGUI, yamloptions)
        #exit
      end 
    end
    SETTINGS_DEFAULT_APPGUI.each do |k,v|
      if prop_options[k] != nil
        # use settings from yaml
        @app_settings[k] = prop_options[k]
      else
        # use default settings
        @app_settings[k] = v
      end
    end
    @app_settings[:games] = prop_options[:games] if prop_options[:games]
    # p @app_settings
  end
  
  def merge_options(default_settings, yamloptions)
    res = {}
    default_settings.each do |k,v|
      #p k
      if yamloptions[k] != nil 
        if v.class != Hash
          res[k] = yamloptions[k]
        else
          sub_key = merge_options(v, yamloptions[k])
          res[k] = sub_key 
        end 
      else
        res[k] = v
      end
    end
    return res
  end
  
  def refresh_settings
    @sound_manager.set_local_settings(@app_settings)
    @control_net_conn.set_local_settings(@app_settings)
    @network_cockpit_view.set_local_settings(@app_settings)
  end
  
  ##
  # Create the window and load initial settings
  def create
    @icons_app.each do |k,v|
      v.create
    end
    # local variables
    
    refresh_settings
       
    #splitter position
    gfxgui_settings = @app_settings['guigfx']
    @split_horiz_netw.setSplit(0, gfxgui_settings[:splitter_network]) if @split_horiz_netw
    @splitter_ntw_log.setSplit(0, gfxgui_settings[:splitter_log_network]) if @splitter_ntw_log
    
    # window size
    ww = gfxgui_settings[:ww_mainwin]
    hh = gfxgui_settings[:hh_mainwin]
    
    # continue to insert item into giochi menu
    FXMenuSeparator.new(@giochimenu)
    FXMenuCommand.new(@giochimenu, "Opzioni").connect(SEL_COMMAND, method(:mnu_cuperativa_options))
    FXMenuSeparator.new(@giochimenu)
    FXMenuCommand.new(@giochimenu, "&Esci").connect(SEL_COMMAND, method(:onCmdQuit))
    
    # Reposition window to specified x, y, w and h
    position(0, 0, ww, hh)
    
    # Create the main window and canvas
    super 
    # Show the main window
    show(PLACEMENT_SCREEN)
    
    # default game or last selected
    game_type = @app_settings["curr_game"]
    #p @supported_game_map
    # initialize only an enabled game. An enabled game is a supported game.
    # Game disabled are not in the @supported_game_map. This to avoid to build poperties and
    # custom widgets
    if @supported_game_map[game_type]
      if @supported_game_map[game_type][:enabled]
        initialize_current_gfx(game_type)
      end
    else
      # default game is not supported, initialize the first enable game
      @corelogger.debug("Default game not enabled, look for the first enabled one")
      @supported_game_map.each do |k, game_info_h|
        game_type = k
        if game_info_h[:enabled]
          initialize_current_gfx(game_type)
          break
        end
      end
    end
    log_sometext("Benvenuta/o nella Cuperativa versione #{VER_PRG_STR}\n")  
    log_sometext("Ora puoi giocare a carte in internet oppure giocare contro il computer.\n")
    @model_net_data.event_cupe_raised(:ev_gui_controls_created)  
  end
  
  
  
  def game_window_destroyed
    @corelogger.debug "Game window is destroyed"
    @singe_game_win = nil
    @control_net_conn.game_window_destroyed
  end
  
  ## 
  # Set a custom deck information. Used for testing code without changing source code
  def set_custom_deck(deck_info)
    @app_settings[:custom_deck] = { :deck => deck_info }
  end
  
  ##
  # Initialize current gfx selected. Current gfx is stored
  # into application settings
  # game_type: game type label (e.g :mariazza_game)
  def initialize_current_gfx(game_type)
    @last_selected_gametype = game_type
    # reset the title
    initial_board_text
    
    ##initialize a current local game
    init_local_game(game_type)
  end
  
  ##
  # Terminate current game
  def mnu_maingui_fine_part(sender, sel, ptr)
  end
  
  ##
  # Gui button state for table selected
  def tab_table_clicked(sender, sel, ptr)
    if ptr == 0
      # on table tab
      @bt_table_viewselect.state = STATE_DOWN
      @bt_net_viewselect.state = STATE_UP
    elsif ptr == 1
      # on network tab
      @bt_table_viewselect.state = STATE_UP
      @bt_net_viewselect.state = STATE_DOWN
    end
  end
  
  ##
  # Select view network
  def view_select_network(sender, sel, ptr)
    tab_table_clicked(0,0,1)
    @tabbook.setCurrent(1)
  end
  
  ##
  # Select view table
  def view_select_table(sender, sel, ptr)
    tab_table_clicked(0,0,0)
    @tabbook.setCurrent(0)
  end
  
  ##
  # Save the current match
  def mnu_giochi_savegame (sender, sel, ptr)
  end
  
  ##
  # Select the current game from all game list
  def mnu_giochi_list (sender, sel, ptr)
    dlg = DlgListGames.new(self,@supported_game_map, @last_selected_gametype)
    if dlg.execute != 0
      k = dlg.get_activatedgame_key
      initialize_current_gfx(k)
      log_sometext("Attivato il gioco #{@supported_game_map[k][:name]}\n") 
    end
  end
  
  ##
  # Shows Info dialogbox
  def mnu_cuperativa_info(sender, sel, ptr)
    #CRASH___________
    dlg = DlgAbout.new(self, APP_CUPERATIVA_NAME, VER_PRG_STR)
    dlg.execute
  end
  
  #def mnu_cuperativa_test(sender, sel, ptr)
    #@net_chat_table_view.show_panel
  #end
  
  #def mnu_cuperativa_test2(sender, sel, ptr)
    #@net_chat_table_view.hide_panel
  #end
  
  ##
  # Provides the help file path
  def get_help_path
    str_help_cmd = File.join(File.dirname(__FILE__), "../res/help/cuperativa.chm")
    return str_help_cmd
  end
  
  ##
  # Shows cuperativa manual
  def mnu_cuperativa_help(sender, sel, ptr)
    str_help_cmd = get_help_path
    target = File.expand_path(str_help_cmd)
    if $g_os_type == :win32_system
      target.gsub!("/", "\\")
      Thread.new{
        system "start \"test\" \"#{target}\""
      }
    else
      LanciaApp::Browser.run(str_help_cmd)
    end
  end
  
  ##
  # Shows options menu
  def mnu_cuperativa_options(sender, sel, ptr)
    unless @control_net_conn.options_changeable?
       FXMessageBox.information(self, MBOX_OK, "NOTA Opzioni", "Le opzioni saranno aggiornate solo all'inizio della prossima partita.")
    end
    dlg = CuperatOptionsDlg.new(self, @app_settings)
    dlg.execute
    refresh_settings
  end
  
  ##
  # Provides an array of integer parsing the string VER_PRG_STR
  # Expect similar to :VER_PRG_STR = "Ver 0.5.4 14042008"  
  def sw_version_to_int
    arr_str =  VER_PRG_STR.split(" ")
    ver_arr = arr_str[1].split(".")
    ver_arr.collect!{|x| x.to_i}
    return ver_arr
  end
  
  ##
  # Provides name of program and software version
  def get_nameprog_swversion
    nomeprog = APP_CUPERATIVA_NAME
    ver_prog = sw_version_to_int
    return nomeprog, ver_prog
  end
  
  ##
  # Check on remote server if a new udate is available
  def mnu_update_check(sender, sel, ptr)
    nomeprog = APP_CUPERATIVA_NAME
    ver_prog = sw_version_to_int
    @control_net_conn.check_update_forclient(nomeprog, ver_prog)
  end
  
  ##
  # Apply a local patch 
  def mnu_update_applypatch(sender, sel, ptr)
    loadDialog = FXFileDialog.new(self, "Applica aggiornamento")
    patterns = [ "Tgz (*.tar.gz)", "Cup (*.cup)", "All Files (*)"  ]
    loadDialog.setPatternList(patterns)
    if loadDialog.execute != 0
      @control_net_conn.apply_update_patch(loadDialog.filename)
    end
  end
  
  ##
  # Start connection with game server
  def mnu_network_con(sender, sel, ptr)
    info_conn_hash = {}
    @control_net_conn.prepare_info_conn_hash(info_conn_hash)
    connect_dlg = DialogConnect.new(self, "Server", info_conn_hash)
    connect_dlg.set_server_info
    if connect_dlg.execute != 0
      info_conn_hash = connect_dlg.getconn_info_hash
      @corelogger.debug("Connect with default server info")
      log_sometext "Comincia il collegamento col server di gioco di default...\n"
      if @control_net_conn.connect_to_server_remote(info_conn_hash)
        log_sometext "Connesso al server #{info_conn_hash[:host_server]} sulla porta #{info_conn_hash[:port_server]}\n"
      else
        # connecting to the last server is not possible, use balancer
        @corelogger.debug("Unable to connect the default server, try the web balancer")
        connect_dlg.set_server_info_with_webbalancer
        if connect_dlg.execute != 0
          info_conn_hash = connect_dlg.getconn_info_hash
          log_sometext "Comincia il collegamento col server di gioco...\n"
          if @control_net_conn.connect_to_server_remote(info_conn_hash)
            log_sometext "Connesso al server #{info_conn_hash[:host_server]} sulla porta #{info_conn_hash[:port_server]}\n"
          end
        end
      end 
    end
    return 1
  end
 
  ##
  # Menu close connection with the server
  def mnu_close_serverconnection(sender, sel, ptr)
    @corelogger.debug "Menu Close server connection"
    @control_net_conn.close_remote_srv_conn
  end
  
  
  
  ############### network control notification
  
  ##
  # Network controller notification : no network
  def ntfy_state_no_network
    @corelogger.debug "Controls for state no network"
    log_network "Non connesso al gioco in rete\n"
    show_prg_name
    #disable_chat_lobby(true)
    @menu_netw_disc.disable
    @menu_netw_coll.enable
    @btnetwork_button.enable
    #@btterminate.disable
    @btstart_button.enable
    @menu_giochi_save.disable
    @menu_giochi_end.disable
    @menu_update_check.disable
    @menu_giochi_list.enable
    @btgamelist.enable
    
    show_startbutton
  end
  
  def ntfy_state_onupdate
  end
  
  ##
  # Network controller notification : on local game
  def ntfy_state_on_localgame
    log_sometext "Partita locale in corso, rete disabilitata\n"
    @menu_netw_disc.disable
    @menu_netw_coll.disable
    @btnetwork_button.disable
    @menu_giochi_list.disable
    @btgamelist.disable
    #@btterminate.enable
    @btstart_button.disable
    @menu_giochi_save.enable
    @menu_giochi_end.enable
    
    @tabbook.setCurrent(0)
    tab_table_clicked(0,0,0)
  end
  
  ##
  # Network controller notification : on network game
  def ntfy_state_on_netgame
    # play a sound
    if @app_settings["sound"][:play_intro_netwgamestart]
      @sound_manager.play_sound(:play_intro_netwgamestart)
    end 
    @menu_update_check.disable
    log_sometext "Partita in rete iniziata\n"
    @lbl_table_title.text += ", gioco in rete [#{@control_net_conn.curr_user_name}]"
    # select chat tavolo
    @tabbook.setCurrent(0)
    tab_table_clicked(0,0,0)
  end
  
  ##
  # Network controller notification : logged on
  def ntfy_state_logged_on
    log_sometext "Collegamento OK - #{@control_net_conn.curr_user_name} pronto per partecipare o creare una partita \n"
    #disable_chat_lobby(false)
    @menu_giochi_list.disable
    @btgamelist.disable
    @menu_netw_disc.enable
    @menu_update_check.enable
    @menu_netw_coll.disable
    @btnetwork_button.disable
    #@btterminate.disable
    @btstart_button.disable
    @tabbook.setCurrent(1)
    tab_table_clicked(0,0,1)
    #hide_startbutton
    show_username(@control_net_conn.curr_user_name)
  end
  
  ##
  # Network controller notification : game is terminated, but stil seat on table
  def ntfy_state_on_table_game_end
  end
  
  ##
  # Network controller notification : sitting on table with less players as required
  def ntfy_state_ontable_lessplayers
  end
   
  # Provides the resource path
  def get_resource_path
    res_path = File.dirname(__FILE__) + "/../res"
    return File.expand_path(res_path)
  end
  
  def OnAppSizeChange(sender, sel, event)
    #set_splitterpos_onsize(width , height)
  end

  ##
  # Quit the application
  def onCmdQuit(sender, sel, ptr)
    if @singe_game_win != nil
      if !modal_yesnoquestion_box("Termina la Cuperativa?", "Partita in corso, vuoi davvero terminare il programma?")
        log_sometext "Utente non vuole terminare la partita\n" 
        #@current_game_gfx.game_end_stuff
        return 1
      else
        @singe_game_win.user_isgoing_toexit
      end
    end
    
    
    #p self.methods
    @corelogger.debug("onCmdQuit is called")
    @app_settings['guigfx'][:ww_mainwin] = self.width
    @app_settings['guigfx'][:hh_mainwin] = self.height
    @app_settings['guigfx'][:splitter_log_network] =  @splitter_ntw_log.getSplit(0)
    
    @app_settings["curr_game"] = @last_selected_gametype
    #network settings
    @control_net_conn.get_local_settings(@app_settings)
    # avoid write test code options
    @app_settings[:custom_deck] = nil
    # yaml file version
    @app_settings["versionyaml"] = CUP_YAML_FILE_VERSION
    
    #save settings in a yaml file
    #p @settings_filename
    File.open( @settings_filename, 'w' ) do |out|
      YAML.dump( @app_settings, out )
    end
    getApp().exit(0)
  end
 
  ##
  # Log text in the top window
  def log_sometext(msg)
    logCtrl = @logTextNtw
    logCtrl = @logText if @tabbook.getCurrent == 0
    log_msg_onctrl(msg, logCtrl)
  end
  
  def log_msg_onctrl(msg, logCtrl)
    logCtrl.text += msg
    logCtrl.makePositionVisible(logCtrl.rowStart(logCtrl.getLength))
  end
  
  def log_network(msg)
    log_msg_onctrl(msg, @logTextNtw)
  end
   
end


if $0 == __FILE__
  theApp = FXApp.new("CuperativaGui", "FXRuby")
  mainwindow = CuperativaGui.new(theApp)
  Log4r::Logger['coregame_log'].level = DEBUG
  if ARGV.size > 0
    nome = ARGV[0]
    mainwindow.login_name = nome
  end
  # test target, need always stdoutput
  #mainwindow.corelogger.outputters << Outputter.stdout 
  # start game using a custom deck
  #deck =  RandomManager.new
  #deck.set_predefined_deck('_6b,_Rc,_5d,_5s,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',0)
  #mainwindow.set_custom_deck(deck)
  # end test a custom deck
    
  # Handle interrupts to terminate program gracefully
  theApp.addSignal("SIGINT", mainwindow.method(:onCmdQuit))

  theApp.create
  
  theApp.run
  # scommenta questa parte se vuoi avere un log quando applicazione crash
  #begin
    #theApp.run
  #rescue => detail
    #err_name = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
    #fname = File.join(File.dirname(__FILE__), "err_app_#{err_name}.log")
    #File.open(fname, 'w') do |out|
      #out << "Program aborted on #{$!} \n"
      #out << detail.backtrace.join("\n")
    #end
  #end
end
