# tombolon_gfx.rb
# Handle display for tombolon graphic engine

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'core_game_tombolon'
require 'games/spazzino/spazzino_gfx' # base gfx class of tombolon


##
# Tombolon Gfx implementation
class TombolonGfx < SpazzinoGfx
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @splash_name =File.join(@resource_path, "icons/tombolon.png")
    @algorithm_name = "AlgCpuTombolon"
  
    @num_of_cards = 4
    @color_panel_points = Fox.FXRGB(255, 115, 115)
    @color_back_table = Fox.FXRGB(103, 203, 103)
    @color_signal = Fox.FXRGB(255, 255, 255)
    @color_player_marker = Fox.FXRGB(255, 255, 255)
    
    set_scaled_info(:deckreduced, 58, 100)
  end
  
  ##
  # Builds widgets for player points
  def build_gfx_points(players)
    color = Fox.FXRGB(0, 0, 0)
    
    # label for points on the current giocata
    players.each do |pl_match|
      player_label = pl_match.name.to_sym
      # scope
      str_num_scopa = calculate_str_points_det(pl_match.name, :scopa)
      sym_scopa_widg = "widg_scopa_#{player_label}"
      @labels_to_disp[sym_scopa_widg] = LabelGfx.new(0,0, str_num_scopa, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_scopa] = @labels_to_disp[sym_scopa_widg]
      
      # scope colore
      str_num_scopacolore = calculate_str_points_det(pl_match.name, :scopa_colore)
      sym_scopacolore_widg = "widg_scopa_colore_#{player_label}"
      @labels_to_disp[sym_scopacolore_widg] = LabelGfx.new(0,0, str_num_scopacolore, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_scopa_colore] = @labels_to_disp[sym_scopacolore_widg]
      
      
      # total points 
      str_num = calculate_str_points_det(pl_match.name, :tot)
      sym_widg = "widg_tot_#{player_label}"
      @labels_to_disp[sym_widg] = LabelGfx.new(0,0, str_num, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_tot] = @labels_to_disp[sym_widg]
      
    end
   
    resize_gfx_points(players)
  end
  
 
  ##
  # Rebuild gfx cards using a new size of cards stack
  # num_card: number of cards in hand of each player
  def rebuild_cards_on_players(num_card)
    @log.debug("Rebuild card on player with num: #{num_card}")
    @num_of_cards = num_card
    @cards_players.set_new_number_ofcards(num_card)
    @cards_players.remove_cards_fromclickable
    # rebuild the card to be displayed
    @players_on_match.each do |player|
      @cards_players.build(player)
    end
  end
  
  ##
  # Override because we need to change the number of cards to display
  def onalg_new_giocata(carte_player)
    @log.debug("New giocata on tombolon gfx")
    rebuild_cards_on_players(4)
    super(carte_player)
  end
  
  ##
  # Expect info as hash with information about the last card on the deck
  def onalg_gameinfo(info)
    if info.class == Hash and info[:deckcard]
       card = info[:deckcard]
       @deck_main.deck_display_lastcard(
          get_card_imagescaled_of(:deckreduced, card), card)
    end
  end
 
  
  # Override because we need to change the number of cards to display
  def onalg_pesca_carta(carte_player)
    if carte_player.size != @num_of_cards
      @log.debug "Resize stack of GfxCards on player hand, new size #{carte_player.size}"
      # number of cards in player hand is changed, need to rebuild the hand
      rebuild_cards_on_players(carte_player.size)
      # need to set initial position for animation distribution
      @cards_players.init_position_ani_distrcards
      
      # need because after rebuild no image is set
      # set image cards of the gui player
      player_sym = @player_on_gui[:player].name.to_sym
      @cards_players.set_cards_player(player_sym, carte_player)
     
    end
    super(carte_player)
    @deck_main.deck_display_lastcard_alreadyset
  end
  
  ##
  # Resize gfx elements like line status, deck
  def resize_gfx_points(players)
    left_align_off = 20
    offlbl_y = 20
    start_toty = 110
    #label for scopa
    players.each do |pl_match|
      player_label = pl_match.name.to_sym
      lbl_gfx_scopa = @points_status[player_label][:widg_scopa]
      lbl_gfx_scopa_colore = @points_status[player_label][:widg_scopa_colore]
      lbl_gfx_tot = @points_status[player_label][:widg_tot] 
      
      lbl_gfx_scopa.pos_x = left_align_off
      lbl_gfx_scopa_colore.pos_x = left_align_off
      lbl_gfx_tot.pos_x = left_align_off
      
      if pl_match.type == :human_local
        human_start_toty = start_toty - 30
        lbl_gfx_scopa.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 2 * offlbl_y)
        
        lbl_gfx_scopa_colore.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 3 * offlbl_y)
        lbl_gfx_tot.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 4 * offlbl_y)
      else
        lbl_gfx_scopa.pos_y = start_toty + 2 * offlbl_y
        lbl_gfx_scopa_colore.pos_y = start_toty + offlbl_y
        lbl_gfx_tot.pos_y = start_toty
      end
    end
  end #end resize_gfx_points
  
  ##
  # Set points into label widgets
  def points_gfx_mano_end_set(curr_points_info, player)
    curr_points_info.each do |pt_item|
      player_label = player.name.to_sym
      
      if pt_item[:scopa_colore]
        @points_status[player_label][:scopa_colore] += pt_item[:scopa_colore]
        @points_status[player_label][:widg_scopa_colore].font_color = @color_signal
        log "#{player.name} ha fatto scopa di colore\n"
      end
    
      if pt_item[:scopa]
        @points_status[player_label][:scopa] += pt_item[:scopa]
        @points_status[player_label][:widg_scopa].font_color = @color_signal
        log "#{player.name} ha fatto scopa\n"
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
      when :scopa_colore
        str_points = "Colore: #{s1}"
      when :scopa
        str_points = "Scope: #{s1}"
      when :tot
        if @core_game
          tot_points = @core_game.game_opt[:target_points]
          str_points = "Punti : #{s1} (#{tot_points})" 
        else
          str_points = "Punti : #{s1}" 
        end       
    end
    
    return str_points
  end
  
  ##
  # Update player points
  def points_gfx_update(player)
    player_label = player.name.to_sym
    #p curr_points_info
    lbl_gfx_scopa = @points_status[player_label][:widg_scopa]
    lbl_gfx_scopa_colore = @points_status[player_label][:widg_scopa_colore]
    
    lbl_gfx_scopa.text = calculate_str_points_det(player.name, :scopa)
    lbl_gfx_scopa_colore.text = calculate_str_points_det(player.name, :scopa_colore)
  end
  
  ##
  # Reset points for the current giocata
  def reset_points_current_giocata
    @players_on_match.each do |pl_match|
      player_label = pl_match.name.to_sym
      @points_status[player_label][:scopa] = 0
      @points_status[player_label][:scopa_colore] = 0
      @points_status[player_label][:num_cards] = 0
      #each player needs last taken cards information
      @taken_card_info_last[player_label] = {} 
      points_gfx_update(pl_match)
    end
  end
  
  ##
  # Reset colors of points labels
  def points_gfx_reset_colors
    @players_on_match.each do |pl_single|
      player_label1 = pl_single.name.to_sym
      @points_status[player_label1][:widg_scopa].font_color = Fox.FXRGB(0, 0, 0)
      @points_status[player_label1][:widg_scopa_colore].font_color = Fox.FXRGB(0, 0, 0)
    end
  end
  
  ##
  # Provides a new instance of the current core. On iherited game you can overwrite
  # this function
  def create_instance_core() 
    @log.debug("Create core instance")
    return CoreGameTombolon.new
  end

  ##
  # Shows the messagebox for smazzata end
  def show_smazzata_end(best_pl_points )
    @log.debug("tombolon smazzata end msgbox")
    @msgbox_smazzataend.SetShortcutsTombolon()
    points_for_msg = []
    names_arr = []
    best_pl_points.each do |pp1_arr|
      name = pp1_arr[0]
      pp1 = pp1_arr[1]
      points_pl = { :tot =>  pp1[:tot], :carte => pp1[:carte], :scope => pp1[:scopa],  
        :settedidenari => pp1[:setbel], :napoli => pp1[:napola], 
        :spade => pp1[:spade], :duedispade=>pp1[:duespade],
        :fantedispade => pp1[:fantespade], :colore => pp1[:scopa_colore],
        :tombolon =>pp1[:tombolon], :raddoppio => pp1[:extra_onori]}
      points_for_msg << points_pl
      names_arr << name
    end
          
    @msgbox_smazzataend.points[:p1] = points_for_msg[0]
    @msgbox_smazzataend.points[:p2] = points_for_msg[1]
    @msgbox_smazzataend.name_p1 = names_arr[0]
    @msgbox_smazzataend.name_p2 = names_arr[1]
    
    @msgbox_smazzataend.set_visible(true)
  end
  
  
