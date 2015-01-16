# spazzino_gfx.rb
# Handle display for scopetta graphic engine

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'games/spazzino/spazzino_gfx' # base core class of scopetta
require 'core_game_scopetta'


##
# Spazzino Gfx implementation
class ScopettaGfx < SpazzinoGfx
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @splash_name = File.join(@resource_path, "icons/scopetta.png")
    @algorithm_name = "AlgCpuScopetta"
    
    ## option for graphic engine on spazzino gfx
    #@option_gfx = {
      #:timout_manoend => 800, 
      #:timeout_player => 400, # not used
      #:timeout_manoend_continue => 200,
      #:timeout_manoend_viewtaken => 900,
      #:timeout_msgbox => 3000,
      #:timeout_autoplay => 1000,
      #:timeout_animation_cardtaken => 20,
      #:timeout_animation_cardplayed => 20,
      #:timeout_animation_carddistr => 20,
      #:timeout_reverseblit => 100,
      #:timeout_lastcardshow => 1200,
      #:carte_avvers => true,
      #:use_dlg_on_core_info => true,
      ## automatic player
      #:autoplayer_gfx => false,
      ## disappear msgbox after timeout when using automatic player
      #:autoplayer_gfx_nomsgbox => true
    #}
    
  end
  
  ##
  # Builds wiidgets for player points
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
      
      # total points 
      str_num = calculate_str_points_det(pl_match.name, :tot)
      sym_widg = "widg_tot_#{player_label}"
      @labels_to_disp[sym_widg] = LabelGfx.new(0,0, str_num, @font_text_curr[:medium], color, true)
      @points_status[player_label][:widg_tot] = @labels_to_disp[sym_widg]
      
    end
   
    resize_gfx_points(players)
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
      lbl_gfx_tot = @points_status[player_label][:widg_tot] 
      
      lbl_gfx_scopa.pos_x = left_align_off
      lbl_gfx_tot.pos_x = left_align_off
      
      if pl_match.type == :human_local
        human_start_toty = start_toty - 30
        #lbl_gfx_scopa.pos_y = @curr_canvas_info[:height] - ( human_start_toty + 2 * offlbl_y)
        #lbl_gfx_tot.pos_y = @curr_canvas_info[:height] - ( human_start_toty + 3 * offlbl_y)  
        lbl_gfx_scopa.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 2 * offlbl_y)
        lbl_gfx_tot.pos_y = @model_canvas_gfx.info[:canvas][:height] - ( human_start_toty + 3 * offlbl_y)  
      else
        lbl_gfx_scopa.pos_y = start_toty + offlbl_y
        lbl_gfx_tot.pos_y = start_toty
      end
    end
  end #end resize_gfx_points
  
  ##
  # Set points into label widgets
  def points_gfx_mano_end_set(curr_points_info, player)
    curr_points_info.each do |pt_item|
      player_label = player.name.to_sym
    
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
      when :scopa
        str_points = "Scope: #{s1}"
      when :tot
        tot_points = @core_game.game_opt[:target_points]
        str_points = "Punti : #{s1} (#{tot_points})"       
    end
    
    return str_points
  end
  
  ##
  # Update player points
  def points_gfx_update(player)
    player_label = player.name.to_sym
    #p curr_points_info
    lbl_gfx_scopa = @points_status[player_label][:widg_scopa]
    lbl_gfx_scopa.text = calculate_str_points_det(player.name, :scopa)
    
  end
  
  ##
  # Reset points for the current giocata
  def reset_points_current_giocata
    @players_on_match.each do |pl_match|
      player_label = pl_match.name.to_sym
      @points_status[player_label][:scopa] = 0
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
    end
  end
  
  ##
  # Provides a new instance of the current core. On iherited game you can overwrite
  # this function
  def create_instance_core() 
    @log.debug("Create an automate AlgCpuScopetta for gfx player")
    return CoreGameScopetta.new
  end
  
  ###
  ## Create a scopetta automate
  #def create_algorithm_player(player, core, gui)
    #return AlgCpuScopetta.new(player, core, gui)
  #end
  
  ##
  # Shows the messagebox for smazzata end
  def show_smazzata_end(best_pl_points )
    @log.debug("scopetta smazzata end msgbox")
    #@msgbox_smazzataend = SmazzataInfoMbox.new("Smazzata finita", 
    #                200,50, 400,350, @font_text_curr[:medium])
    @msgbox_smazzataend.SetShortcutsScopettta
    
    points_for_msg = []
    names_arr = []
    best_pl_points.each do |pp1_arr|
      name = pp1_arr[0]
      pp1 = pp1_arr[1]
      points_pl = { :tot =>  pp1[:tot], :carte => pp1[:carte], :scope => pp1[:scopa],  
        :settedidenari => pp1[:setbel], :napoli => pp1[:napola], 
        :denari => pp1[:denari],
        :primiera =>pp1[:primiera] 
      }
      points_for_msg << points_pl
      names_arr << name
    end
          
    @msgbox_smazzataend.points[:p1] = points_for_msg[0]
    @msgbox_smazzataend.points[:p2] = points_for_msg[1]
    @msgbox_smazzataend.name_p1 = names_arr[0]
    @msgbox_smazzataend.name_p2 = names_arr[1]
    
    @msgbox_smazzataend.set_visible(true)
    #@widget_list_clickable << @msgbox_smazzataend
    #@msgbox_smazzataend.creator = self 
  end
  
