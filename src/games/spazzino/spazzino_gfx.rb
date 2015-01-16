# spazzino_gfx.rb
# Handle display for spazzino graphic engine

$:.unshift File.dirname(__FILE__)

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
  #$:.unshift File.expand_path('../..')
end

require 'base/gfx_general/gfx_elements'
require 'base/gfx_general/base_engine_gfx'
require 'base/gfx_comp/smazzata_mbox_gfx'
require 'core_game_spazzino'

##
# Spazzino Gfx implementation
class SpazzinoGfx < BaseEngineGfx
  attr_accessor :option_gfx
    
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @using_rotated_card = false
    @core_game = nil
    @splash_name = File.join(@resource_path, "icons/spazzino_title_trasp.png")
    
    # option for graphic engine on spazzino gfx
    @option_gfx = {
      :timout_manoend => 800, 
      :timeout_player => 400, # not used
      :timeout_manoend_continue => 200,
      :timeout_manoend_viewtaken => 900,
      :timeout_msgbox => 3000,
      :timeout_autoplay => 1000,
      :timeout_animation_cardtaken => 20,
      :timeout_animation_player => 20,
      :timeout_animation_cardplayed => 20,
      :timeout_animation_carddistr => 20,
      :timeout_reverseblit => 100,
      :timeout_lastcardshow => 1200,
      :carte_avvers => true,
      :use_dlg_on_core_info => true,
      # automatic player
      :autoplayer_gfx => false,
      # disappear msgbox after timeout when using automatic player
      :autoplayer_gfx_nomsgbox => true,
      :jump_distr_cards => false
    }
    @algorithm_name = "AlgCpuSpazzino"
    @splash_image = nil
    # draw handler for each state
    @graphic_handler[:on_splash] = :on_draw_splash
    @graphic_handler[:on_game] = :on_draw_game_scene
    @graphic_handler[:game_end] = :on_draw_game_scene
    
    # some gfx fix number
    @myINFO_GFX_COORD = { :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
      :y_off_plgui_lx => 15, :y_off_plg_card => 10
    }
    
    @model_canvas_gfx.info[:canvas] = {}
    # information about canvas layout offset
    @model_canvas_gfx.info[:info_gfx_coord] = { 
      :x_top_opp_lx => 20, :y_top_opp_lx => 30, 
      :y_off_plgui_lx => 15, :y_off_plg_card => 10
    } 
    
    # store information about player that it is using this gui
    @player_on_gui = {
      # player object
      :player => nil,
      # can player using the gui flag
      :can_play => false,
      # mano index (0 = initial, incremented when a player has correctly played )
      :mano_ix => 0,
      # state of multiple choice (:none => not active, :active_pl => active and card of player is selected, 
      # :active_pl_tbl => active, player card is selected and also table card )
      :mult_choice => {:state => :none, :cadr_pl => nil, :list => nil}
    }
    # grafic card images array for each player
    @cards_player_todisp = {}
    # gfxcards played on the current hand
    @cards_played_todisp = []
    # array of opponents
    @opponents_list = []
    # array of all players
    @players_on_match = []
    # turn markers, used to mark player that have to play
    @turn_playermarker_gfx = {}
    # infos on gfx_elements
    @canvas_gfx_info = {}
    # resource gfx loaded only for this game (e.g. :points_deck_img)
    @image_gfx_resource = {}
    # information about points
    @points_status = {}
    # player that who play the mano
    @mano_end_player_taker = nil
    # card played in the last mano
    @mano_end_cardplayed = nil
    # cards taken in the last mano
    @mano_end_card_taken = []
    # dialogbox
    @msg_box_info = nil
    # color to display when the game is terminated
    @canvas_end_color = Fox.FXRGB(128, 128, 128)
    # algorithm for autoplay on gfx
    @alg_auto_player = nil
    # stack for autoplay function
    @alg_auto_stack = [] 
    # points shower
    @points_image = nil
    # gfx elements (widget) stored on each player    
    # Widget stored are: :lbl_name, :lbl_status, :taken_card, :rectturn
    @player_gfx_info = {}
    # reversed card blitted
    @card_reversed_gfx = nil
   
    # table cards
    @table_cards_gfx = []
    # info for user last card taken
    @taken_card_info_last = {} 
    # widgets for last cards taken
    @cardslasttaken_todisp = []
    # network nal gfx, override default name
    @nal_client_gfx_name = 'NalClientSpazzinoGfx'
    # label array of cards on table
    @table_cards_lbl = [] 
    # cards animated for distribution. Store it for each player
    @cards_distr_animated = {}
    # current cards inside animation
    @distr_card_stack = []
    # mazziere
    @mazziere =  nil
    # actions stored in a saved game
    @action_queue = []
    # predifined flag
    @predifined_game = false
    # num of cards
    @num_of_cards = 3
    # initial cards on table
    @initial_cards_on_table  = 4
    # smazzata end messagebox
    @msgbox_smazzataend = nil
    
    @color_panel_points = Fox.FXRGB(255, 115, 115)
    @color_back_table = Fox.FXRGB(103, 203, 103)
    @color_signal = Fox.FXRGB(255, 255, 255)
    @color_player_marker = Fox.FXRGB(255, 255, 255)
    
    # NOTE: don't forget to initialize variables also in ntfy_base_gui_start_new_game
  end
 
 
  ##
  # Shows a splash screen
  def create_wait_for_play_screen
    @state_gfx = :on_splash
    unless @splash_image
      begin 
        # load the splash
        img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
        #img = FXPNGIcon.new(getApp, nil,IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
        FXFileStream.open(@splash_name, FXStreamLoad) { |stream| img.loadPixels(stream) }
        img.blend(@color_backround)
        img.create
        @splash_image = img
      rescue
        @log.error "ERROR on create_wait_for_play_screen: #{$!}"
      end    
    end
    @app_owner.update_dsp
  end 
 
  ##
  # Draw splash screen
  def on_draw_splash(dc, width, height)
    if @splash_image
      dc.drawImage(@splash_image, width / 2 - @splash_image.width / 2 , height / 2 - @splash_image.height / 2 )
    end
  end
  
   ##
  # Overwrite background
  def on_draw_backgrounfinished(dc)
    dc.foreground = @color_panel_points
    dc.fillRectangle(0, 0, 140,  @model_canvas_gfx.info[:canvas][:height])
    dc.foreground = @color_back_table
    dc.fillRectangle(141, 0,  @model_canvas_gfx.info[:canvas][:width] - 140,  @model_canvas_gfx.info[:canvas][:height])
  end
  
  ##
  # Draw static scene during game
  def on_draw_game_scene(dc,width, height)
    if @state_gfx == :game_end
      # game is terminated, make the background monochrome
      dc.foreground = @canvas_end_color
      dc.fillRectangle(0, 0,  @model_canvas_gfx.info[:canvas][:width],  @model_canvas_gfx.info[:canvas][:height])
    else
      # eventually overwrite background
      on_draw_backgrounfinished(dc)
    end
    
    #draw name of players and all other labels
    dc.foreground = @color_text_label 
    @labels_to_disp.each_value do |label|
      label.draw_label(dc)
    end
    
    #draw points
    if @points_image
      @points_image.draw_points(dc)
    end
    
    #draws player marker
    @turn_playermarker_gfx.each_value do |marker|
      marker.draw_marker(dc)
    end
    # using composite pattern
    @composite_graph.draw(dc)
  end
  
  ##
  # Canvas size has changed
  # width: new width
  # height: new height
  def onSizeChange(width,height)
    @model_canvas_gfx.info[:canvas] = {:height => height, :width => width,:pos_x => 0, :pos_y => 0 }
    if @state_gfx == :on_game
      # chage place for elements in game
      @players_on_match.each do |player|
        @cards_players.resize(player)
        player_sym = player.name.to_sym
        pl_type =  player.type
      
        # player name label 
        resize_gfxlabel_player(player_sym, pl_type)
        # cards taken small symbol
        @cards_taken.resize(player)
        
        # player turn marker
        resize_gfxmarker_player(player_sym, pl_type)
      end
      # cards on table resize
      #@table_cards_played.resize(nil)
      @table_cards_played.resize_with_info
      @deck_main.resize(nil)
      
      @cards_players.init_position_ani_distrcards
      resize_gfx_points(@players_on_match)
    end
  end
  
  ##
  # User click on card
  # card: cardgfx clicked on
  #def click_on_card(card)
  def evgfx_click_on_card(card)
    @log.debug "gfx: evgfx_click_on_card: #{card.lbl}"
    if @player_on_gui[:can_play] == true and card.visible and card.lbl != :vuoto
      if @player_on_gui[:mult_choice][:state] == :none
        # no multiple choice
        if @table_cards_played.is_click_on_table_card?(card)
          # user click on table card: ignore it
          @log.debug "Ignore click #{card.lbl} because is on table"
          return 
        end
        #click admitted
        card.blit_reverse = false
        
        # now check what we can take
        list_options = @core_game.which_cards_pick(card.lbl, @table_cards_lbl)
        if list_options.size <= 1
          # there are no choice of taking, than play it
          cards_played_taken = [card.lbl, list_options.first ].flatten
          cards_played_taken.delete(nil)
          #@player_on_gui[:ani_card_played_is_starting] = true
          allow = @core_game.alg_player_cardplayed_arr(@player_on_gui[:player], cards_played_taken)
          if allow == :allowed
            # on network game we are alway receiving :allowed before response, that
            # mean the client should be sure that it send a card :allowed
            # avoid to submit more played cards, just one
            # if we are on  game that have restriction on card played, e.g. tressette
            #  we have to check here. Waiting response from server it take too long
            @player_on_gui[:can_play] = false
            @sound_manager.play_sound(:play_click4)
            # start card played animation
            start_guiplayer_card_played_animation( @player_on_gui[:player], card.lbl, cards_played_taken)
            return # card clicked  was played correctly
          end
        else
          # Multiple choice not yet active
          multiplechoice_activate(card, list_options)
          @app_owner.update_dsp
          return
        end #list_options.size <= 1
      elsif @player_on_gui[:mult_choice][:state] == :active_pl_tbl or
            @player_on_gui[:mult_choice][:state] == :active_pl
        if card.is_selected?
          multiplechoice_click_ontablecard(card)
          return 
        elsif card.originate_multiplechoice?
          # click on the original played card, disasble multiple choice
          multiplechoice_deactivate
          return
        else
          # click on card ignored
          @log.debug "Ignore click multiple choice #{card.lbl}"
          return
        end
      end #@player_on_gui[:mult_choice] == :none
    end # @player_on_gui[:can_play] == true
    
    # if we reach this code, we have clicked on a card that is not allowed to be played
    @log.debug "Ignore click #{card.lbl} #{@player_on_gui[:can_play]}"
    unless @card_reversed_gfx
      # we have clicked on card that we can't play
      @card_reversed_gfx = card
      card.blit_reverse = true
      @card_reversed_gfx = card
      @app_owner.registerTimeout(@option_gfx[:timeout_reverseblit], :onTimeoutRverseBlitEnd)
      @app_owner.update_dsp
    end    
  end #end click_on_card
  
  ##
  # The player on the gui has played a card. Start the animation process
  # cards_played_and_taken: array with card played at position 0 and rest are cards taken
  def start_guiplayer_card_played_animation( player, lbl_card, cards_played_and_taken )
    @log.debug("gfx: start_guiplayer animation #{lbl_card}, #{cards_played_and_taken}")
    @player_on_gui[:ani_card_played_is_starting] = true
    player_sym = player.name.to_sym
    @cards_players.card_invisible(player_sym, lbl_card)
    #@table_cards_played.set_card_image_visible(0, lbl_card)
    #if cards_played_and_taken.size > 1
    #  @table_cards_played.correct_end_position_cardtaken(@model_canvas_gfx,
    #                             player,cards_played_and_taken[1..-1])
    #end
    #   
    #@table_cards_played.start_ani_played_card(0, 
    #                    @cards_players.last_cardset_info[:pos_x], 
    #                    @cards_players.last_cardset_info[:pos_y])
    
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    card_taken = []
    if cards_played_and_taken.size > 1
      card_taken = cards_played_and_taken[1..-1]
    end
    @table_cards_played.card_is_played2(lbl_card, player, card_taken, init_x, init_y)
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
    
    @app_owner.update_dsp
  end
  
   ##
  # Overrride method because we want to use @composite_graph mouse handler
  def onLMouseDown(event)
    @composite_graph.on_mouse_lclick(event) if @composite_graph
  end
  
  ##
  # User have to choose wich card want take. Go in state multiple choice active
  def multiplechoice_activate(card, list_options)
    @log.debug "gfx: Activate multiple choice #{card.lbl}, #{list_options}"
    @player_on_gui[:mult_choice][:cadr_pl] = card
    @player_on_gui[:mult_choice][:list] = list_options
    @player_on_gui[:mult_choice][:state] = :active_pl
    card.originate_multchoice = true
    @player_on_gui[:mult_choice][:card_selected] = nil
    multiplechoice_colorize_selection
    card.cd_data[:orig_pos_y] = card.pos_y
    card.pos_y = card.pos_y - 40           
  end
  
  ##
  # Deactivate multiple choice
  def multiplechoice_deactivate
    @log.debug "gfx: Deactivate multiple selection"
    @player_on_gui[:mult_choice][:state] = :none
    @table_cards_played.deactivate_border_sel
    card = @player_on_gui[:mult_choice][:cadr_pl] 
    card.originate_multchoice = false
    card.pos_y = card.cd_data[:orig_pos_y]
  end
  
  ##
  # In multiple choice user click on table card
  def multiplechoice_click_ontablecard(card_ontable_clicked)
    @log.debug "gfx: multiplechoice click on table card #{card_ontable_clicked.lbl}"
    list_active = []
    @player_on_gui[:mult_choice][:list].each do |list_item_arr|
      list_item_arr.each do |card_on_lst|
        if card_ontable_clicked.lbl ==  card_on_lst
          list_active << list_item_arr
        end
      end
    end
    # check if we need to stay in state multiple choice
    if list_active.size == 0
      # user click on card not selected, ignore it
      @log.debug "gfx: User click on card not selected (list_active size 0)"
      return
    elsif list_active.size == 1
      # now it we have defined the choice
      card_origin = @player_on_gui[:mult_choice][:cadr_pl]
      cards_played_taken = [card_origin.lbl, list_active.first ].flatten
      cards_played_taken.delete(nil)
      @log.debug "gfx: Card played and take are defined: #{card_origin.lbl} -> #{cards_played_taken}"
      #@player_on_gui[:ani_card_played_is_starting] = true
      allow = @core_game.alg_player_cardplayed_arr(@player_on_gui[:player], cards_played_taken)
      if allow == :allowed
        # on network game we are alway receiving :allowed before response, that
        # mean the client should be sure that it send a card :allowed
        # avoid to subit more played cards, just one
        # if we are on  game that have restriction on card played, e.g. tressette
        #  we have to check here. Waiting response from server it take too long
        @player_on_gui[:can_play] = false
        @sound_manager.play_sound(:play_click4)
        @table_cards_played.deactivate_border_sel
        @player_on_gui[:mult_choice][:state] = :none
        card_origin.pos_y = card_origin.cd_data[:orig_pos_y]
        # animation card played
        start_guiplayer_card_played_animation( @player_on_gui[:player], card_origin.lbl, cards_played_taken)
        return # card clicked  was played correctly
      end
    else
      # more choices are still available
      @log.debug "gfx: More choices are still available"
      @player_on_gui[:mult_choice][:list] = list_active
      @player_on_gui[:mult_choice][:card_selected] = card_ontable_clicked
      @player_on_gui[:mult_choice][:state] = :active_pl_tbl
      log "#{nome_carta_ita(card_ontable_clicked.lbl)}: carta ha combinazione multipla\n"
      multiplechoice_colorize_selection
    end
  end
  
  ##
  # Mark cards on table as selected using multiple choice data
  def multiplechoice_colorize_selection
    card = @player_on_gui[:mult_choice][:cadr_pl]
    list_options = @player_on_gui[:mult_choice][:list]
    card_activated = @player_on_gui[:mult_choice][:card_selected]
    @table_cards_played.multiplechoice_colorize_selection(card, list_options, card_activated)
   
  end
    
  ##
  # Reversed blit tmed on card is elapsed
  def onTimeoutRverseBlitEnd
    @card_reversed_gfx.blit_reverse = false
    @card_reversed_gfx = nil
    @app_owner.update_dsp
  end
  
  ##
  # Player leave the table
  # This is usually a network notification
  def player_leave(user_name)
    # when aplayer leave the game, his label becomes empty
    lbl_displ_pl = get_player_lbl_symbol(user_name)
    lbl_gfx = @labels_to_disp[lbl_displ_pl]
    if lbl_gfx
      lbl_gfx.text = "(Posto vuoto)"
      @app_owner.update_dsp
    else
      @log.warn("player_leave(GFX) don't have recognized player: #{user_name}")
    end
  end
  
  ##
  # Player on the table is ready to start a new game
  # This is usually a network notification
  # user_name: player name
  def player_ready_to_start(user_name)
    player_sym = user_name.to_sym
    lbl_gfx_status = @player_gfx_info[player_sym][:lbl_status] if  @player_gfx_info[player_sym]
    if lbl_gfx_status
      lbl_gfx_status.text = "pronto"
      lbl_gfx_status.font_color =  Fox.FXRGB(20, 10, 200)
    else
      @log.warn("player_ready_to_start(GFX) don't have recognized player: #{user_name}")
    end
  end
 
  ##
  # Spazzino is started. Notification from base class that gui want to start
  # a new game
  # players: array  of players. Players are PlayerOnGame instance
  # options: hash with game options, @app_settings from cuperativa gui
  def ntfy_base_gui_start_new_game(players, options)
    @log.debug "ongui_start_new_game"
    @card_reversed_gfx = nil
    @opponents_list = []
    @players_on_match = []
    @labels_to_disp = {}
    @turn_playermarker_gfx = {}
    @canvas_gfx_info = {}
    @points_status = {}
    @player_gfx_info = {}
    
    
    # initialize the core
    init_core_game(options)
    
    
    load_specific_resource
    
    # usa un valore del seed fisso per provare delle funzioni
    # rimuovi questo codice nella produzione quando i test sono finiti 
    # developer test code -- begin ---
    #@core_game.game_opt[:test_with_custom_deck] = true
    # developer test code -- end ---
    if options["autoplayer"]
      @option_gfx[:autoplayer_gfx] = options["autoplayer"][:auto_gfx]
    end
    
    # composite object
    @composite_graph = GraphicalComposite.new(@app_owner)
    
    # card players
    @cards_players = CardsPlayersGraph.new(@app_owner, self, @core_game.num_of_cards_onhandplayer)
    @cards_players.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_players.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @cards_players.offset_left = 70
    @cards_players.set_jump_animation_distr(@option_gfx[:jump_distr_cards])
    @composite_graph.add_component(:cards_players, @cards_players)
    
    # message box
    @msg_box_info = MsgBoxComponent.new(@app_owner, @core_game, @option_gfx[:timeout_msgbox], @font_text_curr[:medium])
    if @option_gfx[:autoplayer_gfx]
      @msg_box_info.autoremove = true
    end
    @msg_box_info.build(nil) 
    @composite_graph.add_component(:msg_box, @msg_box_info)
    
    #smazzata end message box
    @msgbox_smazzataend = SmazzataInfoMbox.new("Smazzata finita", 
                    200,50, 400,400, @font_text_curr[:medium])
    @msgbox_smazzataend.SetShortcutsSpazzino
    @msgbox_smazzataend.set_visible(false)
    @composite_graph.add_component(:msg_box_smazzataend, @msgbox_smazzataend)
    
    
    # cards taken
    max_num_of_cardstaken = 6
    @cards_taken = CardsTakenGraph.new(@app_owner, self, @font_text_curr[:big], max_num_of_cardstaken )
    @cards_taken.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_taken.set_resource(:points_deck_img, @image_gfx_resource[:points_deck_img])
    @cards_taken.offset_left = 200
    @composite_graph.add_component(:cards_taken, @cards_taken)
    
    # deck
    deck_factor = 2
    num_cards_ondeck = (40 - (players.size * @core_game.num_of_cards_onhandplayer + @initial_cards_on_table)) / deck_factor
    @deck_main = DeckMainGraph.new(@app_owner, self, @font_text_curr[:small], num_cards_ondeck, deck_factor )
    @deck_main.realgame_num_cards = @core_game.num_cards_on_mazzo
    @deck_main.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @composite_graph.add_component(:deck_main, @deck_main)
    
    # cards on table played
    @table_cards_played = TablePlayedCardsGraph.new(@app_owner, self, players.size)
    @table_cards_played.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @composite_graph.add_component(:table_cardsplayed, @table_cards_played)
    
    # eventually add other components for inherited games
    add_components_tocompositegraph()
    
    
    # we have a dependence with the player gui, we have to create it first
    players.each do |player_for_sud|
      if player_for_sud.type == :human_local
        # local player gui
        player_for_sud.position = :sud
        @cards_players.build(player_for_sud)
        player_for_sud.algorithm = self
        @player_on_gui[:player] = player_for_sud
        @player_on_gui[:can_play] = false
        # check autoplayer is enabled, use also an automate instead of human
        if @option_gfx[:autoplayer_gfx]
          # autoplayer
          @alg_auto_player = eval(@algorithm_name).new(player_for_sud, @core_game, @app_owner)
          @log.debug("Create an automate for gfx player #{@algorithm_name}")
        end
        break
      end 
    end
    
    #p players
    # set players algorithm
    pos_names = [:nord]
    players.each do |player|
      player_label = player.name.to_sym
      # prepare info, an empty hash for gfx elements on the player
      @player_gfx_info[player_label] = {}
      if player.type == :cpu_local
        player.position = pos_names.pop
        @cards_players.build(player)
        player.algorithm = eval(@algorithm_name).new(player, @core_game, @app_owner)
        @log.debug "Create player algorithm #{@algorithm_name}"
        @opponents_list << player
      elsif player.type == :human_local
        # already done above
        
      elsif player.type == :human_remote
        player.position = pos_names.pop
        @cards_players.build(player)
        # don't need alg, only label
        player.algorithm = nil
        @opponents_list << player   
      end
      # create the label for the player
      build_gfxlabel_player(player_label, player.type)
      # set the player name
      set_playername_onlabel(player)
     
      # create turn marker
      build_gfxmarker_player(player_label, player.type)
      
      # create taken cards images
      @cards_taken.build(player)
      
      # reset information about points
      @points_status[player_label] = {:tot => 0}
      
      @players_on_match << player
    end #players.each
    
    @state_gfx = :on_game
    
    # create cards on table
    #@table_cards_played.build(nil)
    @table_cards_played.build_with_info(
        {:x => {:type => :center_anchor_horiz, :offset => 0},
         :y => {:type => :center_anchor_vert, :offset => 0},
         :anchor_element => :canvas,
         :max_num_cards => 10, :intra_card_off => 5, 
         :img_coperto_sym => :coperto, :type_distr => :linear})
    
    # create points shower
    build_points_shower
    
    # adjust the cpu algorithm if we are using a saved game
    check_for_predefined_algorithm(options)
    
    # start the match
    @core_game.gui_new_match(@players_on_match) 
  end
  
  ##
  # Add more components
  def add_components_tocompositegraph
    # nothing to add
  end
  
  ##
  # Check for predifined algorithm 
  # Expect predifined information in options (cuperativa @app_settings)
  def check_for_predefined_algorithm(options)
    @predifined_game = false
    if options["cpualgo"]
      if options["cpualgo"][:predefined]
        # leggi il file yaml, trova smazzata, giocatore e mazzo
        # setta il mazzo ed accumula tutte le giocate nell algoritmo
        # di modo che giochi le giocate che via sono proposte
        @log.debug "adjoust algorithm with a predifined game..."
        player = @opponents_list.first
        player.algorithm.level_alg = :predefined
        # load match information
        match_info = YAML::load_file(options["cpualgo"][:saved_game])
        segni = match_info[:giocate] # catch all giocate, it is an array of hash
        # pick giocata
        curr_segno = segni[options["cpualgo"][:giocata_num]]
        if options["cpualgo"][:player_name] != player.name
          @log.error "Predifined player name error"
        end
        # we need to order players based on position
        plyers_order =  match_info[:players]
        if plyers_order
          tmp = @players_on_match
          @players_on_match = []
          plyers_order.each do |pl_name|
            tmp.each do |plobj|
              if plobj.name == pl_name
                @players_on_match << plobj
                break
              end
            end
          end
          if @players_on_match.size != tmp.size
            @log.error "ERROR predifined name don't match! "
          end
        else
          # :players_table is not present, 
          @log.warn "CAUTION CAUTION you have to adjoust players order on the table manually"
        end
        
        # set predifined actions into opponent queue
        player.algorithm.collect_predifined_actions(curr_segno, options["cpualgo"][:player_name])
        # set predifined actions also for the gui player, this info is used to replay the saved game
        collect_predifined_actions(curr_segno,options["cpualgo"][:player_name_gui])
        @core_game.rnd_mgr.set_predefdeck_withready_deck(curr_segno[:deck], curr_segno[:first_plx])
        @predifined_game = true
      end
    end
  end
  
  ##
  # Collect actions to be used on predifined game
  def collect_predifined_actions(curr_smazzata, name)
    @action_queue = []
    curr_smazzata[:actions].each do |action|
      if action[:arg][0] == name
        @action_queue << ({:type => action[:type], :arg => action[:arg]})
      else
        #p action
        # action not for this algorithm player
      end
    end
    @log.debug "Predifined actions collected: #{@action_queue.size}"
  end
  
  ##
  # Provides a new instance of the current core. On iherited game you can overwrite
  # this function
  def create_instance_core() 
    return CoreGameSpazzino.new
  end
  
  ##
  # Set the player name on the label
  # player: instance of PlayerOnGame
  def set_playername_onlabel(player)
    player_label = player.name.to_sym
    lbl_plname = get_player_lbl_symbol(player_label)
    @labels_to_disp[lbl_plname].text = player.name
    @labels_to_disp[lbl_plname].visible = true
  end
  
  ###
  # Load specific resource, like special image, for spazzino
  def load_specific_resource
    # load only once
    if @image_gfx_resource.size == 0
      png_resource =  File.join(@resource_path ,"images/taken.png")
      res_sym = :points_deck_img
      
      # points
      img = FXPNGIcon.new(getApp, nil,IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
      @image_gfx_resource[res_sym] = img
      
      # opponent cards
      png_resource =  File.join(@resource_path ,"images/avvers_coperto.png")
      res_sym = :card_opp_img
      img = FXPNGIcon.new(getApp, nil,
              IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
      @image_gfx_resource[res_sym] = img
      # now create all resources
      @image_gfx_resource.each_value{|v| v.create}
    end
  end
  
  ##
  # Unload all specific resources. Called from base class detach
  def detach_specific_resources
    @image_gfx_resource.each_value{|v| v.detach}
  end

  ##
  # Build a marker for player that have to play
  def build_gfxmarker_player(player_sym, pl_type)
    color = @color_player_marker
    marker_gfx_created =  TurnMarkerGfx.new(0,0, 40, 8, color, false)
    #p player_sym
    @turn_playermarker_gfx[player_sym]  = marker_gfx_created
    @player_gfx_info[player_sym][:rectturn] = marker_gfx_created
    # adjoust position
    resize_gfxmarker_player(player_sym, pl_type)
  end
  
  ##
  # Resize marker for player on turn
  def resize_gfxmarker_player(player_sym, pl_type)
    info_lbl = @canvas_gfx_info["#{player_sym}_label_pl".to_sym]
    y_lbl = info_lbl[:y] + 5
    x_lbl = info_lbl[:x]
    
    marker_gfx_created =  @player_gfx_info[player_sym][:rectturn] 
    marker_gfx_created.pos_x = x_lbl
    marker_gfx_created.pos_y = y_lbl
  end

  ##
  # Build points shower
  def build_points_shower()
   
  end


  ###
  # User click on card taken
  def evgfx_click_on_takencard(sender)
    @log.debug "Click on card taken"
    if @taken_card_info_last[:state] == :showing
      # ignore click because we are already showing one
      @log.debug("Ignore click on card taken")
      return
    end
    player_sym = sender.data_custom[:player_sym]
    #p "Click on deck for #{plsym}"
    count = 0
    ix_list = [2,3,1,4,0,5] # use index list to show first card in the middle
    @taken_card_info_last[player_sym][:taken_cards].each do |cd_item|
      ix = ix_list[count]
      card_gfx = @player_gfx_info[player_sym][:card_lasttaken_arr][ix]
      card_gfx.change_image(get_card_image_of(cd_item), cd_item)
      card_gfx.visible = true
      count += 1
      break if count >= ix_list.size or count >= @player_gfx_info[player_sym][:card_lasttaken_arr].size
    end
    @taken_card_info_last[:state] = :showing
    @taken_card_info_last[:curr_playersym_shown] = player_sym
    @app_owner.registerTimeout(@option_gfx[:timeout_lastcardshow], :onTimeoutLastCardTakenShow)
    # refresh the display
    @app_owner.update_dsp 
  end
 
  
  ##
  # Build a label with the player name
  # player_sym: user name as symbol
  def build_gfxlabel_player(player_sym, pl_type)
    # label username
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    lbl_displ_pl = get_player_lbl_symbol(player_sym)
    color = Fox.FXRGB(0, 0, 0)
    lbl_gfx_created  =  LabelGfx.new(0,0, "", @font_text_curr[:big], color,  false)
    @labels_to_disp[lbl_displ_pl]  = lbl_gfx_created
    @player_gfx_info[player_sym][:lbl_name] = lbl_gfx_created 
    
    # label for status
    color = Fox.FXRGB(20, 10, 200)
    lbl_gfx_status  =  LabelGfx.new(0,0, "pronto", @font_text_curr[:small], color, false)
    @labels_to_disp["#{lbl_displ_pl}status".to_sym] = lbl_gfx_status
    @player_gfx_info[player_sym][:lbl_status] = lbl_gfx_status
    # adjust position
    resize_gfxlabel_player(player_sym, pl_type)
  end
  
  
  ##
  # Resize player label
  # NOTA: funzione candidata a finire in una classe base tra briscola e spazzino
  def resize_gfxlabel_player(player_sym, pl_type)
    x_lbl =  @model_canvas_gfx.info[:info_gfx_coord][:x_top_opp_lx]
    y_lbl =  @model_canvas_gfx.info[:info_gfx_coord][:y_top_opp_lx]
    info_deck = @model_canvas_gfx.info[:deck_gui_pl]
    
    offlbl_y = 20
    start_toty = 30
    
    if pl_type == :human_local
      x_lbl = 20
      y_lbl = @model_canvas_gfx.info[:canvas][:height] - 30
    end
    
    # label username
    info_hash_lbl_tmp = {:x => x_lbl, :y => y_lbl} 
    @canvas_gfx_info["#{player_sym}_label_pl".to_sym] = info_hash_lbl_tmp
    @model_canvas_gfx.info_label_player_set(player_sym, info_hash_lbl_tmp) 
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    lbl_displ_pl = get_player_lbl_symbol(player_sym)
    lbl_gfx_created  = @labels_to_disp[lbl_displ_pl]  
    lbl_gfx_created.pos_x = x_lbl
    lbl_gfx_created.pos_y = y_lbl
    # label for status
    y_lbl -= 20
    lbl_gfx_status  =  @player_gfx_info[player_sym][:lbl_status]
    lbl_gfx_status.pos_x = x_lbl
    lbl_gfx_status.pos_y = y_lbl
  end

  
  ##
  # Provides the symbol for a player in game to be used for generating LabelGfx
  def get_player_lbl_symbol(player_sym)
    # prefix player string beacuse we have also other strings 
    # that need not to be confused with player name
    return lbl_displ_pl = "0#{player_sym}".to_sym
  end
  
  ##
  # Builds wiidgets for player points
  def build_gfx_points(players)
    # label for points on the current giocata
    color = Fox.FXRGB(0, 0, 0)
    players.each do |pl_match|
      player_label = pl_match.name.to_sym
      # picule
      str_num_pic = calculate_str_points_det(pl_match.name, :picula)
      sym_pic_widg = "widg_pic_#{player_label}"
      @labels_to_disp[sym_pic_widg] = LabelGfx.new(0,0, str_num_pic, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_pic] = @labels_to_disp[sym_pic_widg] 
      # spazzini
      str_num_spazz = calculate_str_points_det(pl_match.name, :spazzino)
      sym_spazz_widg = "widg_spaz_#{player_label}"
      @labels_to_disp[sym_spazz_widg] = LabelGfx.new(0,0, str_num_spazz, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_spaz] = @labels_to_disp[sym_spazz_widg]
      # bager
      str_num_bager = calculate_str_points_det(pl_match.name, :bager)
      sym_bager_widg = "widg_bager_#{player_label}"
      @labels_to_disp[sym_bager_widg] = LabelGfx.new(0,0, str_num_bager, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_bager] = @labels_to_disp[sym_bager_widg] 
      
      # total points 
      str_num = calculate_str_points_det(pl_match.name, :tot)
      sym_widg = "widg_tot_#{player_label}"
      @labels_to_disp[sym_widg] = LabelGfx.new(0,0, str_num, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_tot] = @labels_to_disp[sym_widg]
    end
    @points_status[:build] = true
    resize_gfx_points(players)
  end
  
  ##
  # Resize widgets for players points
  def resize_gfx_points(players)
    return unless @points_status[:build]
    left_align_off = 20
    offlbl_y = 20
    #start_toty = 30
    start_toty = 110
    
    #label for picule and spazzini
    players.each do |pl_match|
      player_label = pl_match.name.to_sym
      lbl_gfx_pic = @points_status[player_label][:widg_pic]
      lbl_gfx_spaz = @points_status[player_label][:widg_spaz]
      lbl_gfx_bager = @points_status[player_label][:widg_bager]
      lbl_gfx_tot = @points_status[player_label][:widg_tot] 
      lbl_gfx_pic.pos_x = left_align_off
      lbl_gfx_spaz.pos_x = left_align_off
      lbl_gfx_tot.pos_x = left_align_off
      lbl_gfx_bager.pos_x = left_align_off
      if pl_match.type == :human_local
        human_start_toty = start_toty - 30
        lbl_gfx_spaz.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 2 * offlbl_y)
        lbl_gfx_pic.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 3 * offlbl_y)
        lbl_gfx_bager.pos_y = @model_canvas_gfx.info[:canvas][:height] -( human_start_toty + 4 * offlbl_y)
        lbl_gfx_tot.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 5 * offlbl_y)
      else
        lbl_gfx_spaz.pos_y = start_toty + offlbl_y
        lbl_gfx_pic.pos_y = start_toty + 2 * offlbl_y
        lbl_gfx_tot.pos_y = start_toty
        lbl_gfx_bager.pos_y = start_toty + 3 * offlbl_y
      end
    end
  end
 
  ##
  # Provides string for points detail
  def calculate_str_points_det(player_name, det)
    s1 = 0
    s1 = @points_status[player_name.to_sym][det] if @points_status[player_name.to_sym][det]
    str_points = ""
    case det
      when :picula
        str_points = "Picule  : #{s1}"
      when :spazzino
        str_points = "Spazzini: #{s1}"
      when :bager
        str_points = "Bager   : #{s1}"
      when :tot
        tot_points = @core_game.game_opt[:target_points]
        str_points = "Punti : #{s1} (#{tot_points})"       
    end
    
    return str_points
  end
  
  ##
  # Provides string with current points on the game (OBSOLETE)
  def calculate_str_points
    pl1 = @players_on_match.first
    pl2 = @players_on_match.last
    tot_points = @core_game.game_opt[:target_points]
    s1 = @points_status[pl1.name.to_sym][:tot]
    s2 = @points_status[pl2.name.to_sym][:tot]
    str_points = "Punteggio (#{tot_points}):    #{pl1.name}: #{s1}  #{pl2.name}: #{s2}"
    @log.debug("calculate_str_status_segni: #{str_points}")
    return str_points
  end

  ##
  # Mano end timeout. We have to disntinguish about two cases: the first is when 
  # a user take cards, then we can show animation. The second case is when the user don't
  # take cards, then there is no animation
  def onTimeoutManoEnd
    #p 'onTimeoutManoEnd'
    @log.debug "gfx: timeout manoend"
    #@core_game.continue_process_events if @core_game
    if @mano_end_card_taken.size > 0 and @state_gfx == :on_game
      ## deselect all cards on table
      @table_cards_played.deactivate_border_sel
      ## we don't see an empty table
      @log.debug "gfx: start animation cards taken"
      #@table_cards_played.card_taken_ontable(@mano_end_player_taker, @mano_end_card_taken) 
      #@table_cards_played.start_ani_cards_taken
      @table_cards_played.card_taken_ontable2(@mano_end_player_taker, @mano_end_card_taken) 
    else
      # simply continue NO animation
      @app_owner.registerTimeout(@option_gfx[:timeout_manoend_continue], :onTimeoutManoEndContinue)
    end
    #@core_game.continue_process_events if @core_game
  end
  
  ##
  # Now continue the game
  def onTimeoutManoEndContinue
    @log.debug "gfx: timeout manoend_continue"
    #p 'onTimeoutManoEndContinue'
    player_label = @mano_end_player_taker.name.to_sym
    # player mark turned off
    @turn_playermarker_gfx[player_label].visible = false
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  ##
  # Play automatically
  def onTimeoutHaveToPLay
    if @state_gfx == :on_game
      #only if we are on game 
      player = @alg_auto_stack.pop
      command_decl_avail = @alg_auto_stack.pop
      @alg_auto_player.onalg_have_to_play(player,command_decl_avail)
    end
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  ##
  # Player on gui played timeout
  def onTimeoutPlayer
    @log.debug "gfx: timeout player, continue game"
    @core_game.continue_process_events if @core_game
  end
  
  
  ##
  # Notification that on the gui the player has clicked on declaration button
  # params: array of parameters. Expect player as first item and declaration as second.
  def onBtPlayerDeclare(params)
    @log.error("onBtPlayerDeclare not supported")
  end
  
  ##
  # NOtification not used
  def onBtPlayerChangeBriscola(params)
    @log.error("onalg_player_has_declared not supported")
  end
  
  ############### implements methods of AlgCpuPlayerBase
  #############################################
  #algorithm calls (gfx is a kind of algorithm)
  #############################################
   
  ##
  # New match is started
  # players: array of players
  def onalg_new_match(players)
    #p players.serialize 
    log "Nuova partita. Numero gioc: #{players.size}\n"
    players.each{|pl| log " Nome: #{pl.name}\n"}
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_new_match(players)
    end
  end
   
  ##
  # New giocata notification
  # carte_player: array of card as symbol (e.g :bA, :c2 ...). First three cards
  #  are for the player, the rest is on the table.
  def onalg_new_giocata(carte_player)
    str_log = "Nuova giocata, carte in mano: "
    carte_player[0..@num_of_cards-1].each{|e| str_log += "[#{nome_carta_ita(e)}]"}
    str_log += "\n"
    log str_log
    str_log = "Carte in tavola: "
    carte_player[@num_of_cards..-1].each{|e| str_log += "[#{nome_carta_ita(e)}]"}
    str_log += "\n"
    log str_log
    
    build_gfx_points(@players_on_match)

    @table_cards_lbl = carte_player[@num_of_cards..-1]
    @table_cards_played.initial_lbl_cards_on_table2(@table_cards_lbl)
    
    # deck for the distributer
    @initial_cards_on_table = carte_player.size - @num_of_cards
    build_deck_on_newgiocata(@initial_cards_on_table)
    
    player_sym = @player_on_gui[:player].name.to_sym
    @cards_players.set_cards_player(player_sym, carte_player)
    
    
    @cards_players.init_position_ani_distrcards
    
    @turn_playermarker_gfx.each do |k,v|
      v.visible = false
    end
    
    #reset points in the current giocata
    reset_points_current_giocata()
    
    # last card taken state
    @cards_taken.init_state(@players_on_match)
   
    #set cards of opponent (assume it is only one opponent)
    player_opp = @opponents_list.first.name.to_sym
    @cards_players.set_allcards_player_decked(player_opp, :card_opp_img)
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_new_giocata(carte_player)
    end
    
    # animation distribution cards
    @composite_graph.bring_component_on_front(:cards_players)
    @cards_players.start_animadistr
    
    if !@cards_players.is_animation_terminated?
      # suspend core event process untill animation_cards_distr_end is called
      @core_game.suspend_proc_gevents("onalg_new_giocata")
    end
    
      
    # refresh the display
    @app_owner.update_dsp
  end
  
  def build_deck_on_newgiocata(initial_cards_on_table)
    @deck_main.briscola = false
    @deck_main.build(nil)
    @deck_main.realgame_num_cards = 40 -  initial_cards_on_table - 
                 ( @core_game.num_of_cards_onhandplayer * (@players_on_match.size))  
  end
  
  ##
  # Reset points for the current giocata
  def reset_points_current_giocata
    @players_on_match.each do |pl_match|
      player_label = pl_match.name.to_sym
      @points_status[player_label][:spazzino] = 0
      @points_status[player_label][:picula] = 0
      @points_status[player_label][:bager] = 0
      @points_status[player_label][:num_cards] = 0
      #each player needs last taken cards information
      @taken_card_info_last[player_label] = {} 
      points_gfx_update(pl_match)
    end
  end
  
  ##
  # Notification about the mazziere
  def onalg_new_mazziere(player)
    @log.debug("New mazziere is: #{player.name}")
    @mazziere = player
    if @mazziere.name == @player_on_gui[:player].name 
      @deck_main.movedeck_to(:sud)
    else
      @deck_main.movedeck_to(:nord)
    end
  end
  
  ##
  # Create a string for the messagebox object using bestplayer data
  def bestpl_points_to_msgboxstr(best_pl_points)
    str_res = "Punteggio smazzata:\n #{best_pl_points[0][0]}: #{best_pl_points[0][1][:tot]} \n #{best_pl_points[1][0]}: #{best_pl_points[1][1][:tot]}"
    best_pl_points.each do |item|
      str_res += "\n **** #{item[0]}\n"
      count = 0
      item[1].each do |k,v|
        next if k == :tot
        str_res += "   #{k}: #{v}"
        if count == 3 
          str_res += "\n"
          count = 0
        else
          count += 1
        end 
      end 
    end
    return str_res
  end
  
  ##
  # New mano
  #table_player_info: array of two elements: first is the player, second are cards on table
  def onalg_newmano(table_player_info)
    @log.debug "gfx: onalg_newmano"
    @mano_end_cardplayed = nil
    @mano_end_card_taken = []
    player =  table_player_info[0]
    @table_cards_lbl = table_player_info[1]
    #@table_cards_played.prepare_table_for_newmano(@table_cards_lbl)

    @log.debug "Nuova mano. Comincia: #{player.name}"
    @player_on_gui[:mano_ix] = 0
    @mano_end_player_taker = nil
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_newmano(table_player_info)
    end
  end
  
  ##
  # Mano end
  # player: who has played the hand
  # dummy: not used
  # curr_points_info: something like: [{:spazzino => 0, :picula => 0,...}] look on core mano_end (reset_points_newgiocata)
  #               Points event collecetd in this hand, if there are.
  #               Empty array if nothing is collected, such as picula, spazzino or bager
  def onalg_manoend(player, dummy, curr_points_info)
    @log.debug 'gfx: onalg_manoend'
    if @mano_end_card_taken.size > 0
      # adjourn points in the view
      @points_status[player.name.to_sym][:num_cards] += @mano_end_card_taken.size + 1
      @cards_taken.set_player_points(player, @points_status[player.name.to_sym][:num_cards])
      # last cards taken
      @cards_taken.set_lastcardstaken(player, [@mano_end_cardplayed, @mano_end_card_taken].flatten)
      
    end
    
    ## start a timer for card played animation
    #reset colors for points   
    points_gfx_reset_colors
    points_gfx_mano_end_set(curr_points_info, player)
    # update points in the view
    points_gfx_update(player) #if curr_points_info.size > 0
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_manoend(player, dummy, curr_points_info)
    end
    
    # start a timer to give a user a chance to see the end
    @app_owner.registerTimeout(@option_gfx[:timout_manoend], :onTimeoutManoEnd)
    
    ## suspend core event process untill timeout
    @core_game.suspend_proc_gevents("onalg_manoend")
  end
  
  ##
  # Reset colors of points labels
  def points_gfx_reset_colors
    @players_on_match.each do |pl_single|
      player_label1 = pl_single.name.to_sym
      @points_status[player_label1][:widg_pic].font_color = Fox.FXRGB(0, 0, 0)
      @points_status[player_label1][:widg_spaz].font_color = Fox.FXRGB(0, 0, 0)
      @points_status[player_label1][:widg_bager].font_color = Fox.FXRGB(0, 0, 0)
    end
  end
  
  ##
  # Set points into label widgets
  def points_gfx_mano_end_set(curr_points_info, player)
    curr_points_info.each do |pt_item|
      player_label = player.name.to_sym
    
      if pt_item[:spazzino]
        @points_status[player_label][:spazzino] += pt_item[:spazzino]
        @points_status[player_label][:widg_spaz].font_color = @color_signal 
        log "#{player.name} ha fatto spazzino\n"
      end
      if pt_item[:picula]
        @points_status[player_label][:picula] += pt_item[:picula]
        @points_status[player_label][:widg_pic].font_color = @color_signal
        log "#{player.name} ha fatto picula\n"
      end  
      if pt_item[:bager]
        @points_status[player_label][:bager] += pt_item[:bager]
        @points_status[player_label][:widg_bager].font_color = @color_signal
        log "#{player.name} ha fatto bager\n"
      end
    end
  end
  
  ##
  # Update player points
  def points_gfx_update(player)
    player_label = player.name.to_sym
    #p curr_points_info
    lbl_gfx_pic = @points_status[player_label][:widg_pic]
    lbl_gfx_spaz = @points_status[player_label][:widg_spaz]
    lbl_gfx_bager = @points_status[player_label][:widg_bager]
    lbl_gfx_pic.text = calculate_str_points_det(player.name, :picula)  
    lbl_gfx_spaz.text = calculate_str_points_det(player.name, :spazzino)
    lbl_gfx_bager.text = calculate_str_points_det(player.name, :bager)
    
  end
  
  ##
  # Provides card name in italian
  def nome_carta_ita(lbl_card)
    return CoreGameBase.nome_carta_completo(lbl_card)
  end
  
  ##
  # Player has pick cards from deck
  # carte_player: array of card picked
  def onalg_pesca_carta(carte_player)
    #expect @num_of_cards cards
    @log.debug "gfx: card picked #{carte_player.join(",")}"
    nomi = []
    carte_player.each{|c| nomi << nome_carta_ita(c)}
    str_log = "Carta pescate: "
    nomi.each{|e| str_log += "[#{e}]"}
    str_log += "\n"
    log str_log 
    #search the first free card on player gui
    player_sym = @player_on_gui[:player].name.to_sym
    
    #player cards
    @cards_players.set_cards_player(player_sym, carte_player)
    
    # opponent card, simulate on the gui that he has also picked a card
    player_opp = @opponents_list.first.name.to_sym
    @cards_players.set_allcards_player_decked(player_opp, :card_opp_img)
    
    carte_player.size.times{|ix| @deck_main.pop_cards(1)}
    @deck_main.realgame_num_cards -= ( @players_on_match.size * carte_player.size)
    
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_pesca_carta(carte_player)
    end
    
    ## animation for distributing cards
    @composite_graph.bring_component_on_front(:cards_players)
    @cards_players.start_animadistr
    
    if !@cards_players.is_animation_terminated?
      @core_game.suspend_proc_gevents("onalg_pesca_carta")
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ##
  # Shows the messagebox for smazzata end
  def show_smazzata_end(best_pl_points )
    str_res = bestpl_points_to_msgboxstr(best_pl_points)
    
    points_for_msg = []
    names_arr = []
    best_pl_points.each do |pp1_arr|
      name = pp1_arr[0]
      pp1 = pp1_arr[1]
      points_pl = { :tot =>  pp1[:tot], :carte => pp1[:carte], :spazzino => pp1[:spazzino],  
        :settedidenari => pp1[:setbel], :napoli => pp1[:napola], 
        :spade => pp1[:spade], :duedispade=>pp1[:duespade],
        :fantedispade => pp1[:fantespade], :bager => pp1[:bager],
        :picula =>pp1[:picula]}
      points_for_msg << points_pl
      names_arr << name
    end
          
    @msgbox_smazzataend.points[:p1] = points_for_msg[0]
    @msgbox_smazzataend.points[:p2] = points_for_msg[1]
    @msgbox_smazzataend.name_p1 = names_arr[0]
    @msgbox_smazzataend.name_p2 = names_arr[1]
    
    @msgbox_smazzataend.set_visible(true)
  end
  
  ##
  # Giocata end notification
  # best_pl_points: array of couple name->points sorted by max points
  # e.g. [["cpu", {:carte=>2, :spade=>2, :napola=>0, :spazzino=>0, :onori=>2, :picula=>0, :tot=>9, :bager=>3}], ["me", {:carte=>0, :spade=>0, :napola=>0, :spazzino=>0, :onori=>1, :picula=>1, :tot=>2, :bager=>0}]]
  def onalg_giocataend(best_pl_points)
    #p best_pl_points
    best_pl_points.each do |pl_info_points|
      player_label = pl_info_points[0].to_sym
      @points_status[player_label][:tot] += pl_info_points[1][:tot]
      lbl_gfx_tot = @points_status[player_label][:widg_tot]
      playername = pl_info_points[0]
      lbl_gfx_tot.text = calculate_str_points_det(playername, :tot)
    end
    str = "** Punteggio smazzata: #{best_pl_points[0][0]} punti: #{best_pl_points[0][1][:tot]} - #{best_pl_points[1][0]} punti: #{best_pl_points[1][1][:tot]}\n"
    log str
    if @option_gfx[:use_dlg_on_core_info]
      show_smazzata_end(best_pl_points )
    end
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_giocataend(best_pl_points)
    end
    
    # refresh the display
    @app_owner.update_dsp
    
    # continue the game
    @core_game.gui_new_segno if @core_game
  end
  
  ##
  # Match end notification
  # match_points: array of pairs name->points
  # e.g [["rudy", 21], ["zorro", 5]]
  def onalg_game_end(match_points)
    #p match_points
    winner = match_points[0]
    loser =  match_points[1]
    str = "*** Vince la partita: #{winner[0]}\n" 
    str += "#{winner[0]} punti #{winner[1]}\n"
    if loser[1] == -1
      str += "#{loser[0]} abbandona\n"
    else
      str += "#{loser[0]} punti #{loser[1]}\n"
    end 
    log str
    if @option_gfx[:use_dlg_on_core_info]
      @msg_box_info.show_message_box("Partita finita", str.gsub("*** ", ""), false)
    end
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_game_end(match_points)
    end
    game_end_stuff
  end
  
  ##
  # Game end stuff
  def game_end_stuff
    fname = File.expand_path(File.join( File.dirname(__FILE__) + "/../..","game_terminated_last.yaml"))
    @core_game.save_curr_game(fname) if @core_game
    log "Partita terminata\n"
    # don't need anymore core
    @core_game = nil
    @state_gfx = :game_end
    if @composite_graph
      @composite_graph.remove_all_components()
      @composite_graph.add_component(:msg_box, @msg_box_info)
      @composite_graph.add_component(:smazzata_end, @msgbox_smazzataend) if @msgbox_smazzataend
    end
    super # base class game_end_stuff
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
      if @predifined_game
        # we can play a predifined game shows it in the log
        args = predef_get_next_action(:cardplayedarr)
        @log.debug("PREDEF: Cards played from #{args[0]} are: #{args[1].join(",")}") if args
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
    if @option_gfx[:autoplayer_gfx] and player == @player_on_gui[:player]
      # avoid conflicts with user
      @player_on_gui[:can_play] = false
      # store parameters into a stack
      @alg_auto_stack.push(command_decl_avail)
      @alg_auto_stack.push(player)
      # trigger autoplay
      @log.debug "Waiting for autoplay..."
      @app_owner.registerTimeout(@option_gfx[:timeout_autoplay], :onTimeoutHaveToPLay)
      # suspend core event process untill timeout
      @core_game.suspend_proc_gevents("onalg_have_to_play")
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  ##
  # Provides the next action requested from action queue
  # Action is removed from queue
  def predef_get_next_action(action_name)
    ix = 0
    while @action_queue.size > 0
      action = @action_queue.slice(ix)
      #p "Action....."
      #action is something like: {:type=>:cardplayedarr, :arg=>["Alex", [:_6d, :_4c, :_2d]]}
      #p action
      if action[:type] == action_name
        # use predifined action
        @action_queue.slice!(ix)
        return action[:arg]
      end
      ix += 1
      return nil if ix >= @action_queue.size 
    end
    return nil
  end
  
  ##
  # Player has changed the briscola on table with a 7
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    @log.error("onalg_player_has_declared not supported")
  end
  
  ##
  # Player has played a card not allowed
  def onalg_player_cardsnot_allowed(player, cards)
    #lbl_card = cards.join(",")
    nomi = []
    cards.each{|c| nomi << nome_carta_ita(c)}
    str_log = ""
    nomi.each{|e| str_log += "[#{e}]"}
    
    log "#{player.name} ha giocato carte non valide #{str_log}\n"
    @player_on_gui[:can_play] = true
    @log.warn("Carte giocate non valide: #{str_log}")
  end
  
  ##
  # player has taken some cards. This is called at the end of giocata
  # if some cards are still on the table and need to be assigned to one player
  def onalg_player_has_taken(player, arr_lbl_card)
    @mano_end_player_taker = player
    @mano_end_card_taken = []
    arr_lbl_card.each do |taked_lbl|
      @mano_end_card_taken << taked_lbl 
    end
    @points_status[player.name.to_sym][:num_cards] += arr_lbl_card.size
    @app_owner.registerTimeout(@option_gfx[:timout_manoend], :onTimeoutManoEnd)
    @core_game.suspend_proc_gevents("onalg_player_has_taken")
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_taken(player, arr_lbl_card)
    end
  end
  
  ##
  # Player has played a card
  # arr_lbl_card: 2 item array of card played. First is the card played. Second is an array of card taken
  #               e.g [[:_4c][_1b, _1s, _2c]]
  # player: player that have played
  def onalg_player_has_played(player, arr_lbl_card)
    @log.debug "gfx: onalg_player_has_played #{player.name}, #{arr_lbl_card}"
    lbl_card = arr_lbl_card[0]
    card_taken = arr_lbl_card[1]
    @mano_end_cardplayed = lbl_card
    @mano_end_card_taken = card_taken
    @mano_end_player_taker = player
    
    player_sym = player.name.to_sym
    str_log =  "#{player.name} ha giocato la carta [#{nome_carta_ita(lbl_card)}]"
    if card_taken.size > 0
      str_log += ", preso: "
      #p card_taken
      card_taken.each{|e| str_log += "[#{nome_carta_ita(e)}]"}
      @taken_card_info_last[player_sym][:taken_cards] = []
      @taken_card_info_last[player_sym][:taken_cards] << lbl_card  
    end
    str_log += "\n"
    log str_log
    
    # check if it was gui player
    if @player_on_gui[:player] == player
      @log.debug "Carta giocata correttamente #{lbl_card}"  
      @player_on_gui[:can_play] = false
      if @player_on_gui[:ani_card_played_is_starting] == true
        # suspend core processing because we want to wait end of animation
        @core_game.suspend_proc_gevents("onalg_player_has_played")
      else
        # when animation is not rquired
        @log.debug "gfx: card played whitout/terminated animation, suspension is not needed"
      end
      # nothing to do more because player animation will be started on click handler
      return
    end
    
    # opponent player cards
    
    @cards_players.card_invisible_rnd_decked(player_sym)
    
    @sound_manager.play_sound(:play_click4)
    
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    @table_cards_played.card_is_played2(lbl_card, player, @mano_end_card_taken, init_x, init_y)
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
    
    if @option_gfx[:autoplayer_gfx]
      @alg_auto_player.onalg_player_has_played(player, arr_lbl_card)
    end
     
    # refresh the display
    @app_owner.update_dsp
    
    # suspend core processes
    @core_game.suspend_proc_gevents("onalg_player_has_played 2")
    
    # here is not better to insert a delay, beacuse we make the player turn slow
    # Delay is better on mano end and when opponent is on turn
  
  end
  
  def ani_card_played_end
    @log.debug "gfx: animation end card played"
    @player_on_gui[:ani_card_played_is_starting] = false
    if @mano_end_card_taken.size > 0
      @table_cards_played.multiplechoice_colorizetaken(@mano_end_card_taken)
    end
    @app_owner.registerTimeout(@option_gfx[:timeout_animation_player], :onTimeoutPlayer)
  end
  
  def ani_card_taken_end
    @log.debug "gfx: animation end card taken"
    @app_owner.registerTimeout(@option_gfx[:timeout_manoend_continue], :onTimeoutManoEndContinue)
  end
  
  def onalg_player_has_declared(player, name_decl, points)
    @log.error("onalg_player_has_declared not supported")
  end
  
  ##
  # Player has become points. This usally when he has declared a mariazza 
  # as a second player 
  def onalg_player_has_getpoints(player,  points)
    @log.error("onalg_player_has_declared not supported")
  end
  
  ##
  # Calculate the round distribution cards. mazziere_player is a mazziere player.
  def calc_gfxround_players(arr_players, mazziere_player)
    ins_point = -1
    round_players = []
    onlast = true
    arr_players.each_index do |e|
      if arr_players[e].name == mazziere_player.name
        ins_point = 0
        onlast = false
      end 
      round_players.insert(ins_point, arr_players[e])
      ins_point =  onlast ?  -1 : ins_point + 1         
    end
    return round_players
  end
  
  
