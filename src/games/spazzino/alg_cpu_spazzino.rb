# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_spazzino.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../../base/core_game_base'
end

##################################################### 
##################################################### AlgCpuSpazzino
#####################################################

##
# Class used to play briscola automatically
class AlgCpuSpazzino < AlgCpuPlayerBase
  attr_accessor :level_alg, :alg_player
  ##
  # Initialize algorithm of player
  # player: player that use this algorithm instance
  # coregame: core game instance used to notify game changes
  # cup_gui: gui to signal algorithm events for suspending functions
  def initialize(player, coregame, cup_gui)
    # cuperativa main gui
    @cupera_gui = cup_gui
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
    @level_alg = :dummy #:master #:dummy
    # deck info for points and rank
    @deck_info = CoreGameBase.mazzo_italiano
    # opponents names 
    @opp_names = []
    # team mate 
    @team_mates = []
    # target points
    @target_points = @core_game.game_opt[:target_points]
    # cards on deck
    @num_cards_on_deck = 0
    # cards on table
    @table_cards = []
    # predifined game
    @action_queue = []
    # num of cards on hand 
    @num_cards_on_hand = 3
    # algorithm options
    @option_gfx = {
      :timeout_haveplay => 700
    }
    @log = Log4r::Logger.new("coregame_log::AlgCpuSpazzino") 
  end
  
  ##
  # Briscola was changed
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand)
    @log.error("onalg_player_has_changed_brisc: not exist")
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
        # action not for the algorithm player
      end
    end
  end
  
  ##
  # Alg is on new giocata. carte_player is an array with all cards for player
  # card on table are on end 
  def onalg_new_giocata(carte_player)
    @num_cards_on_deck = 40 - @num_cards_on_hand * @players.size - 4
    @table_cards = [] 
    str_card = ""
    str_table = ""
    @cards_on_hand = []
    #p @num_cards_on_hand
    carte_player[0..@num_cards_on_hand - 1].each do |card| 
      @cards_on_hand << card
    end
    carte_player[@num_cards_on_hand..-1].each do |card| 
      @table_cards << card
    end
    @cards_on_hand.each{|card| str_card << "#{card.to_s} "}
    @table_cards.each{|card| str_table << "#{card.to_s} "}
    @players.each do |pl|
      @points_segno[pl.name] = 0
    end 
    @log.info "ALG:#{@alg_player.name} cards: #{str_card} table: #{str_table}"
  end
  
  ##
  # Algorithm have to play
  def onalg_have_to_play(player,command_decl_avail)
    cards = []
    @log.debug("onalg_have_to_play cpu alg: #{player.name}")
    if player == @alg_player
      if @cupera_gui
        @cupera_gui.registerTimeout(@option_gfx[:timeout_haveplay], :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to sloow down the algorithm play
        @core_game.suspend_proc_gevents
        @log.debug("onalg_have_to_play cpu alg: #{player.name}")
      else
        # no wait for gfx stuff, continue immediately to play
        alg_play_acard
      end
      # continue on onTimeoutHaveToPlay
    end
      
  end
  
  ##
  # onTimeoutHaveToPlay: after wait a little for gfx purpose the algorithm play a card
  def onTimeoutAlgorithmHaveToPlay
    alg_play_acard
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  def alg_play_acard
    case @level_alg 
      when :master
        cards = play_like_a_master
      when :predefined
        cards = play_with_predifined
      else
        cards = play_like_a_dummy
    end
    # notify card played to core game
    @core_game.alg_player_cardplayed_arr(@alg_player, cards)
    @log.error "No cards on hand - programming error" unless cards
  end 
  
  ##
  # Play using a predifined playing algorithmus
  def play_with_predifined
    while @action_queue.size > 0
      action = @action_queue.slice!(0)
      #p "Action....."
      #action is something like: {:type=>:cardplayedarr, :arg=>["Alex", [:_6d, :_4c, :_2d]]}
      #p action
      if action[:type] == :cardplayedarr
        cards = action[:arg][1]
        # use predifined action
        return cards
      end
    end
    # no cards found in action
    @log.warn "No cards found in predifined action, use dummy alg"
    return play_like_a_dummy
  end
  
  ##
  # Play like briscola master
  def play_like_a_master
    card = nil
    #TODO
    return card
  end
  
  ##
  # Play as master as second
  def play_as_master_second
    
  end
  
 
  ##
  # Play as master first
  def play_as_master_first
    
  end
  
  ##
  # Provides the card to play in a very dummy way
  def play_like_a_dummy
    # very brutal algorithm , always play the first card
    #card = @cards_on_hand.pop
    #p @cards_on_hand.size
    card = @cards_on_hand[0]
    if card
      # check if the played card take something
      #@table_cards
      
      #@log.debug "Alg: cards on table #{@table_cards}"
      list = @core_game.which_cards_pick(card, @table_cards)
      #p "which cards pick: card #{card}, table #{@table_cards.join(",")}, list #{list.size}"
      result = [card, list[0]].flatten
      return result
    end
    raise "Error cards on hand #{@cards_on_hand.join(',')}" 
  end
  
  ##
  # Algorithm pick up a new card
  # carte_player: card picked from deck
  def onalg_pesca_carta(carte_player)
    #expect only one card
    @log.info "ALG[#{@alg_player.name}]: card picked #{carte_player.join(",")}"
    carte_player.each do |card|
      @cards_on_hand << card
    end 
    if @cards_on_hand.size > @num_cards_on_hand
      raise "ERROR onalg_pesca_carta: #{@cards_on_hand}"
    end
    @num_cards_on_deck -= (carte_player.size *  @players.size)   
  end
  
  def onalg_player_has_played(player, card)
    #p "onalg_player_has_played, #{player.name}, #{card}"
    if player != @alg_player
      @card_played <<  card
    else
      #p "delete #{card}"
      @cards_on_hand.delete(card[0])
      #p @cards_on_hand
    end
  end
  
  def onalg_player_cardsnot_allowed(player, arr_lbl_card)
    @log.error("ERROR programming: #{arr_lbl_card} is not allowed to be played")
  end
  
  def onalg_player_has_declared(player, name_decl, points)
    @log.error("onalg_player_has_declared not supported")
  end
  
  def onalg_player_has_getpoints(player, points)
    #@points_segno[player.name] +=  points
    @log.error("onalg_player_has_getpoints not supported")
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
  
  #
  #table_player_info: array of two elements: first is the player, second are cards on table
  def onalg_newmano(table_player_info)
    @card_played = []
    @table_cards =  table_player_info[1]
  end
  
  def onalg_manoend(player_best, dummy, point_events) 
    
  end
  
  def onalg_player_has_taken(player, arr_lbl_card)
  end
  
end #end AlgCpuSapzzino

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_spazzino'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameSpazzino.new
  rep = ReplayerManager.new(log)
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/spazzino/saved_games/alg_flaw_02.yaml')
  #p match_info
  player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  alg_cpu1 = AlgCpuSpazzino.new(player1, core)
  
  player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
  alg_cpu2 = AlgCpuSpazzino.new(player2, core)
  alg_cpu2.level_alg = :dummy
  
  alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
  segno_num = 0
  rep.alg_cpu_contest = true
  rep.replay_match(core, match_info, alg_coll, segno_num)
end
