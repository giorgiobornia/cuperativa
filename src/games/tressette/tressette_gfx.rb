# tressette_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'base/gfx_general/base_engine_gfx'
require 'base/gfx_general/gfx_elements'
require 'base/gfx_comp/smazzata_mbox_gfx'
require 'core_game_tressette'


##
# TressetteGfx implementation
class TressetteGfx < BaseEngineGfx
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @log = Log4r::Logger.new("coregame_log::TressetteGfx") 
    @core_game = nil
    @algorithm_name = "AlgCpuTressette"  
    @core_name_class = 'CoreGameTressette'
    @splash_name = File.join(@resource_path, "icons/tressette.png")
    
    # option for graphic engine on briscola gfx
    @option_gfx = {
      :timout_manoend => 900,#800, 
      :timeout_player => 400,#450, 
      :timeout_manoend_continue => 400,#500,
      :timeout_msgbox => 3000,
      :timout_autoplay => 1000,
      :timeout_animation_cardtaken => 20,
      :timeout_animation_cardplayed => 20,
      :timeout_animation_carddistr => 20,
      :timeout_reverseblit => 100,
      :timeout_lastcardshow => 1200,
      :use_dlg_on_core_info => true,
      :autoplayer_gfx => false,
      :jump_distr_cards => false
    }
    @splash_image = nil
    # draw handler for each state
    @graphic_handler[:on_splash] = :on_draw_splash
    @graphic_handler[:on_game] = :on_draw_game_scene
    @graphic_handler[:game_end] = :on_draw_game_scene
    # store information about player that it is using this gui
    @player_on_gui = {
      # player object
      :player => nil,
      # can player using the gui flag
      :can_play => false,
      # mano index (0 = initial, incremented when a player has correctly played )
      :mano_ix => 0
    }
    # cards on table played
    @table_cards_played = nil
    # composite graphical
    @composite_graph = nil 
    @color_back_table = Fox.FXRGB(0x22, 0x8a, 0x4c) #Fox.FXRGB(103, 203, 103)
    @color_panel_points = Fox.FXRGB(255, 115, 115)
    
    # gfx elements (widget) stored on each player    
    # Widget stored are: :lbl_name, :lbl_status, :taken_card, :rectturn
    @player_gfx_info = {}
    # reversed card clitted
    @card_reversed_gfx = nil
    # player that wons the mano
    @mano_end_player_taker = nil
    # dialogbox
    @msg_box_info = nil
    # color to display when the game is terminated
    @canvas_end_color = Fox.FXRGB(128, 128, 128)
    # algorithm for autoplay on gfx
    @alg_auto_player = nil
    # stack for autoplay function
    @alg_auto_stack = [] 
    
    # smazzata end messagebox
    @msgbox_smazzataend = nil
    @model_canvas_gfx.info[:canvas] = {}
    @model_canvas_gfx.info[:info_gfx_coord] = { 
      :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
      :y_off_plgui_lx => 15, :y_off_plg_card => 10
    } 
    # resource gfx loaded only for this game (e.g. :points_deck_img)
    @image_gfx_resource = {}
    
    load_specific_resource
  end
  
  ###
  # Load specific resource, like special image, for briscola
  def load_specific_resource
    info_res = [ {:res_sym => :bambu, 
                 :filename =>  File.join(File.dirname(__FILE__) ,"images/bambu_129.png")},
                 {:res_sym => :points_deck_img, 
                 :filename => File.join(@resource_path ,"images/taken.png")},
                 {:res_sym => :card_opp_img, 
                 :filename => File.join(@resource_path ,"images/avvers_coperto.png")},
                 {:res_sym => :foglie, 
                 :filename =>  File.join(File.dirname(__FILE__) ,"images/sfondofoglie_98.png")},
               ]
               
    # load only once
    if @image_gfx_resource.size == 0
      info_res.each do |info_res_item|
        png_resource = info_res_item[:filename]
        res_sym = info_res_item[:res_sym]
        img = FXPNGIcon.new(getApp, nil,
                IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
        FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
        @image_gfx_resource[res_sym] = img
      end
      
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
  # User click on card
  # card: cardgfx clicked on
  #def click_on_card(card)
  def evgfx_click_on_card(card)
    if (@player_on_gui[:can_play] == true and 
        card.visible and 
        card.lbl != :vuoto and 
        @alg_auto_player.is_card_ok_forplay?(card.lbl))
      #click admitted
      card.blit_reverse = false
      @player_on_gui[:ani_card_played_is_starting] = true
      allow = @core_game.alg_player_cardplayed(@player_on_gui[:player], card.lbl)
      if allow == :allowed
        @log.debug "gfx: submit card played #{card.lbl}"
        @sound_manager.play_sound(:play_click4)
        # on network game we are alway receiving :allowed before response, that
        # mean the client should be sure that it send a card :allowed
        # avoid to submit more played cards, just one
        # if we are on  game that have restriction on card played, e.g. tressette
        #  we have to check here. Waiting response from server it take too long
        @player_on_gui[:can_play] = false
        # start card played animation
        start_guiplayer_card_played_animation( @player_on_gui[:player], card.lbl)
        return # card clicked  was played correctly
      end
    end
    
    # if we reach this code, we have clicked on a card that is not allowed to be played
    @log.debug "Ignore click #{card.lbl}"
    @player_on_gui[:ani_card_played_is_starting] = false
    unless @card_reversed_gfx
      # we have clicked on card that we can't play
      @card_reversed_gfx = card
      card.blit_reverse = true
      @card_reversed_gfx = card
      @app_owner.registerTimeout(@option_gfx[:timeout_reverseblit], :onTimeoutRverseBlitEnd)
      @app_owner.update_dsp
    end    
  end #end click_on_card
  
  def get_zord_ofcardplayed
    return @player_on_gui[:mano_ix]
  end
  
  ##
  # The player on the gui has played a card. Start the animation process
  def start_guiplayer_card_played_animation( player, lbl_card)
    @log.debug("user card is played animation start #{lbl_card}")
    ix = @player_on_gui[:mano_ix]
    player_sym = player.name.to_sym
    @cards_players.card_invisible(player_sym, lbl_card)
    #@table_cards_played.set_card_image_visible(ix, lbl_card)
    #@table_cards_played.start_ani_played_card(ix, 
    #  @cards_players.last_cardset_info[:pos_x], 
    #  @cards_players.last_cardset_info[:pos_y])
    
    z_ord = get_zord_ofcardplayed
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    @table_cards_played.card_is_played2_incirc(lbl_card, player.position, z_ord, init_x,  init_y)
    
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
    
    @app_owner.update_dsp
  end
  
  def animation_pickcards_end
    player_sym = @picked_info[:player_gui]
    card_pl = @picked_info[:player_card_picked]
    player_opp_sym = @picked_info[:player_opponent]
    @cards_players.set_card_empty_player(player_sym, card_pl)
    @cards_players.set_card_empty_player_decked(player_opp_sym, :card_opp_img)
    cards_gui_player = @cards_players.get_cards_player(player_sym)
    cards_gui_player = sort_on_seed(cards_gui_player)
    @cards_players.set_cards_player(player_sym, cards_gui_player)
    @core_game.continue_process_events if @core_game
  end
  
  def ani_card_played_end
    @log.debug("gfx: ani_card_played_end")
    @player_on_gui[:ani_card_played_is_starting] = false
    @app_owner.registerTimeout(@option_gfx[:timeout_animation_cardtaken], :onTimeoutPlayer)
  end
  
  ##
  # Player on gui played timeout
  def onTimeoutPlayer
    @log.debug("gfx: onTimeoutPlayer")
    @turn_marker.set_all_marker_invisible
    @core_game.continue_process_events if @core_game
  end
  
  
  ##
  # Overrride method because we want to use @composite_graph mouse handler
  def onLMouseDown(event)
    @composite_graph.on_mouse_lclick(event) if @composite_graph
  end
  
  ##
  # Shows a splash screen
  def create_wait_for_play_screen
    @state_gfx = :on_splash
    unless @splash_image
      begin 
        # load the splash
        img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
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
    img_teil = @image_gfx_resource[:bambu]
    draw_with_texture_img(dc, img_teil, width, height)
    dc.drawImage(@splash_image, width / 2 - @splash_image.width / 2 , height / 2 - @splash_image.height / 2 )
  end
  
  ##
  # Draw static scene during game
  def on_draw_game_scene(dc,width, height)
    if @state_gfx == :game_end
      dc.foreground = @canvas_end_color
      #dc.fillRectangle(0, 0, @model_canvas_gfx.info[:canvas][:width], @model_canvas_gfx.info[:canvas][:height])
    else
      dc.foreground = Fox.FXRGB(243, 240, 100)
    end
    img_teil = @image_gfx_resource[:foglie]
    draw_with_texture_img(dc, img_teil, @model_canvas_gfx.info[:canvas][:width], @model_canvas_gfx.info[:canvas][:height])
    dc.lineWidth = 2
    rect_width = 150
    rect_h = 200
    dc.drawRoundRectangle(5,10, rect_width, rect_h, 5, 5 )
    dc.fillRoundRectangle(5,10, rect_width, rect_h, 5, 5 )
    dc.drawRoundRectangle(5,10, rect_width, rect_h, 5, 5 )
    dc.fillRoundRectangle(5,@model_canvas_gfx.info[:canvas][:height] - rect_h - 10, rect_width, rect_h, 5, 5 )
    #end
    @composite_graph.draw(dc) 
  end #end on_draw_game_scene
  
  
  ##
  # Canvas size has changed
  # width: new width
  # height: new height
  def onSizeChange(width,height)
    #@log.debug "onSizeChange: w = #{width} h = #{height}"
    @model_canvas_gfx.info[:canvas] = {:height => height, :width => width, :pos_x => 0, :pos_y => 0 }
    if @state_gfx == :on_game
      players_to_resize = []
      #resize player on sud first
      @players_on_match.each do |player_for_sud|
        if player_for_sud.position == :sud
          resize_player(player_for_sud)
        else
          players_to_resize << player_for_sud
        end
      end
      players_to_resize.each do |player|
        resize_player(player)
      end #end @players_on_match
      #@table_cards_played.resize(nil)
      @table_cards_played.resize_with_info
      @deck_main.resize_with_info
      @labels_graph.resize
      @cards_players.init_position_ani_distrcards
      @picked_cards_shower.resize
      @turn_marker.resize
    end
  end
  
   ##
  # resize all element of the player
  def resize_player(player)
    #@cards_players.resize(player)
    @cards_players.resize_with_info(player.name)
    #@cards_taken.resize(player)
    @cards_taken.resize_with_info(player.name)
  end
  
  ##
  # Tressette is started. Notification from base class that gui want to start
  # a new game
  # players: array  of players. Players are PlayerOnGame instance
  # options: hash with game options, @app_settings from cuperativa gui
  def ntfy_base_gui_start_new_game(players, options)
    @log.debug "gfx: ntfy_base_gui_start_new_game"
    @card_reversed_gfx = nil
    @opponents_list = []
    @players_on_match = []
    #@labels_to_disp = {}
    @turn_playermarker_gfx = {}
    @player_gfx_info = {}
    @player_picked_count = 0
    
    unless @model_canvas_gfx.info[:canvas][:height] 
      @log.error("ERROR: Canvas information not set")
      return
    end
    
    if options["autoplayer"]
      @option_gfx[:autoplayer_gfx] = options["autoplayer"][:auto_gfx]
    end
    
    if options["games"] and options["games"][:tressette_game]
      @option_gfx[:jump_distr_cards] = options["games"][:tressette_game][:jump_distr_cards]
    end
    
    # initialize the core
    init_core_game(options)
    
    # composite object
    @composite_graph = GraphicalComposite.new(@app_owner)
    
    # cards on table played
    @table_cards_played = TablePlayedCardsGraph.new(@app_owner, self, players.size)
    @table_cards_played.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @composite_graph.add_component(:table_cardsplayed, @table_cards_played)
    
    # card players
    @cards_players = CardsPlayersGraph.new(@app_owner, self, @core_game.num_of_cards_onhandplayer)
    @cards_players.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_players.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @cards_players.set_jump_animation_distr(@option_gfx[:jump_distr_cards])
    @composite_graph.add_component(:cards_players, @cards_players)
    
    # message box
    @msg_box_info = MsgBoxComponent.new(@app_owner, @core_game, @option_gfx[:timeout_msgbox], @font_text_curr[:medium])
    if @option_gfx[:autoplayer_gfx]
      @msg_box_info.autoremove = true
    end 
    @composite_graph.add_component(:msg_box, @msg_box_info)
    
    #smazzata end message box
    @msgbox_smazzataend = SmazzataInfoMbox.new("Smazzata finita", 
                    200,50, 400,400, @font_text_curr[:medium])
    @msgbox_smazzataend.set_shortcuts_tressette
    @msgbox_smazzataend.set_visible(false)
    @composite_graph.add_component(:msg_box_smazzataend, @msgbox_smazzataend)
    
    
    # cards taken
    @cards_taken = CardsTakenGraph.new(@app_owner, self, @font_text_curr[:big], players.size )
    @cards_taken.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @cards_taken.set_resource(:points_deck_img, @image_gfx_resource[:points_deck_img])
    @composite_graph.add_component(:cards_taken, @cards_taken)
    
    #player marker
    color_on = Fox.FXRGB(255, 150, 0)
    color_off = Fox.FXRGB(128, 128, 128)
    @turn_marker = TurnPlayerSignalGxc.new(@app_owner, self, color_on, color_off)
    @turn_marker.set_all_marker_invisible
    @composite_graph.add_component(:turn_marker, @turn_marker)
    
    # deck
    deck_factor = 2
    real_cards_ondeck_num = get_real_numofcards_indeck_initial(players.size)
    num_gfxcards_ondeck = real_cards_ondeck_num / deck_factor
    num_gfxcards_ondeck += 1 if real_cards_ondeck_num % 2 == 1 # on odd number need to increment deck
    @deck_main = DeckMainGraph.new(@app_owner, self, @font_text_curr[:small], num_gfxcards_ondeck, deck_factor )
    @deck_main.realgame_num_cards = get_real_numofcards_indeck_initial(players.size)
    @deck_main.set_resource(:card_opp_img, @image_gfx_resource[:card_opp_img])
    @composite_graph.add_component(:deck_main, @deck_main)
    build_deck
    
    #labels
    @labels_graph = LabelsGxc.new(@app_owner, self, @color_text_label, @font_text_curr[:big], @font_text_curr[:small])
    @composite_graph.add_component(:labels_graph, @labels_graph)

    # picked cards
    @picked_cards_shower = CardsDisappGraph.new(@app_owner, self, 2000)
    @picked_cards_shower.set_resource(:coperto, get_cardsymbolimage_of(:coperto))
    @composite_graph.add_component(:picked_cards, @picked_cards_shower)
    
    # eventually add other components for inherited games
    add_components_tocompositegraph()
    
    # we have a dependence with the player gui, we have to create it first
    players.each do |player_for_sud|
      if player_for_sud.type == :human_local
        # local player gui
        player_for_sud.position = :sud
        @labels_graph.set_label_text(player_for_sud.name.to_sym,
                                     player_for_sud.name, 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :bottom_anchor, :offset => -40},
               :anchor_element => :canvas })
        @turn_marker.add_marker(player_for_sud.name, :is_on,
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :bottom_anchor, :offset => -45},
               :anchor_element => :canvas, :marker_width => 90, :marker_height => 15 })
        
        @labels_graph.set_label_text(:sud_player_pt,
                                     "Punti: ", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :bottom_anchor, :offset => -80},
               :anchor_element => :canvas })
        @labels_graph.set_label_text(:vittoria_a,
                                     "Si vince ai #{@core_game.game_opt[:target_points]} punti", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :bottom_anchor, :offset => -110},
               :anchor_element => :canvas }, :small_font)
        @cards_players.build_with_info(player_for_sud.name, :coperto, true,
              {:x => {:type => :center_anchor_horiz, :offset => 0},
               :y => {:type => :bottom_anchor, :offset => -10},
               :anchor_element => :canvas, :intra_card_off => -20 } )
        @picked_cards_shower.build(player_for_sud.name.to_sym, :coperto,
              {:x => {:type => :right_anchor, :offset => -140},
               :y => {:type => :center_anchor_vert, :offset => 80},
               :anchor_element => :canvas} )
        
        @cards_taken.build_with_info(player_for_sud.name,
              {:x => {:type => :left_anchor, :offset => 20},
               :y => {:type => :bottom_anchor, :offset => -10},
               :anchor_element => :canvas, :intra_card_off => -20 } )
        
        player_for_sud.algorithm = self
        @player_on_gui[:player] = player_for_sud
        @player_on_gui[:can_play] = false
        #algorithm is used to reuse code to check if a card is valid
        # it could be also used to auto player
        @alg_auto_player = eval(@algorithm_name).new(player_for_sud, @core_game, @app_owner)
        @log.debug("Create AlgCpuTressette for gfx player")
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
        player.algorithm = eval(@algorithm_name).new(player, @core_game, @app_owner)
      elsif player.type == :human_local
        # already done above
        
      elsif player.type == :human_remote
        player.position = pos_names.pop
        # don't need alg, only label
        player.algorithm = nil 
      end
      
      if player.type != :human_local
        # create cards gfx for the oppponent
        @cards_players.build_with_info(player.name, :card_opp_img, false,
              {:x => {:type => :center_anchor_horiz, :offset => 0},
               :y => {:type => :top_anchor, :offset => 10},
               :anchor_element => :canvas, :intra_card_off => -30 } )
        @opponents_list << player
        @labels_graph.set_label_text(player.name.to_sym,
                                     player.name, 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 40},
               :anchor_element => :canvas })
        @turn_marker.add_marker(player.name, :is_on,
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 48},
               :anchor_element => :canvas, :marker_width => 90, :marker_height => 15 })
        @labels_graph.set_label_text(:nord_player_pt,
                                     "Punti: ", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 80},
               :anchor_element => :canvas })
        @picked_cards_shower.build(player.name.to_sym, :coperto,
              {:x => {:type => :right_anchor, :offset => -140},
               :y => {:type => :center_anchor_vert, :offset => -120},
               :anchor_element => :canvas} )
        
        @cards_taken.build_with_info(player.name,
              {:x => {:type => :left_anchor, :offset => 20},
               :y => {:type => :top_anchor, :offset => 136},
               :anchor_element => :canvas, :intra_card_off => -20 } )
        @labels_graph.set_label_text(:info_click_1,
                                     "Click sul mazzetto", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 184},
               :anchor_element => :canvas }, :small_font)
        @labels_graph.set_label_text(:info_click_2,
                                     "per ultima mano", 
              {:x => {:type => :left_anchor, :offset => 10},
               :y => {:type => :top_anchor, :offset => 200},
               :anchor_element => :canvas }, :small_font)
        
      end
      
      set_position_cardtaken(player_label, player.position)
      
      @players_on_match << player
    end
    
    # create cards on table
    #@table_cards_played.build(nil)
    @table_cards_played.build_with_info(
        {:x => {:type => :center_anchor_horiz, :offset => 0},
         :y => {:type => :center_anchor_vert, :offset => -40},
         :anchor_element => :canvas,
         :max_num_cards => 2, :intra_card_off => 0, 
         :img_coperto_sym => :coperto, :type_distr => :circular,
         :player_positions => [:nord, :sud]})
    
    
    @labels_graph.build()
    
    @msg_box_info.build(nil)
    
    # start the match
    @core_game.gui_new_match(players)
    
    @state_gfx = :on_game #leave this here because resize and other stuff could 
                          # break this routine
                          
                          
    @log.debug "ntfy_base_gui_start_new_game terminated"
  end #end ntfy_base_gui_start_new_game
  
  ##
  # Player leave the table
  # This is usually a network notification
  def player_leave(user_name)
    # when player leave the game, his label becomes empty
    @labels_graph.change_text_label(user_name, "(Posto vuoto)")
    @app_owner.update_dsp
    
  end
  
  
  def get_real_numofcards_indeck_initial(num_of_players)
    return 40 -  ( @core_game.num_of_cards_onhandplayer * num_of_players)
  end
  
  def add_components_tocompositegraph
    # nothing to add
  end
  
  def set_position_cardtaken(player_sym, position)
    x_pos = 20
    y_pos = 30
    if position == :sud
      y_pos = @model_canvas_gfx.info[:canvas][:height] - 90
    end
    info_hash_lbl_tmp = {:x => x_pos, :y => y_pos} 
    @model_canvas_gfx.info_label_player_set(player_sym, info_hash_lbl_tmp)
  end
  
  def build_deck
    @log.debug "gfx: build_deck"
    @deck_main.briscola = false
    @deck_main.build_with_info(
              {:x => {:type => :right_anchor, :offset => -40},
               :y => {:type => :center_anchor_vert, :offset => 0},
               :anchor_element => :canvas},
              :card_opp_img)
    @deck_main.realgame_num_cards = 40 - ( @core_game.num_of_cards_onhandplayer * (@players_on_match.size))  
  end
  
  ##
  # Mano end timeout
  def onTimeoutManoEnd
    @log.debug("gfx: onTimeoutManoEnd")
    if @state_gfx == :on_game
      # prepare animation cards taken
      if @mano_end_player_taker
        #@table_cards_played.all_card_played_tocardtaken(@mano_end_player_taker) 
        @table_cards_played.all_card_played_tocardtaken2(@mano_end_player_taker) 
        #@table_cards_played.start_ani_cards_taken
      end
      
      # refresh the display
      @app_owner.update_dsp
    end
  end
  
  ##
  # Now continue the game
  def onTimeoutManoEndContinue
    @log.debug("gfx: onTimeoutManoEndContinue")
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  def ani_card_taken_end
    @log.debug("gfx: ani_card_taken_end")
    @app_owner.registerTimeout(@option_gfx[:timeout_manoend_continue], :onTimeoutManoEndContinue)
  end
  
  def show_smazzata_end(best_pl_points )
    str = "** Vince smazzata: #{best_pl_points.first[0]} col punteggio #{best_pl_points.first[1]} a #{best_pl_points[1][1]}\n"
    log str
    #@msg_box_info.show_message_box("Smazzata finita", str.gsub("** ", ""))
    @msgbox_smazzataend.set_shortcuts_tressette
    
    points_for_msg = []
    names_arr = []
    best_pl_points.each do |pp1_arr|
      name = pp1_arr[0]
      pp1 = pp1_arr[1]
      points_pl = { :tot =>  pp1[:tot], :pezze => pp1[:pezze], 
      :assi => pp1[:assi]   
      }
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
  # Reversed blit tmed on card is elapsed
  def onTimeoutRverseBlitEnd
    if @state_gfx == :on_game and @card_reversed_gfx
      @card_reversed_gfx.blit_reverse = false
      @card_reversed_gfx = nil
      @app_owner.update_dsp
    end
  end
  
  
  ############### implements methods of AlgCpuPlayerBase
  #############################################
  #algorithm calls (gfx is a kind of algorithm)
  #############################################
  
  ##
  # Giocata end notification
  # best_pl_points: array of couple name->points sorted by max points
  # e.g. [["rudy", 45], ["zorro", 33]]
  def onalg_giocataend(best_pl_points)
    @log.debug("gfx: onalg_giocataend #{best_pl_points}")
    str = "** Punteggio smazzata: #{best_pl_points[0][0]} punti: #{best_pl_points[0][1][:tot]} - #{best_pl_points[1][0]} punti: #{best_pl_points[1][1][:tot]}\n"
    log str
    if @option_gfx[:use_dlg_on_core_info]
      show_smazzata_end(best_pl_points )
    end
    
    @alg_auto_player.onalg_giocataend(best_pl_points)
    set_player_points
    
    # refresh the display
    @app_owner.update_dsp
    
    # continue the game
    @core_game.gui_new_segno if @core_game
  end
  
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
  # Other cores send onalg_pesca_carta, but in this game we need also
  # wich card has picked the opponent
  def onalg_player_pickcards(player, cards_arr)
    @player_picked_count += 1
    #p cards_arr
    @log.debug("gfx: player #{player.name} pick #{cards_arr}")
    if player.name ==  @player_on_gui[:player].name
      player_sym = @player_on_gui[:player].name.to_sym
      #@cards_players.set_card_empty_player_visible(player_sym, cards_arr.first, false)
      @picked_info[:player_gui] = player_sym
      @picked_info[:player_card_picked] = cards_arr.first
      @deck_main.pop_cards(1)
      @deck_main.realgame_num_cards -= @players_on_match.size
      @picked_cards_shower.set_card_image(player_sym,cards_arr.first)
    else
      player_opp_sym = @opponents_list.first.name.to_sym
      @picked_info[:player_opponent] = player_opp_sym
      #@cards_players.set_card_empty_player_decked(player_opp_sym, :card_opp_img)
      @picked_cards_shower.set_card_image(player_opp_sym, cards_arr.first)
    end
    
    if @player_picked_count == @players_on_match.size
      @picked_cards_shower.start_showing
      @player_picked_count = 0
      if !@picked_cards_shower.is_animation_terminated?
        @core_game.suspend_proc_gevents
      end
    end
    
    @alg_auto_player.onalg_player_pickcards(player, cards_arr)
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  def onalg_new_match(players)
    log "Nuova partita. Numero gioc: #{players.size}\n"
    players.each{|pl| log " Nome: #{pl.name}\n"}
    @alg_auto_player.onalg_new_match(players)
  end
  
  def set_player_points
    pt_opp = @alg_auto_player.get_tot_points(@opponents_list.first.name.to_sym)
    pt_gui = @alg_auto_player.get_tot_points(@player_on_gui[:player].name.to_sym)
    @labels_graph.change_text_label(:sud_player_pt, "Punti: #{pt_gui}")
    @labels_graph.change_text_label(:nord_player_pt, "Punti: #{pt_opp}")
  end
  
  def onalg_new_mazziere(player)
    @log.debug("New mazziere is: #{player.name}")
  end
  
  def sort_on_seed(carte_player)
    deck_info = @core_game.get_deck_info
    res = carte_player.sort do |x,y|
      ss = 0
      if  deck_info[y][:segno] == deck_info[x][:segno]
        ss = deck_info[y][:rank] <=> deck_info[x][:rank]
      else
        ss = deck_info[y][:segno].to_s <=> deck_info[x][:segno].to_s
      end
      ss
    end
    return res
  end
  
  def onalg_new_giocata(carte_player)
    @log.debug("New giocata #{carte_player}")
    carte_player = sort_on_seed(carte_player)
    build_deck
    @cards_players.init_position_ani_distrcards
    @turn_marker.set_all_marker_invisible
    
    
    #set cards of the gui player
    player_sym = @player_on_gui[:player].name.to_sym
    @cards_players.set_cards_player(player_sym, carte_player)
    
    #set cards of opponent (assume it is only one opponent)
    player_opp = @opponents_list.first.name.to_sym
    @cards_players.set_allcards_player_decked(player_opp, :card_opp_img)
    
    @cards_taken.init_state(@players_on_match)
    
    @alg_auto_player.onalg_new_giocata(carte_player)
    set_player_points
    
    # animation distribution cards
    @composite_graph.bring_component_on_front(:cards_players)
    @cards_players.start_animadistr
    if !@cards_players.is_animation_terminated?
      # suspend core event process untill animation_cards_distr_end is called
      @core_game.suspend_proc_gevents
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  def onalg_newmano(player) 
    @log.debug "Nuova mano. Comincia: #{player.name}"
    @picked_info = {}
    @player_on_gui[:mano_ix] = 0
    @mano_end_player_taker = nil
    @alg_auto_player.onalg_newmano(player)
  end
  
  ##
  # Mano end
  # player_best: player who wons  the hand
  # carte_prese_mano: cards taken on this hand
  # punti_presi: points collectd in this hand
  def onalg_manoend(player_best, carte_prese_mano, punti_presi)
    log "Mano finita. Vinta: #{player_best.name}, punti: #{punti_presi}\n"
    @player_picked_count = 0
    @mano_end_player_taker = player_best
    
    # adjourn points in the view
    #@cards_taken.adjourn_points(player_best, punti_presi)
    @cards_taken.adjourn_points(player_best, carte_prese_mano.size)
    
    # last cards taken
    @cards_taken.set_lastcardstaken(player_best, carte_prese_mano)
    
    @alg_auto_player.onalg_manoend(player_best, carte_prese_mano, punti_presi)
    
    # start a timer to give a user a chance to see the end
    @app_owner.registerTimeout(@option_gfx[:timout_manoend], :onTimeoutManoEnd)
    
    # suspend core event process untill timeout
    @core_game.suspend_proc_gevents
    
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
    end
    # mark player that have to play
    @turn_marker.set_marker_state_invisible_allother(player.name, :is_on)
    
    log "Tocca a: #{player.name}.\n"
    if player == @player_on_gui[:player]
      @player_on_gui[:can_play] = true
      #log "#{player.name} comandi: #{decl_str}\n" if command_decl_avail.size > 0
    else
      @player_on_gui[:can_play] = false
    end
    if @option_gfx[:autoplayer_gfx]
      # store parameters into a stack
      @alg_auto_stack.push(command_decl_avail)
      @alg_auto_stack.push(player)
      # trigger autoplay
      # TODO
      @app_owner.registerTimeout(@option_gfx[:timout_autoplay], :onTimeoutHaveToPLay)
      # suspend core event process untill timeout
      @core_game.suspend_proc_gevents
    end
    
    # refresh the display
    @app_owner.update_dsp
  end
  
  def onalg_player_cardsnot_allowed(player, card_arr)
  end
  
  ##
  # Player has played a card
  # lbl_card: label of card played
  # player: player that have played
  def onalg_player_has_played(player, lbl_card)
    log "#{player.name} ha giocato la carta [#{nome_carta_ita(lbl_card)}]\n"
    @log.debug("onalg_player_has_played: #{player.name}, #{lbl_card}")
    
    # check card on player hand
    player_sym = player.name.to_sym
    @alg_auto_player.onalg_player_has_played(player, lbl_card)
    
    # check if it was gui player
    if @player_on_gui[:player] == player
      @log.debug "Carta giocata correttamente #{lbl_card}"  
      @player_on_gui[:can_play] = false
      if @player_on_gui[:ani_card_played_is_starting] == true
        # suspend core processing because we want to wait end of animation
        @core_game.suspend_proc_gevents
      else
        @log.debug "card played without animation, suspension is not needed"
      end
      
      # nothing to do more because player animation will be started on click handler
      return
    end
    
    # opponent player cards
    @cards_players.card_invisible_rnd_decked(player_sym)
    @sound_manager.play_sound(:play_click4)
    
    z_ord = get_zord_ofcardplayed
    init_x = @cards_players.last_cardset_info[:pos_x]
    init_y = @cards_players.last_cardset_info[:pos_y]
    @table_cards_played.card_is_played2_incirc(lbl_card, player.position, z_ord, init_x,  init_y)
    
    
    ## use card on current mano index
    #ix = @player_on_gui[:mano_ix]
    ### change image on card played
    #@table_cards_played.set_card_image_visible(ix, lbl_card)
    
    # start card played animation
    #@table_cards_played.start_ani_played_card(ix, 
    #  @cards_players.last_cardset_info[:pos_x], 
    #  @cards_players.last_cardset_info[:pos_y])
    
    
    # update index of mano
    @player_on_gui[:mano_ix] += 1
  
    # refresh the display
    @app_owner.update_dsp
    
    # suspend core processes
    @core_game.suspend_proc_gevents
    
    # here is not better to insert a delay, beacuse we make the player turn slow
    # Delay is better on mano end and when opponent is on turn
    
  end
  
  
end #end TressetteGfx

##############################################################################
##############################################################################

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,900,700)
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu', nil, :cpu_local, 0)
  
  mainwindow.init_gfx(TressetteGfx, players)
  theApp.run
end 