end

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,900,700)
  
  # start game using a custom deck
  # remember that custom deck has high priority compared with cupalgo
  # PLEASE IF YOU WANT TO USE CPUALGO from yaml comment this part PLEASE
  #deck =  RandomManager.new
  #first_player = 1
  #deck.set_predefined_deck('_Rs,_Ab,_3s,_5d,_Cs,_6c,_5c,_2d,_Fd,_3c,_Ac,_3b,_5s,_6d,_Ad,_2s,_7b,_7c,_Fb,_Rd,_6s,_2b,_4c,_Cc,_5b,_6b,_4s,_Fc,_7s,_Cd,_3d,_4d,_As,_2c,_Rb,_Cb,_Fs,_7d,_Rc,_4b', first_player)
  #deck.set_predefined_deck('_Rs,_Ab,_3s,_5d,_Cs,_6c,_5c,_2d,_Fd,_3c,_Ac,_3b,_5s,_6d,_Ad,_2s,_7b,_7c,_Fb,_Rd,_6s,_2b,_4c,_Cc,_5b,_6b,_4s,_Fc,_7s,_Cd,_3d,_4d,_As,_7c,_4b,_5b,_As,_2d,_3c,_4b', first_player)
  #mainwindow.set_custom_deck(deck)
  # end test a custom deck
  
  theApp.create()
  players = []
  # Order is important? No, using information in the yaml we can set the right order
  # only the name should match
  players << PlayerOnGame.new('igor060', nil, :human_local, 0)
  players << PlayerOnGame.new('drina', nil, :cpu_local, 0)
  
  # lets try to set move of the algorithm like a saved game
  # from yaml we are using smazzata info, deck , first player (implicit mazziere) and :players
  # ATTENZIONE: ho impostato il replay di una partita con un bug. Quindi 
  # va a finire che a un certo punto la partita si blocca (alg predefined).
  #mainwindow.app_settings["cpualgo"][:predefined] = true
  
  yamlgame = 's12_gc1_2008_12_02_22_26_03-savedmatch.yaml'
  savedgame = File.dirname(__FILE__) + '/../../../test/spazzino/saved_games/' + yamlgame
  savedgame = File.expand_path(savedgame)
  mainwindow.app_settings["cpualgo"][:saved_game] = savedgame
  mainwindow.app_settings["cpualgo"][:giocata_num] = 0
  mainwindow.app_settings["cpualgo"][:player_name] = 'drina'
  mainwindow.app_settings["cpualgo"][:player_name_gui] = 'igor060'
  mainwindow.app_settings["games"][:spazzino_game] = {:target_points => 4}
  
  #mainwindow.app_settings["auto_gfx"] = true
  mainwindow.init_gfx(SpazzinoGfx, players)
  spazz_gfx = mainwindow.current_game_gfx
  spazz_gfx.option_gfx[:timeout_autoplay] = 50
  spazz_gfx.option_gfx[:autoplayer_gfx_nomsgbox] = false
  theApp.run
end
 