end #end ScopettaGfx

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
  #deck =  RandomManager.new
  #deck.set_predefined_deck('_Rs ,_Fc ,_2s ,_6s ,_Fd ,_4d ,_7b ,_7c ,_Cd ,_4s ,_2d ,_Ad ,_Cb ,_As ,_Cc ,_2b ,_Fs ,_Rb ,_Rd ,_Rc ,_4b ,_Ac ,_6b ,_Cs ,_3d ,_7s ,_3b ,_5s,_5c,_3c,_7d,_4c,_5d,_3s,_6c,_6d,_5b,_2c,_Ab,_Fb', 0)
  #deck.set_predefined_deck('_6d,_7c,_Rc,_Cb,_2s,_6c,_2c,_Cd,_3b,_Fd,_4d,_As,_Fc,_Rs,_Fb,_Fs,_4c,_3c,_5b,_Cs,_3d,_Cc,_5c,_Ad,_6b,_3s,_6s,_2d,_7d,_Rd,_4b,_7s,_Ac,_2b,_Rb,_4s,_5s,_Ab,_5d,_7b', 1)
  #deck.set_predefined_deck('_6b,_Rc,_5d,_Fs,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_6c,_7d,_2d,_2s,_6d,_3s,_Fb,_Cd,_4s,_7s,_4c,_3c,_5c',1)
  #deck.set_predefined_deck('_6b,_Rc,_5d,_5s,_Rb,_7b,_5b,_As,_7c,_4b,_2b,_Cc,_Fc,_Cs,_4d,_Rs,_Rd,_Cb,_Ab,_2c,_Fs,_3b,_Fd,_Ad,_Ac,_3d,_6s,_Fb,_7d,_2d,_4s,_6d,_3s,_6c,_Cd,_7s,_2s,_4c,_3c,_5c',0)
  #deck.set_predefined_deck '_6s,_2c,_Ad,_Ab,_3c,_7s,_4b,_5c,_5b,_5d,_Cd,_Fd,_3d,_4s,_7b,_Cb,_Rc,_3b,_Fs,_5s,_Rd,_Ac,_Cs,_3s,_6d,_4c,_Rb,_Fc,_6b,_As,_Cc,_2b,_4d,_7d,_2s,_Rs,_6c,_7c,_2d,_Fb', 0
  #mainwindow.set_custom_deck(deck)
  # end test a custom deck
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('Scarrafone', nil, :human_local, 0)
  players << PlayerOnGame.new('maestro', nil, :cpu_local, 0)
  
  
  yamlgame = 'scopetta2p_60_2010_10_16_11_46_10-savedmatch.yaml'
  savedgame = File.dirname(__FILE__) + '/../../../test/scopetta/saved_games/' + yamlgame
  savedgame = File.expand_path(savedgame)
  mainwindow.app_settings["cpualgo"][:saved_game] = savedgame
  mainwindow.app_settings["cpualgo"][:giocata_num] = 0
  mainwindow.app_settings["cpualgo"][:player_name] = 'maestro'
  mainwindow.app_settings["cpualgo"][:player_name_gui] = 'Scarrafone'
  mainwindow.app_settings["games"][:scopetta_game] = {:target_points => 11}
  # NOTA: per rigiocare la partita serve il mazzo predefinito della partita e la linea qua sotto
  #mainwindow.app_settings["cpualgo"][:predefined] = true #rigioca la partita
  
  #mainwindow.app_settings["auto_gfx"] = true
  mainwindow.init_gfx(ScopettaGfx, players)
  spazz_gfx = mainwindow.current_game_gfx
  spazz_gfx.option_gfx[:timeout_autoplay] = 50
  spazz_gfx.option_gfx[:autoplayer_gfx_nomsgbox] = false
  theApp.run
end
 

