# -*- coding: ISO-8859-1 -*-
#file: network_cockpit_view.rb

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'base/gfx_general/base_engine_gfx'


##
# Interface for network connection, join a game and create a new one
class NetworkCockpitView
  NUM_EMPTY_ROWS = 3
  
  def initialize(comment,  split_horiz_netw, gui_owner, controller, data_model)
    @net_controller = controller
    #store the gui control
    @cup_gui = gui_owner
    # data of the networ session
    @data_model = data_model
    @comment_init = comment
    # values for autoplaying
    @auto_gfx_settings = {}
    
    #--------------------- tabbook - start -----------------
    @tabbook = FXTabBook.new(split_horiz_netw, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_RIGHTTABS)
    @tab1 = FXTabItem.new(@tabbook, "Giochi",  @cup_gui.icons_app[:cardgame_sm])
    
    main_vertical = FXVerticalFrame.new(@tabbook, 
                           FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    
    @lbl_giochidisp = FXLabel.new(main_vertical, "", nil, JUSTIFY_LEFT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    # Table
    @table_games = FXTable.new(main_vertical, nil, 0,
      TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY|LAYOUT_FILL_X|LAYOUT_FILL_Y,
      0,0,0,0, 2,2,2,2)
      
    @table_games.visibleRows = 10
    @table_games.visibleColumns = 6
    @table_games.rowHeaderWidth = 50
    # suppose a maximun of 50 request of games at the begin
    # changes are handled using insertRows and  removeRows
    @table_games.insertColumns(0,7)
    # insert some empty rows to make it working if the user click on rows
    @table_games.insertRows(0,NUM_EMPTY_ROWS)
    @table_games.setColumnText(0, "Creato da")
    @table_games.setColumnText(1, "U")
    @table_games.setColumnText(2, "Gioco")
    @table_games.setColumnText(3, "T")
    @table_games.setColumnText(4, "C")
    @table_games.setColumnText(5, "Opzioni")
    @table_games.setColumnText(6, "Giocatori")
    
    @table_games.setColumnWidth(1,25)
    @table_games.setColumnWidth(3,25)
    @table_games.setColumnWidth(4,25)
    @table_games.setColumnWidth(5,170)
    @table_games.setColumnWidth(6,200)
    
    @table_games.stippleColor = FXRGB(0xfc, 0xd0, 0x04)
    
    # context menu
    @table_games.connect(SEL_RIGHTBUTTONRELEASE, method(:showTableContextMenu))
    
    # get selection changed event
    @table_games.connect(SEL_SELECTED, method(:table_games_sel_change)) 
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    #connect to server
    @bt_connect_to_server = FXButton.new(btframe, "Connetti", @cup_gui.icons_app[:icon_network], nil, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK)
    @bt_connect_to_server.iconPosition = (@bt_connect_to_server.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @bt_connect_to_server.connect(SEL_COMMAND) do |sender, sel, ptr|
      @cup_gui.mnu_network_con(nil,nil,nil)
    end
    
    
    # crea gioco command
    @bt_create_game = FXButton.new(btframe, "Crea",  @cup_gui.icons_app[:crea], nil, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK)
    @bt_create_game.iconPosition = (@bt_create_game.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @bt_create_game.connect(SEL_COMMAND, method(:bt_create_game))
    
    # partecipation button
    @partecipate_bt = FXButton.new(btframe, "Partecipa", @cup_gui.icons_app[:icon_start], nil, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK )
    @partecipate_bt.iconPosition = (@partecipate_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @selected_pg_ixgame = nil
    @partecipate_bt.connect(SEL_COMMAND, method(:bt_partecipate_game))
    @partecipate_bt.disable
    
    # disconnect game command
    @disconnect_bt = FXButton.new(btframe, "Disconnetti", @cup_gui.icons_app[:disconnect], nil, 0,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK)
    @disconnect_bt.iconPosition = (@disconnect_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @disconnect_bt.connect(SEL_COMMAND) do
      @cup_gui.mnu_close_serverconnection(nil,nil,nil)
    end
     
    @bt_connect_to_server.setDefault  
    @bt_connect_to_server.setFocus
    
    # (2)tab  - Utenti
    @tab2 = FXTabItem.new(@tabbook, "Utenti",  @cup_gui.icons_app[:giocatori_sm])
    main_vertical = FXVerticalFrame.new(@tabbook, 
                           FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    @lbl_user_list = FXLabel.new(main_vertical, "", nil, JUSTIFY_LEFT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    
    @tbl_users = FXTable.new(main_vertical, nil, 0,
      TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY|LAYOUT_FILL_X|LAYOUT_FILL_Y,
      0,0,0,0, 2,2,2,2)
      
    @tbl_users.visibleRows = 10
    @tbl_users.visibleColumns = 4
    @tbl_users.rowHeaderWidth = 50
    @tbl_users.insertRows(0,NUM_EMPTY_ROWS)
    @tbl_users.insertColumns(0,4)
    @tbl_users.setColumnText(0, "L")
    @tbl_users.setColumnText(1, "T")
    @tbl_users.setColumnText(2, "Stat")
    @tbl_users.setColumnText(3, "Nome")
    
    @tbl_users.setColumnWidth(0,30)
    @tbl_users.setColumnWidth(1,30)
    @tbl_users.setColumnWidth(2,60)
    @tbl_users.setColumnWidth(3,220)
    
    # (3)tab  - Games on play
    @tab3 = FXTabItem.new(@tabbook, "Partite",  @cup_gui.icons_app[:eye])
    main_vertical = FXVerticalFrame.new(@tabbook, 
                           FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    @lbl_gamesonline = FXLabel.new(main_vertical, "", nil, JUSTIFY_LEFT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    
    @tbl_gamesonline = FXTable.new(main_vertical, nil, 0,
      TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY|LAYOUT_FILL_X|LAYOUT_FILL_Y,
      0,0,0,0, 2,2,2,2)
    
    @tbl_gamesonline.visibleRows = 10
    @tbl_gamesonline.visibleColumns = 3
    @tbl_gamesonline.rowHeaderWidth = 50
    @tbl_gamesonline.insertRows(0,NUM_EMPTY_ROWS)
    @tbl_gamesonline.insertColumns(0,4)
    @tbl_gamesonline.setColumnText(0, "Gioco")
    @tbl_gamesonline.setColumnText(1, "Giocatori")
    @tbl_gamesonline.setColumnText(2, "Spettatori")
    @tbl_gamesonline.setColumnText(3, "C")
    
    @tbl_gamesonline.setColumnWidth(0,80)
    @tbl_gamesonline.setColumnWidth(1,220)
    @tbl_gamesonline.setColumnWidth(2,220)
    @tbl_gamesonline.setColumnWidth(3,25)
    
    @tbl_gamesonline.connect(SEL_SELECTED, method(:tbl_gamesonline_sel_change))
    
     # view button
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    @viewgame_bt = FXButton.new(btframe, "Osserva", @cup_gui.icons_app[:eye], nil, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK )
    @viewgame_bt.iconPosition = (@viewgame_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    @selected_view_ixgame = nil
    @viewgame_bt.connect(SEL_COMMAND, method(:bt_view_game))
    @viewgame_bt.disable
    
    @tab3.hide # TODO: remove hide when game observer is implemented
    
    # --- tab generic information ---
    @tab1.tabOrientation = TAB_RIGHT
    @tab2.tabOrientation = TAB_RIGHT
    @tab3.tabOrientation = TAB_RIGHT
    
    @tabbook.setCurrent(0)
    #--------------------- tabbook - END -----------------
    
    ## logger for debug
    @log = Log4r::Logger["coregame_log"]
    #
  end
  
  ##
  # Set member variable using application settings
  def set_local_settings(app_settings)
    @auto_gfx_settings["auto_gfx"] = app_settings["autoplayer"][:auto_gfx]
    @auto_gfx_settings["auto_gamename_gfx"] =  app_settings["autoplayer"][:auto_gamename_gfx]
    @auto_gfx_settings[:current_game] = app_settings["curr_game"]
    @auto_gfx_settings[:auto_game_enabled]= app_settings["session"][:auto_create_game]
  end
  
  
  
  ##
  # Set buttons when network is not connected. State no network is reached.
  def ntfy_state_no_network
    # only connect is available
    clear_userlist_table
    clear_pgtable
    clear_viewgametable
    @bt_connect_to_server.enable
    @disconnect_bt.disable
    @partecipate_bt.disable
    @bt_create_game.disable
    
    @lbl_giochidisp.text = "NON CONNESSO"
    set_label_colors_no_network(@lbl_giochidisp)
    @lbl_user_list.text = "NESSUN UTENTE COLLEGATO"
    set_label_colors_no_network(@lbl_user_list)
    @lbl_gamesonline.text = "NESSUNA PARTITA IN GIOCO"
    set_label_colors_no_network(@lbl_gamesonline)
  end
  
  def set_label_colors_no_network(label)
    label.backColor = Fox.FXRGB(120, 120, 120)
    label.textColor = Fox.FXRGB(255, 255, 255)
  end
  
  def set_label_colors_loggedon(label)
    label.backColor = Fox.FXRGB(80, 250, 120)
    label.textColor = Fox.FXRGB(0, 0, 0)
  end
  
  def set_label_colors_lessplayers(label)
    label.backColor = Fox.FXRGB(220, 120, 120)
    label.textColor = Fox.FXRGB(0, 0, 0)
  end
  
  def set_label_colors_table_game_end(label)
    label.backColor = Fox.FXRGB(190, 190, 240)
    label.textColor = Fox.FXRGB(0, 0, 0)
  end
  
  def set_label_colors_table_on_netgame(label)
    label.backColor = Fox.FXRGB(120, 120, 240)
    label.textColor = Fox.FXRGB(0, 0, 0)
  end
  
  ##
  # State on network game is reached.
  def ntfy_state_on_netgame
    # avoid to use pending game
    clear_pgtable
    @partecipate_bt.disable
    @bt_create_game.disable
    set_label_colors_table_on_netgame(@lbl_giochidisp)
    set_label_colors_table_on_netgame(@lbl_user_list)
    set_label_colors_table_on_netgame(@lbl_gamesonline)
    
    @lbl_giochidisp.text = "In partita"
  end
  
  ##
  # State on table with game end
  def ntfy_state_on_table_game_end
    set_label_colors_table_game_end(@lbl_giochidisp)
    set_label_colors_table_game_end(@lbl_user_list)
    set_label_colors_table_game_end(@lbl_gamesonline)
    @lbl_giochidisp.text = "Seduto al tavolo"
    #@auto_gfx_settings["auto_gfx"]
    if @auto_gfx_settings["auto_gfx"]
      # autoplayer have to leave the table
      @net_controller.leave_table_cmd
    end
  end
  
  ##
  # State on table with game end
  def ntfy_state_ontable_lessplayers
    set_label_colors_lessplayers(@lbl_giochidisp)
    set_label_colors_lessplayers(@lbl_user_list)
    set_label_colors_lessplayers(@lbl_gamesonline)
    @lbl_giochidisp.text = "Seduto al tavolo e giocatori hanno abbandonato il tavolo"
  end
  
  ##
  # Set buttons when player is on localgame.
  # State local game is reached.
  def ntfy_state_on_localgame
    # all network operations are disabled
    @bt_connect_to_server.disable
    @disconnect_bt.disable
    @partecipate_bt.disable
    @bt_create_game.disable
  end
  
  ##
  # On update process
  def ntfy_state_onupdate
    @bt_connect_to_server.disable
    @disconnect_bt.enable
    @partecipate_bt.disable
    @bt_create_game.disable
  end
  
  ##
  # Set buttons when player is logged on
  def ntfy_state_logged_on
    # network player is logged on
    @bt_connect_to_server.disable
    @disconnect_bt.enable
    @partecipate_bt.disable
    @viewgame_bt.disable
    @bt_create_game.enable
    set_label_colors_loggedon(@lbl_giochidisp)
    set_label_colors_loggedon(@lbl_user_list)
    set_label_colors_loggedon(@lbl_gamesonline)
    auto_create_new_pg_game(@auto_gfx_settings)
  end
  
  ##
  # Context menu for games table
  def showTableContextMenu(source, selector, event)
    if @table_games.anythingSelected? then
        ix_pg = @table_games.getItemData(@table_games.selStartRow,0)
        if ix_pg
          popupMenu = FXMenuPane.new(source)
          FXMenuCommand.new(popupMenu, "Rimuovi gioco").connect(SEL_COMMAND,method(:remove_game_Row))      
          popupMenu.create
          popupMenu.popup(nil, event.root_x, event.root_y)
        end
    end
  end
  
  ##
  # User want to remove selected Pg game
  def remove_game_Row(source, selector, event)
    @log.debug 'remove_game_Row is called'
    if @selected_pg_ixgame
      row = @selected_pg_ixgame[:row]
      ix_pg = @table_games.getItemData(row,0)
      @log.debug "pg_remove_req: #{ix_pg}"
      @net_controller.send_pg_remove_req(ix_pg)
    end
  end

  def tbl_gamesonline_sel_change(sender, sel, ptr)
    table_pos = ptr
    ix_pg = @tbl_gamesonline.getItemData(table_pos.row,0)
    if ix_pg
      @selected_view_ixgame = {:index => ix_pg, :row => table_pos.row }
      @viewgame_bt.enable
      # this 2 lines below are used to select the full row
      @tbl_gamesonline.setAnchorItem(@tbl_gamesonline.currentRow, 0)
      @tbl_gamesonline.extendSelection(@tbl_gamesonline.currentRow, @tbl_gamesonline.numColumns-1, true) 
    else
      @selected_view_ixgame = nil
      @viewgame_bt.disable
    end 
  end
  
  ##
  # Event selection change in table
  # Note: if the user select the row, this event is called 3 time
  def table_games_sel_change(sender, sel, ptr)
    # in help is written: message data is an object FXTablePos
    # message data is ptr
    table_pos = ptr
    #p "Selected cell (row #{table_pos.row}, col #{table_pos.col})"
    #p "Selected row #{@table_games.selStartRow}"
    ix_pg = @table_games.getItemData(table_pos.row,0)
    if ix_pg
      # valid pending game index is selected
      @selected_pg_ixgame = {:index => ix_pg, :row => table_pos.row }
      @partecipate_bt.enable
      # this 2 lines below are used to select the full row
      @table_games.setAnchorItem(@table_games.currentRow, 0)
      @table_games.extendSelection(@table_games.currentRow, @table_games.numColumns-1, true) 
    else
      @selected_pg_ixgame = nil
      @partecipate_bt.disable
    end 
  end
  
  ##
  # User click to view a game on going
  def bt_view_game(sender, sel, ptr)
    if @selected_view_ixgame
      row = @selected_view_ixgame[:row]
      ix_viewgame = @tbl_gamesonline.getItemData(row,0)
      if ix_viewgame 
        msg_det = {:cmd => :start_view, :index =>  ix_viewgame}
        @log.debug "game_view: #{msg_det}"
        @net_controller.send_view_game(msg_det)
      else
        @selected_pg_ixgame = nil
        @partecipate_bt.disable
      end
    end
  end
 
  
  ##
  # User click on partecipate game button
  def bt_partecipate_game(sender, sel, ptr)
    if @selected_pg_ixgame
      row = @selected_pg_ixgame[:row]
      # check if the selection is on valid row
      ix_pg = @table_games.getItemData(row,0)
      game_data = @table_games.getItemData(row, 3)
      if game_data and game_data[:private] == true
        @log.debug "Try to join a private game"
        dlg = DlgJoinPrivate.new(@cup_gui, "Pin per il gioco privato")
        if dlg.execute != 0 and ix_pg 
          pin = dlg.get_pin 
          @log.debug "pg_join_pin: #{ix_pg},#{pin}"
          @net_controller.send_join_pin_pg(ix_pg, pin)
        end
        return 
      end 
      if ix_pg 
        msg_det = "#{ix_pg}"
        @log.debug "pg_join: #{msg_det}"
        @net_controller.send_join_pg(msg_det)
      else
        @selected_pg_ixgame = nil
        @partecipate_bt.disable
      end
    end
  end
  
  ##
  # Create a new game
  def bt_create_game(sender, sel, ptr)
    supp_games = @cup_gui.get_supported_games
    # uncomment below if you want to test more games 
    #supp_games = {
    #:mariazza_game => {:name => "Mariazza",
                       #:opt =>{:target_points_segno => 41, :num_segni_match => 1}
                     #},
    #:briscola_game => {:name => "Briscola",
                       #:opt =>{:target_points_segno => 61, :num_segni_match => 2}
                     #}
    #}
    dlg = DlgCreatePgGame.new(@cup_gui, @cup_gui,supp_games)
    if dlg.execute != 0
      info = dlg.get_create_options
      @log.debug "pg_create: #{info}"
      if dlg.is_private_game?
        pin = dlg.get_pin
        @log.debug "Private game with pin #{pin}" 
        @cup_gui.log_sometext("Creato un gioco privato con pin: #{pin}\n") 
      end
      @net_controller.send_create_pg2(info)  
    end
    
  end
  
  ##
  # Automatically create a new pending game request
  # opt: app settings 
  def auto_create_new_pg_game(opt)
    unless opt[:auto_game_enabled]
      # no auto stuff enabled
      return
    end
    supp_games = @cup_gui.get_supported_games
    game_det = supp_games[opt[:current_game]]
    if  game_det
      info = {
        :game => game_det[:name],
        :prive => {:val => false, :pin => "" },
        :class => true,
        :opt_game => game_det[:opt]
      }
      @net_controller.send_create_pg2(info) 
    else
      @log.warn "auto_create_new_game game not recognized"
    end
  end
  
  ##
  # Insert data in the table pg using interface 2
  def insert_data2(data_table)
    r_ix = 0
    data_table.each do |data_row|
      change_pg_row_data2(r_ix, data_row)
      r_ix += 1
    end
  end
  
  def insert_viewgame_data(data_table)
    r_ix = 0
    data_table.each do |data_row|
      change_viewgame_row(r_ix, data_row)
      r_ix += 1
    end
  end
  
  ##
  # Insert user information into the user table
  def insert_front_userdata(user_table)
    r_ix = 0
    user_table.each do |data_row|
      change_user_row_data(r_ix, data_row)
      r_ix += 1
    end
  end
   
  ##
  # Insert data using interface 2
  def pushfront_pgitem_data2(data_table)
    if data_table.size > 0
      @table_games.insertRows(0,data_table.size)
      insert_data2(data_table)
      update_number_pggames
    end
  end
  
  def pushfront_viewgames_data(data_table)
    if data_table.size > 0
      @tbl_gamesonline.insertRows(0,data_table.size)
      insert_viewgame_data(data_table)
      update_number_gameinprogress
    end
  end
  
  ##
  # Insert on the top users
  # user_table: array of array with user information
  def pushfront_users_data(user_table)
    if user_table.size > 0
      @tbl_users.insertRows(0,user_table.size)
      insert_front_userdata(user_table)
      update_number_of_players
    end
    #auto_create_new_pg_game
  end
  
  ##
  # Update display number of players
  def update_number_of_players
    num_of_players = @tbl_users.numRows - NUM_EMPTY_ROWS
    @lbl_user_list.text = "Lista degli utenti collegati (#{num_of_players})"
  end
  
  ##
  # Update display number of pending games
  def update_number_pggames
    num_of_games = @table_games.numRows - NUM_EMPTY_ROWS
    @lbl_giochidisp.text = "#{@comment_init} (#{num_of_games}):"
  end
  
  def update_number_gameinprogress
    num_of_games = @tbl_gamesonline.numRows - NUM_EMPTY_ROWS
    @lbl_gamesonline.text = "Partite in corso #{num_of_games}:"
  end
  
  ##
  # Change user information on a row in the user table
  # data_row: an hash with info about a user, look on col_key for all supported keys 
  def change_user_row_data(r_ix, data_row)
    col_key = {:name => 3, :lag => 0, :type => 1, :stat => 2 }
    @tbl_users.setItemData(r_ix,0,data_row[:name])
    data_row.each do |k, col_text|
      @tbl_users.setItemText(r_ix, col_key[k], col_text)
      @tbl_users.setItemJustify(r_ix, col_key[k], FXTableItem::LEFT)
    end
  end
  
  def change_viewgame_row(r_ix, info)
    supported_games = @cup_gui.get_supported_games
    # index
    index = info[:index]
    @tbl_gamesonline.setRowText(r_ix, "N.#{index}")
    @tbl_gamesonline.setItemData(r_ix,0,index)
    # games name
    gamename_key = info[:game_name]
    game_supported_info = supported_games[gamename_key]
    gamename = game_supported_info[:name]
    @tbl_gamesonline.setItemText(r_ix, 0, gamename.to_s)
    @tbl_gamesonline.setItemJustify(r_ix, 0, FXTableItem::LEFT)
    #players
    players = info[:players].join(",")
    @tbl_gamesonline.setItemText(r_ix, 1, players)
    @tbl_gamesonline.setItemJustify(r_ix, 1, FXTableItem::LEFT)
    #viewers
    viewers = info[:viewers].join(",")
    @tbl_gamesonline.setItemText(r_ix, 2, viewers)
    @tbl_gamesonline.setItemJustify(r_ix, 2, FXTableItem::LEFT)
    #isclassment
    is_relax = !info[:is_classmentgame]
    if is_relax == true
      @tbl_gamesonline.setItemIcon(r_ix, 3, @cup_gui.icons_app[:rainbow])
    else
      @tbl_gamesonline.setItemIcon(r_ix, 3, @cup_gui.icons_app[:rosette])
    end
  end
  
  ##
  # Add on the table the pending game information
  # row_ix: row index in the table to be changed
  # info: info hash about the game (e.g. {:index => ix, :user => pioppa, :game => gamesym, 
  #                 :prive => bprive, :class => bclass, :opt_game => opt_game, :players =>[pioppa]})
  def change_pg_row_data2(r_ix, info)
    # index
    index = info[:index]
    @table_games.setRowText(r_ix, "N.#{index}")
    @table_games.setItemData(r_ix,0,index)
    # creator 
    user = info[:user]
    @table_games.setItemText(r_ix, 0, user.to_s)
    @table_games.setItemJustify(r_ix, 0, FXTableItem::LEFT)
    # gioco
    gioco = info[:game]
    @table_games.setItemText(r_ix, 2, gioco.to_s)
    @table_games.setItemJustify(r_ix, 2, FXTableItem::LEFT)
    #options
    str_opt = options_to_humanstring(info[:opt_game])
    @table_games.setItemText(r_ix, 5, str_opt.to_s)
    @table_games.setItemJustify(r_ix, 5, FXTableItem::LEFT)
    
    #players
    giocatori = info[:players].join(",")
    @table_games.setItemText(r_ix, 6, giocatori.to_s)
    
    is_private = info[:prive]
    is_relax = !info[:class]
    if is_private == true
      @table_games.setItemIcon(r_ix, 3, @cup_gui.icons_app[:lock])
      @table_games.setItemData(r_ix, 3, {:private => is_private})
    end
    if is_relax == true
      @table_games.setItemIcon(r_ix, 4, @cup_gui.icons_app[:rainbow])
    else
      @table_games.setItemIcon(r_ix, 4, @cup_gui.icons_app[:rosette])
    end
    if info[:user_type] == :computer
      @table_games.setItemIcon(r_ix, 1, @cup_gui.icons_app[:computer])
    elsif info[:user_type] == :female
      @table_games.setItemIcon(r_ix, 1, @cup_gui.icons_app[:user_female])
    else
      @table_games.setItemIcon(r_ix, 1, @cup_gui.icons_app[:user])
    end
  end
  
  ##
  # Provides a huma version of game option hash
  # optgame: option game hash (e.g {:target_points=>{:type=>:textbox, :name=>"Punti vittoria", :val=>21}})
  def options_to_humanstring(optgame)
    arr_res = [] 
    optgame.each do |k,v|
      valore = v[:val]
      valore = "Si" if valore == true
      valore = "No" if valore == false
      arr_res << "#{v[:name]} : #{valore}"
    end
    strres = arr_res.join(";")
    return  strres 
  end
    
  ##
  # Delete all entries in table control
  def clear_pgtable
    @table_games.removeRows(0, @table_games.numRows - NUM_EMPTY_ROWS)
    @partecipate_bt.disable
    update_number_pggames
  end
  
  def clear_viewgametable
    @tbl_gamesonline.removeRows(0, @tbl_gamesonline.numRows - NUM_EMPTY_ROWS)
    @viewgame_bt.disable
    update_number_gameinprogress
  end
  
  ##
  # Delete all entries in the user table
  def clear_userlist_table
    @tbl_users.removeRows(0, @tbl_users.numRows - NUM_EMPTY_ROWS)
    update_number_of_players
  end
  
 
  ##
  # Remove a pending game in the table with index ix_to_remove
  # ix_to_remove: integer to be used whe we serach entry on the table widget
  def table_remove_pg_game(ix_to_remove)
    (0..@table_games.numRows-1).each do |r_ix|
      ixpg_on_row = @table_games.getItemData(r_ix,0)
      if ixpg_on_row.to_i == ix_to_remove
        @log.debug "Remove row #{r_ix} with data #{ixpg_on_row} and caption #{@table_games.getRowText(r_ix)}"
        @table_games.removeRows(r_ix, 1)
        update_number_pggames
        return
      end
    end
  end
  
  def table_remove_viewgame(ix_to_remove)
    (0..@tbl_gamesonline.numRows-1).each do |r_ix|
      ixpg_on_row = @tbl_gamesonline.getItemData(r_ix,0)
      if ixpg_on_row.to_i == ix_to_remove
        @log.debug "Remove row #{r_ix} with data #{ixpg_on_row} and caption #{@tbl_gamesonline.getRowText(r_ix)}"
        @tbl_gamesonline.removeRows(r_ix, 1)
        update_number_gameinprogress
        return
      end
    end
  end
  
  ##
  # Remove user from user table
  def table_remove_user(user_name)
    (0..@tbl_users.numRows-1).each do |r_ix|
      curr_row_name = @tbl_users.getItemData(r_ix,0)
      if curr_row_name == user_name
        @log.debug "Remove row #{r_ix} with user_name: #{curr_row_name}"
        @tbl_users.removeRows(r_ix, 1)
        update_number_of_players
        return
      end
    end
  end

  ##
  # Add pg item using pgadd2 messasge
  # ix_pg: pending game index into the data model
  def table_add_pgitem2(ix_pg)
    record = @data_model.get_record_pg2(ix_pg)
    unless record
      @log.error "table_add_pgitem2 can't find pending game #{ix_pg} on model"
      return 
    end
    # append new pg_item at the end, just before the three empty rows
    r_ix = @table_games.numRows - NUM_EMPTY_ROWS
    @table_games.insertRows(r_ix, 1)
    change_pg_row_data2(r_ix, record)
    update_number_pggames
  end
  
  def table_add_viewgame(ixgame)
    record = @data_model.get_record_viewgame(ixgame)
    unless record
      @log.error "table_add_viewgame can't find view game #{ixgame} on model"
      return 
    end
    # append new pg_item at the end, just before the three empty rows
    r_ix = @tbl_gamesonline.numRows - NUM_EMPTY_ROWS
    @tbl_gamesonline.insertRows(r_ix, 1)
    change_viewgame_row(r_ix, record)
    
    update_number_gameinprogress
  end
  
  ##
  # Add a new user name to the user table
  def table_add_userdata(user_name)
    record = @data_model.get_record_username(user_name)
    # append new user at the end, just before the three empty rows
    r_ix = @tbl_users.numRows - NUM_EMPTY_ROWS
    @tbl_users.insertRows(r_ix, 1)
    change_user_row_data(r_ix, record)
    update_number_of_players
  end
  
end 
