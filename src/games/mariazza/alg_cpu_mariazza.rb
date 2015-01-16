# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_mariazza.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../../base/core_game_base'
end

##################################################### 
##################################################### AlgCpuMariazza
#####################################################

##
# Class used to play mariazza automatically
class AlgCpuMariazza < AlgCpuPlayerBase
  attr_accessor :level_alg, :alg_player
  ##
  # Initialize algorithm of player
  # player: player that use this algorithm instance
  # coregame: core game instance used to notify game changes
  def initialize(player, coregame, cup_gui)
    # set algorithm player
    @alg_player = player
    # logger
    @log = Log4r::Logger["coregame_log"]
    # core game
    @core_game = coregame
    # cards in current player
    @cards_on_hand = []
    # points hash using player name as key, with array of card label
    @points_segno = {}
    # card played on table
    @card_played = []
    # array of players
    @players = nil
    # alg level 
    @level_alg = :master #:dummy
    # briscola
    @briscola = nil
    # deck info for points and rank
    @deck_info = CoreGameBase.mazzo_italiano
    # opponents names 
    @opp_names = []
    # team mate 
    @team_mates = []
    # target points
    @target_points = @core_game.game_opt[:target_points_segno]
    # mariazza available on suite
    @mariazz_on_suite = {}
    # strotti available on suite
    @strozzi_on_suite = {}
    # cuperativa main gui
    @cupera_gui = cup_gui
    # store commands when usign delay player
    @command_decl_avail = []
    # algorithm options
    @option_gfx = {
      :timeout_haveplay => 700
    }
  end
  
  ##
  # Briscola was changed
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    @log.debug("onalg_player_has_changed_brisc: card_briscola: #{card_briscola}, card_on_hand: #{card_on_hand}")
    if player == @alg_player
      # adjust the deck before playing, the 7 is not in the player hand anymore
      @cards_on_hand.each_index do |ix|
        if @cards_on_hand[ix] == card_on_hand
          @cards_on_hand[ix] = card_briscola
          @log.debug("onalg_player_has_changed_brisc, hand adjusted: #{@cards_on_hand.to_s}")
          break
        end
      end
    end
  end
  
  ##
  # Alg is on new giocata. carte_player is an array with all cards for player
  # hand and briscola at the end
  def onalg_new_giocata(carte_player)
    ["b", "d", "s", "c"].each do |segno|
      @strozzi_on_suite[segno] = 2
      @mariazz_on_suite[segno] = true
    end
    @alg_is_waiting = false
   
    str_card = ""
    @cards_on_hand = []
    carte_player.each do |card| 
      @cards_on_hand << card
    end
    @briscola = @cards_on_hand.pop
    @cards_on_hand.each{|card| str_card << "#{card.to_s} "}
    @players.each do |pl|
      @points_segno[pl.name] = 0
    end 
    @log.info "#{@alg_player.name} cards: #{str_card}, briscola is #{@briscola.to_s}"
  end
  
  ##
  # onTimeoutHaveToPlay: after wait a little for gfx purpose the algorithm play a card
  def onTimeoutAlgorithmHaveToPlay
    @alg_is_waiting = false
    alg_play_acard(@command_decl_avail)
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  ##
  # Algorithm have to play
  def onalg_have_to_play(player,command_decl_avail)
    if player == @alg_player
      @log.debug("onalg_have_to_play cpu alg: #{player.name}")
      if @cupera_gui
        if @alg_is_waiting == true
          # we still wait for time out
          return
        end
        @alg_is_waiting = true
        @command_decl_avail = command_decl_avail
        @cupera_gui.registerTimeout(@option_gfx[:timeout_haveplay], :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to slow down the algorithm play
        @core_game.suspend_proc_gevents
        @log.debug("onalg_have_to_play cpu alg: #{player.name}")
      else
        # no wait for gfx stuff, continue immediately to play
        alg_play_acard(command_decl_avail)
      end
    end 
  end
  
  ##
  # Algorithm play one card
  def alg_play_acard(command_decl_avail)
    player = @alg_player
    if command_decl_avail.size > 0
      # there are declaration
      cmd_change_brisc_def = nil
      # check if there is a change briscola command
      command_decl_avail.each do |item| 
        if item[:change_briscola]
          # we have only set the change briscola hash {:briscola => lbl, :on_hand => lbl}
          cmd_change_brisc_def = item[:change_briscola] 
        end 
      end
      if cmd_change_brisc_def
        # we have a change briscola command
        res_allow = @core_game.alg_player_change_briscola(player, cmd_change_brisc_def[:briscola], cmd_change_brisc_def[:on_hand])
        @log.info "#{@alg_player.name} alg_player_change_briscola #{cmd_change_brisc_def[:briscola]} with #{cmd_change_brisc_def[:on_hand]}"
        # now wait for a confirm
        if res_allow == :allowed
          return
        else
          @log.error "ERROR #{@alg_player.name} change briscola"
        end
      else
        # mariazza declaration
        # look on the max mariazza
        mar_max = command_decl_avail.max{|a,b| a[:points] <=> b[:points]}
        @log.info "#{@alg_player.name} declare #{mar_max[:name]}"
        # make declaration
        @core_game.alg_player_declare(player, mar_max[:name] )
        # now wait for confirm to continue
        # IMPORTANT return, otherwise we get called two time
        return
      end
    end
    case @level_alg 
      when :master
        card = play_like_a_master
      else
        card = play_like_a_dummy
    end
    #card = play_like_a_master
    # notify card played to core game
    @core_game.alg_player_cardplayed(@alg_player, card)
    @log.error "No cards on hand - programming error" unless card
  end
  
  ##
  # Play like mariazza master
  def play_like_a_master
    card = nil
    case @card_played.size
      when 0
        card = play_as_master_first
      when 1
        card = play_as_master_second
    end
    return card
  end
  
  ##
  # Provides true if maziazza is still declarable on the given suite
  # suit: a string like "b" for suite bastoni. 1 character length
  def is_mariazz_possible?(suit)
    return @mariazz_on_suite[suit]
  end
  
  ##
  # Play as master as second
  def play_as_master_second
    card_avv_s = @card_played[0].to_s
    card_avv_info = @deck_info[@card_played[0]]
    max_points_take = 0
    max_card_take = @cards_on_hand[0]
    min_card_leave = @cards_on_hand[0]
    min_points_leave = 120
    take_it = []
    leave_it = []
    # build takeit leaveit arrays
    @cards_on_hand.each do |card_lbl|
      card_s = card_lbl.to_s
      bcurr_card_take = false
      card_curr_info = @deck_info[card_lbl]
      if card_s[2] == card_avv_s[2]
        # same suit
        if card_curr_info[:rank] > card_avv_info[:rank]
          # current card take
          bcurr_card_take = true
          take_it << card_lbl
        else
          leave_it << card_lbl
        end
      elsif card_s[2] == @briscola.to_s[2]
        # this card is a briscola 
        bcurr_card_take = true
        take_it << card_lbl
      else
        leave_it << card_lbl
      end
      # check how many points make the card if it take
      points = card_curr_info[:points] + card_avv_info[:points]
      if bcurr_card_take
        if points > max_points_take
          max_card_take = card_lbl
          max_points_take = points
        end
      else
        # leave it as minimum
        if points < min_points_leave
          min_card_leave = card_lbl
          min_points_leave = points
        end
      end
    end
    curr_points_me = 0
    @team_mates.each{ |name_pl| curr_points_me += @points_segno[name_pl] }
    tot_points_if_take = curr_points_me + max_points_take
    curr_points_opp = 0
    @opp_names.each{ |name_pl| curr_points_opp += @points_segno[name_pl] }
    
    #p take_it
    #p leave_it
    #p max_points_take
    #p min_points_leave
    if take_it.size == 0
      #take_it is not possibile, use leave it
      @log.debug("play_as_master_second, apply R1")
      return min_card_leave  
    end
    max_card_take_s = max_card_take.to_s
    if tot_points_if_take >= @target_points
      # take it, we win
      @log.debug("play_as_master_second, apply R2")
      return max_card_take
    end
    if max_card_take_s[2] == @briscola.to_s[2]
      # card that take is briscola, pay attention to play it
      if max_points_take >= 20
        @log.debug("play_as_master_second, apply R3")
        return max_card_take
      end
    elsif max_points_take >= 10
      # take it, strosa!
      @log.debug("play_as_master_second, apply R4")
      return max_card_take
    end
    if take_it.size > 0
      # we can take it
      if curr_points_opp > 28 and max_points_take > 0
        # try to take it
        @log.debug("play_as_master_second, apply R5")
        return best_taken_card(take_it)
      end
      if min_points_leave > 3
        # I am loosing too many points?
        @log.debug("play_as_master_second, apply R6")
        return best_taken_card(take_it)
      end
    end 
    # leave it
    @log.debug("play_as_master_second, apply R7")
    return min_card_leave 
    #crash
  end
  
  ##
  # Provides the best card from the take_it list
  # take_it: array of cards that ha to be played
  def best_taken_card(take_it)
    @log.debug("calculate best_taken_card") 
    w_cards = []
    take_it.each do |card_lbl|
      card_s = card_lbl.to_s # something like '_Ab'
      segno = card_s[2,1] # character with index 2 and string len 1
      curr_w = 0
      curr_w += 200 if  card_s[2] == @briscola.to_s[2]
      # check if it is an asso or 3
      curr_w += 9 if card_s[1] == "A"[0]
      curr_w += 7 if card_s[1] == "3"[0] 
      if card_s =~ /[24567]/
        # liscio value
        lisc_val = (card_s[1] - '0'[0]).to_i
        curr_w += 70 + lisc_val
      end
      curr_w += 40 if card_s[1] == "F"[0]
      # mariazza is possible?, horse and king has a different value
      if card_s[1] == "C"[0]
        if is_mariazz_possible?(segno)
          curr_w += 90
        else
          curr_w += 30
        end
      end 
      if card_s[1] == "R"[0]
        if is_mariazz_possible?(segno)
          curr_w += 100
        else
          curr_w += 20
        end
      end
      w_cards << [card_lbl, curr_w ]  
    end
    # find a minimum
    #p w_cards
    min_list = w_cards.min{|a,b| a[1]<=>b[1]}
    @log.debug("Best card to play on best_taken_card is #{min_list[0]}, w_cards = #{w_cards.to_s}")
    return min_list[0]
  end
  
  ##
  # Play as master first
  def play_as_master_first
    w_cards = []
    @cards_on_hand.each do |card_lbl|
      card_s = card_lbl.to_s # something like '_Ab'
      segno = card_s[2,1] # character with index 2 and string len 1 
      curr_w = 0
      curr_w += 70 if  card_s[2] == @briscola.to_s[2]
      # check if it is an asso or 3
      curr_w += 220 if card_s[1] == "A"[0]
      curr_w += 200 if card_s[1] == "3"[0] 
      if card_s =~ /[24567]/
        # liscio value
        lisc_val = (card_s[1] - '0'[0]).to_i
        curr_w += 50 + lisc_val
      end
      curr_w += 60 if card_s[1] == "F"[0]
      # check horse and king cards
      if card_s[1] == "C"[0]
        if is_mariazz_possible?(segno)
          curr_w += 90 + 70
        else
          curr_w += 30
        end
      end 
      if card_s[1] == "R"[0]
        if is_mariazz_possible?(segno)
          curr_w += 100 + 70
        else
          curr_w += 20
        end
      end
      # penalty for cards wich are not stroz free
      curr_w += 10 * @strozzi_on_suite[segno]
      
      w_cards << [card_lbl, curr_w ]  
    end
    # find a minimum
    #p w_cards
    min_list = w_cards.min{|a,b| a[1]<=>b[1]}
    @log.debug("Play as first: best card#{min_list[0]}, (w_cards = #{w_cards.to_s})")
    return min_list[0]
  end
  
  ##
  # Provides the card to play in a very dummy way
  def play_like_a_dummy
    # very brutal algorithm , always play the first card
    card = @cards_on_hand.pop
  end
  
  ##
  # Algorithm pick up a new card
  # carte_player: card picked from deck
  def onalg_pesca_carta(carte_player)
    #expect only one card
    @log.info "Algorithm card picked #{carte_player.first}"
    @cards_on_hand << carte_player.first    
  end
  
  def onalg_player_has_played(player, card)
    if player != @alg_player
      @card_played <<  card
    else
      @cards_on_hand.delete(card)
    end
    card_s = card.to_s
    segno = card_s[2,1]
    if card_s[1] == "C"[0] or card_s[1] == "R"[0]
      # if a player play a Horse or a King there is no more declaration  
      @mariazz_on_suite[segno] = false
    end 
    if card_s[1] == "A"[0] or card_s[1] == "3"[0]
      @strozzi_on_suite[segno] -= 1
    end
  end
  
  def onalg_player_has_declared(player, name_decl, points)
    suit_decl = nil
    case name_decl
      when "Mariazza di denari"
        suit_decl = "d"
      when "Mariazza di spade"
        suit_decl = "s"
      when "Mariazza di coppe"
        suit_decl = "c"
      when "Mariazza di bastoni"
        suit_decl = "b"
    end
    @mariazz_on_suite[suit_decl] = false if suit_decl
    @points_segno[player.name] +=  points
  end
  
  def onalg_player_has_getpoints(player, points)
    @points_segno[player.name] +=  points
  end
  
  def onalg_new_match(players)
    @opp_names = []
    @team_mates = []
    @players = players
    unless @deck_info[:rank] 
      # we have a raw deck_info, build information for rank and points
      val_arr_rank   = [12,2,11,4,5,6,7,8,9,10] # card value order
      val_arr_points = [11,0,10,0,0,0,0,2,3,4] # card points
      @deck_info.each do |k, card|
        # add points and rank 
        curr_index = card[:ix]
        card[:rank] = val_arr_rank[curr_index % 10]
        card[:points] = val_arr_points[curr_index % 10]
      end
    end
    # first check wich index is mine
    index = 0
    ix_me = 0
    players.each do |pl| 
      ix_me = index if pl.name == @alg_player.name
      index += 1
    end
    index = 0
    players.each do |pl|
      #p pl.name
      @points_segno[pl.name] = 0
      if is_opponent?(index,ix_me)
        @opp_names << pl.name
      else
        @team_mates << pl.name
      end
      index += 1
    end
    #p @opp_names
    #p @team_mates.size
  end
  
  ##
  # Provides true if index is opponent index
  # ix_me: index of the current algorithm
  # index: index to check
  def is_opponent?(index,ix_me)
    if ix_me == 0 or ix_me == 2
      if index == 1 or index == 3
        return true
      else
        return false
      end
    else
      if index == 0 or index == 2
        return true
      else
        return false
      end
    end
   
  end
  
  def onalg_newmano(player)
    @card_played = [] 
  end
  
  def onalg_manoend(player_best, carte_prese_mano, punti_presi) 
    @points_segno[player_best.name] +=  punti_presi
  end
  
end #end AlgCpuMariazza

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_mariazza'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameMariazza.new
  rep = ReplayerManager.new(log)
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/mariaz_sett_cam_brisc.yaml')
  #p match_info
  player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  alg_cpu1 = AlgCpuMariazza.new(player1, core, nil)
  
  player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
  alg_cpu2 = AlgCpuMariazza.new(player2, core, nil)
  alg_cpu2.level_alg = :master
  
  alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
  segno_num = 0
  rep.alg_cpu_contest = true
  rep.replay_match(core, match_info, alg_coll, segno_num)
end
