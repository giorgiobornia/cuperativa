# mariazza_gfx.rb
# Handle display for mariazza graphic engine

$:.unshift File.dirname(__FILE__)

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'base/gfx_general/gfx_elements'
require 'base/gfx_general/base_engine_gfx'
require 'core_game_mariazza'
require 'games/briscola/briscola_gfx'


##
# Class that manage the mariazza table gui
class MariazzaGfx < BriscolaGfx
  attr_accessor :option_gfx

  INFO_GFX_COORD = { :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
     :y_off_plgui_lx => 15, :y_off_plg_card => 10
  }
  
  MARIAZZA_NAME = {:mar_den => {:name_lbl => "Mariazza di denari"}, 
                     :mar_spa => {:name_lbl => "Mariazza di spade"},
                     :mar_cop => {:name_lbl => "Mariazza di coppe"},
                     :mar_bas => {:name_lbl => "Mariazza di bastoni"}
                   }
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @core_game = nil
    @splash_name = File.join(@resource_path, "icons/mariazza_title_trasp.png")
    @algorithm_name = "AlgCpuMariazza"  
    #core game name (created on base class)
    @core_name_class = 'CoreGameMariazza'
    
    # game commands
    @game_cmd_bt_list = []

    ## NOTE: don't forget to initialize variables also in ntfy_base_gui_start_new_game
  end
  
  ##
  # Give the current game the chance to build an own frame near to the canvas
  def set_canvas_frame(canvasFrame_wnd)
    canvasFrame = FXVerticalFrame.new(canvasFrame_wnd, FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    canvasFrame.create
    
    #p "**** set frame..."
    if @game_cmd_bt_list.size > 0 
      # send canvas size changed
      @app_owner.activate_canvas_frame
      return
    end
    
    label_wnd = FXLabel.new(canvasFrame, "Comandi gioco  ", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    label_wnd.create
    
    bt_wnd_list = []
    bt_wnd_list << FXButton.new(canvasFrame, "uno", @app_owner.icons_app[:numero_uno], nil, 0,FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_BOTTOM|LAYOUT_LEFT,0, 0, 0, 0, 10, 10, 5, 5)
    bt_wnd_list <<  FXButton.new(canvasFrame, "due", @app_owner.icons_app[:numero_due], nil, 0,FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_BOTTOM|LAYOUT_LEFT,0, 0, 0, 0, 10, 10, 5, 5)
    bt_wnd_list << FXButton.new(canvasFrame, "tre", @app_owner.icons_app[:numero_tre], nil, 0,FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_BOTTOM|LAYOUT_LEFT,0, 0, 0, 0, 10, 10, 5, 5)
    
    bt_wnd_list.each do |bt_wnd|
      bt_wnd.iconPosition = (bt_wnd.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
      bt_hash = {:bt_wnd => bt_wnd, :status => :not_used}
      @game_cmd_bt_list << bt_hash
      bt_wnd.create
    end
    free_all_btcmd # hide all commands buttons
    
    # send canvas size changed
    @app_owner.activate_canvas_frame
  end
  
  ##
  # Free and hide all game specific cmd buttons
  def free_all_btcmd
    @game_cmd_bt_list.each do |bt| 
      bt[:bt_wnd].hide
      bt[:bt_wnd].enable
#  bt[:bt_wnd].show #only for test
      bt[:status] = :not_used
    end
    #@app_owner.deactivate_canvas_frame
  end
  
  ##
  # Add more components to be displayed
  def add_components_tocompositegraph
    # smazzata end
    @msgbox_smazzataend = MsgBoxComponent.new(@app_owner, @core_game, @option_gfx[:timeout_msgbox], @font_text_curr[:medium])
    if @option_gfx[:autoplayer_gfx]
      @msgbox_smazzataend.autoremove = true
    end
    @msgbox_smazzataend.box_pos_x = 300
    @msgbox_smazzataend.box_pos_y = 150
    @msgbox_smazzataend.build(nil)
    @composite_graph.add_component(:smazzata_end, @msgbox_smazzataend)
  end
  
  ##
  # Shows a dilogbox for the end of the smazzata
  def show_smazzata_end(best_pl_points )
    @log.debug "Show smazzata end dialogbox"
    str = "** Segno terminato: vince #{best_pl_points.first[0]} col punteggio #{best_pl_points.first[1]} a #{best_pl_points[1][1]}\n"
    log str
   
    if @option_gfx[:use_dlg_on_core_info]
      @msgbox_smazzataend.show_message_box("Smazzata finita", str.gsub("** ", ""), true)
      @msgbox_smazzataend.set_visible(true)
    end
    
  end
 
  ##
  # Notification that on the gui the player has clicke on declaration button
  # params: array of parameters. Expect player as first item and declaration as second.
  def onBtPlayerDeclare(params)
    player = params[0]
    name_decl = params[1]
    @core_game.alg_player_declare(player, name_decl )
  end
  
  ##
  # Notification that on the gui the player has clicked on command
  # change the briscola.
  # params: array of parameters. Expect player as first item. Follow the 
  #         briscola and the card on player hand(only the 7 is allowed) 
  def onBtPlayerChangeBriscola(params)
    player = params[0]
    card_briscola = params[1]
    card_on_hand = params[2]
    @core_game.alg_player_change_briscola(player, card_briscola, card_on_hand )
  end
  
  ############### implements methods of AlgCpuPlayerBase
  #############################################
  #algorithm calls (gfx is a kind of algorithm)
  #############################################
 
  ##
  # Provides the name of the mariazza declaration
  # name_decl: mariazza name as label (e.g :mar_den)
  def nome_mariazza(name_decl)
    return MARIAZZA_NAME[name_decl][:name_lbl]
  end
  
  ##
  # Player have to play
  # player: player that have to play
  # command_decl_avail: array of commands (hash with :name and :points) 
  # available for declaration
  def onalg_have_to_play(player,command_decl_avail)
    decl_str = ""
    #p command_decl_avail
    if player == @player_on_gui[:player]
      @log.debug("player #{player.name} have to play")
      free_all_btcmd()
      command_decl_avail.each do |cmd| 
        if cmd[:name] == :change_brisc
          # change briscola command
          decl_str += "possibile scambio briscola"
          # create command button to change the briscola
          create_bt_cmd("Cambia bri", 
         [ player, cmd[:change_briscola][:briscola], cmd[:change_briscola][:on_hand]  ], 
               :onBtPlayerChangeBriscola)
        else
          # mariazza declaration command
          decl_str += "#{nome_mariazza(cmd[:name])}, punti: #{cmd[:points]} "
          # create a button with the declaration of this mariazza
          create_bt_cmd(cmd[:name], [player, cmd[:name]], :onBtPlayerDeclare)
        end
      end
    end
    # mark player that have to play
    player_sym = player.name.to_sym
    @turn_playermarker_gfx[player_sym].visible = true
    
    log "Tocca a: #{player.name}.\n"
    if player == @player_on_gui[:player]
      @player_on_gui[:can_play] = true
       log "#{player.name} comandi: #{decl_str}\n" if command_decl_avail.size > 0
    else
      @player_on_gui[:can_play] = false
    end
    if @option_gfx[:autoplayer_gfx]
      # store parameters into a stack
      @alg_auto_stack.push(command_decl_avail)
      @alg_auto_stack.push(player)
      # trigger autoplay
      @app_owner.registerTimeout(@option_gfx[:timout_autoplay], :onTimeoutHaveToPLay)
      # suspend core event process untill timeout
      @core_game.suspend_proc_gevents
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ##
  # Create a new command in the game command pannel
  # params: array of parameters
  # cb_btcmd: callback implemented in the game gfx
  def create_bt_cmd(cmd_name, params, cb_btcmd)
    # get the cmd button ready to be used
    bt_cmd_created = get_next_btcmd()
    #p bt_cmd_created[:bt_wnd].methods
    #p bt_cmd_created[:bt_wnd].shown?
    bt_cmd_created[:name] = cmd_name
    bt_cmd_created[:bt_wnd].show
    #p bt_cmd_created[:bt_wnd].shown?
    bt_cmd_created[:bt_wnd].text = cmd_name.to_s
    bt_cmd_created[:bt_wnd].enable
    bt_cmd_created[:bt_wnd].connect(SEL_COMMAND) do
      bt_cmd_created[:bt_wnd].disable
      send(cb_btcmd, params)
    end
    
    # send canvas size changed
    @app_owner.activate_canvas_frame
  end
  
  ##
  # Provides the next free button
  def get_next_btcmd
    @game_cmd_bt_list.each do |bt|
      if bt[:status] == :not_used
        bt[:status] = :used 
        return bt
      end 
    end
    nil
  end
  
  ##
  # Player has changed the briscola on table with a 7
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    str_msg =  "#{player.name} ha scambiato [#{nome_carta_ita(card_on_hand)}] " + 
        "con  [#{nome_carta_ita(card_briscola)}]\n"
    log(str_msg) 
  
    # check if it was gui player
    if @player_on_gui[:player] == player
      log "Scambio briscola OK [#{nome_carta_ita(card_on_hand)}] -> [#{nome_carta_ita(card_briscola)}]\n"
      player_sym = player.name.to_sym
      @cards_players.swap_card_player(player_sym, card_on_hand,  card_briscola)
    else
      # other player has changed the briscola, shows a dialogbox
      if @option_gfx[:use_dlg_on_core_info]
        @msg_box_info.show_message_box("Briscola in tavola cambiata", str_msg, false)
      end 
    end
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    end
    
    #set the briscola with the card on player hand (the 7) 
    @deck_main.set_briscola(card_on_hand)
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ##
  # Player has played a card not allowed
  def onalg_player_cardsnot_allowed(player, cards)
    lbl_card = cards[0]
    log "#{player.name} ha giocato una carta non valida [#{nome_carta_ita(lbl_card)}]\n"
    @player_on_gui[:can_play] = true
  end
  
  
  ##
  # Player has declared a mariazza
  # player: player that has declared
  # name_decl: mariazza declared name (e.g :mar_den)
  # points: points of the declared mariazza
  def onalg_player_has_declared(player, name_decl, points)
    log "#{player.name} ha dichiarato #{nome_mariazza(name_decl)}\n"
    #if @player_on_gui[:player] == player
      #@app_owner.disable_bt(name_decl)
    #end
    str = "Il giocatore #{player.name} ha accusato la\n#{nome_mariazza(name_decl)}\n"
    str.concat("da #{points} punti") if points > 0
    if @option_gfx[:use_dlg_on_core_info]
      @msg_box_info.show_message_box("Mariazza accusata", str, false)
    end
    # adjourn points
    @cards_taken.adjourn_points(player, points)
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_declared(player, name_decl, points)
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ##
  # Player has become points. This usally when he has declared a mariazza 
  # as a second player 
  def onalg_player_has_getpoints(player,  points)
    log str =  "#{player.name} ha fatto #{points} punti di accusa\n"
    
    if @option_gfx[:use_dlg_on_core_info]
      @msg_box_info.show_message_box("Punti ricevuti", str, false)
    end
    
    # adjourn points
    @cards_taken.adjourn_points(player, points)
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_getpoints(player, points)
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ###
  ## Overwrite background
  #def on_draw_backgrounfinished(dc)
    #dc.foreground = @color_back_table
    #dc.fillRectangle(0, 0, @curr_canvas_info[:width], @curr_canvas_info[:height])
  #end
  
end
 

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,950,530)
  
  # start game using a custom deck
  deck =  RandomManager.new
  deck.set_predefined_deck('_Ab,_2c,_Ad,_Ac,_5b,_7b,_3c,_2d,_Rb,_3b,_5s,_2s,_3d,_5d,_Cd,_5c,_As,_Fs,_Fc,_Rc,_Fd,_2b,_4s,_Cb,_6b,_3s,_Rs,_6s,_4c,_6c,_7c,_4d,_Cc,_Fb,_Cs,_7s,_4b,_7d,_Rd,_6d',0)
  mainwindow.set_custom_deck(deck)
  # end test a custom deck
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu', nil, :cpu_local, 0)
  
  #mainwindow.app_settings["autoplayer"][:auto_gfx] = true
  
  mainwindow.init_gfx(MariazzaGfx, players)
  maria_gfx = mainwindow.current_game_gfx
  maria_gfx.option_gfx[:timeout_autoplay] = 50
  maria_gfx.option_gfx[:autoplayer_gfx_nomsgbox] = false
  
  theApp.run
end