end #end TombolonGfx

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
  deck =  RandomManager.new
  #deck.set_predefined_deck('_6d,_7c,_Rc,_Cb,_2s,_6c,_2c,_Cd,_3b,_Fd,_4d,_As,_Fc,_Rs,_Fb,_Fs,_4c,_3c,_5b,_Cs,_3d,_Cc,_5c,_Ad,_6b,_3s,_6s,_2d,_7d,_Rd,_4b,_7s,_Ac,_2b,_Rb,_4s,_5s,_Ab,_5d,_7b', 1)
  #deck.set_predefined_deck('_6b,_Rc,_5d,_Fs,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',1)
  #deck.set_predefined_deck('_6b,_Rc,_5d,_5s,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_Fb,_7d,_2d,_4s,_6d,_3s,_6c,_Cd,_7s,_2s,_4c,_3c,_5c',0)
  deck.set_predefined_deck '_6s,_2c,_Ad,_Ab,_3c,_7s,_4b,_5c,_5b,_5d,_Cd,_Fd,_3d,_4s,_7b,_Cb,_Rc,_3b,_Fs,_5s,_Rd,_Ac,_Cs,_3s,_6d,_4c,_Rb,_Fc,_6b,_As,_Cc,_2b,_4d,_7d,_2s,_Rs,_6c,_7c,_2d,_Fb', 1
  mainwindow.set_custom_deck(deck)
  # end test a custom deck
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu', nil, :cpu_local, 0)
  
  #mainwindow.app_settings["auto_gfx"] = true
  mainwindow.init_gfx(TombolonGfx, players)
  spazz_gfx = mainwindow.current_game_gfx
  mainwindow.app_settings["cpualgo"]["autoplayer"] = {}
  spazz_gfx.option_gfx[:timeout_autoplay] = 50
  spazz_gfx.option_gfx[:autoplayer_gfx_nomsgbox] = false
  theApp.run
end
 

