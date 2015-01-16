# -*- coding: ISO-8859-1 -*-
#file: net_ongame_cmds.rb

$:.unshift File.dirname(__FILE__) + '/../..'
require 'net_createpg_dlg'

##
# Manage GFX buttons and panel for server commands during the network game
# Buttons supported are: leave table, restart, abandon
class NetworkOnGameCmds
  
  ##
  # ctrlframe: frame where to put commands
  # gui_owner: cuperatia gui owner
  def initialize(ctrlframe, gui_owner, net_controller)
    # flag used to disable restart to another game
    @restart_another_game_enabled = false 
    
    @net_controller = net_controller
    @game_win = gui_owner
    @buttonFrame = FXVerticalFrame.new(ctrlframe, LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 10, 10)
    
    ## restart game button
    @bt_restart_game = FXButton.new(@buttonFrame, "Rivincita", @game_win.icons_app[:revenge], nil, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @bt_restart_game.connect(SEL_COMMAND) do |sender, sel, ptr|
      @net_controller.restart_game_cmd
    end
    @bt_restart_game.iconPosition = (@bt_restart_game.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    #restart to another game
    if @restart_another_game_enabled
      @bt_restart_toanother = FXButton.new(@buttonFrame, "Altra sfida", @game_win.icons_app[:crea], nil, 0,
        LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
      @bt_restart_toanother.connect(SEL_COMMAND) do |sender, sel, ptr|
        cup_gui = @game_win.cup_gui
        supp_games = cup_gui.get_supported_games
        dlg = DlgCreatePgGame.new(@game_win, cup_gui,supp_games)
        dlg.set_title("Scegli un altro gioco per la nuova sfida")
        if dlg.execute != 0
          info = dlg.get_create_options
          @log.debug "restart_withanewgame: #{info}"
          if dlg.is_private_game?
            pin = dlg.get_pin
            @log.debug "Private game with pin #{pin}" 
            @game_win.log_sometext("Sfida gioco privato con pin: #{pin}\n") 
          end
        
          @net_controller.send_restart_withanewgame(
                         {:type_req => :create,  
                          :detail => info})  
        end
      end
      @bt_restart_toanother.iconPosition = (@bt_restart_toanother.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    end
    
    ## resing game button
    @bt_resign_game = FXButton.new(@buttonFrame, "Abbandona", @game_win.icons_app[:perde], nil, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
    @bt_resign_game.connect(SEL_COMMAND) do |sender, sel, ptr|
      if @game_win.modal_yesnoquestion_box("Abbandona la partita?", "Partita in corso, vuoi davvero abbandonarla?")
        @net_controller.resign_game_cmd  
      end
    end
    @bt_resign_game.iconPosition = (@bt_resign_game.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    
    ## leave table button
    @bt_leave_table = FXButton.new(@buttonFrame, "Lascia", @game_win.icons_app[:leave], nil, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT )
    @bt_leave_table.connect(SEL_COMMAND) do |sender, sel, ptr|
      @net_controller.leave_table_cmd
      @game_win.leave_table_cmd
    end
    @bt_leave_table.iconPosition = (@bt_leave_table.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    #@bt_leave_table.disable
    
    @log = Log4r::Logger["coregame_log"]    
    
    #@buttonFrame.hide
  end
  
  def ntfy_state_no_network
    hide_panel
  end
  
  def ntfy_state_on_localgame
    hide_panel
  end
  
  def ntfy_state_on_netgame
    show_panel
    show_only_resign
  end
  
  def ntfy_state_logged_on
    hide_panel
  end
  
  def ntfy_state_on_table_game_end
    show_leave_and_restart 
  end
  
  def ntfy_state_ontable_lessplayers
    show_only_leave
  end
  
  def ntfy_state_onupdate
  end
  
  
  def hide_panel
    #@log.debug "hide network cmds panel"
    #@buttonFrame.hide
  end
  
  def show_panel
    @log.debug "show network cmds panel"
    #@buttonFrame.show
  end
  
  def show_only_leave
    @bt_resign_game.disable
    @bt_leave_table.enable
    @bt_restart_game.disable
    @bt_restart_toanother.disable if @bt_restart_toanother
  end
  
  def show_leave_and_restart
    @bt_resign_game.disable
    @bt_leave_table.enable
    @bt_restart_game.enable
    @bt_restart_toanother.enable if @bt_restart_toanother
  end
  
  def show_only_resign
    @bt_restart_game.disable
    @bt_restart_toanother.disable if @bt_restart_toanother
    @bt_resign_game.enable
    @bt_leave_table.disable
  end
end
