# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_scopetta.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../../base/core/core_game_base'
  require 'core_game_scopetta'
end

##
# Class used to play briscola automatically
class AlgCpuScopetta < AlgCpuSpazzino
  
  def initialize(player, coregame, cup_gui)
    super(player, coregame, cup_gui)
    @level_alg = :master
    @log = Log4r::Logger.new("coregame_log::AlgCpuScopetta") 
  end
  
  def onalg_new_match(players)
    super
    #p @deck_info
    @log.debug "**** Playing using level #{@level_alg} *****"
  end
  
  def play_like_a_master
    @log.debug "Play at master level"
    maxp_pt_list = 0
    curr_result = []
    cards_on_hand_notaken = []
    @cards_on_hand.each do |card_item|
      list = @core_game.which_cards_pick(card_item, @table_cards)
      if list.size == 0
        cards_on_hand_notaken << card_item
        next
      end
      pt_list, ix_list = rank_picked(card_item, list)
      #@log.debug "++++ [#{card_item}] => list #{list} score #{pt_list}"
      if pt_list > maxp_pt_list
        maxp_pt_list = pt_list
        curr_result = [card_item, list[ix_list]].flatten
      end
    end
    if maxp_pt_list > 0
      @log.debug "Play card #{curr_result[0]} with taken: #{curr_result[1..-1]} score #{maxp_pt_list}"
      return curr_result
    end
    #evaluate a card that should be played on the table
    pt_table = calc_pt_card_arr(@table_cards)
    pt_hands = {}
    cards_on_hand_notaken.each do |card_item|
      pt_hands[card_item] = 1000
      pt_hands[card_item] -= 20 if card_allow_scopa?(card_item, pt_table)
      pt_hands[card_item] -= 10 if card_is_denari?(card_item)
      pt_hands[card_item] -= 12 if card_is_sette?(card_item)
      pt_hands[card_item] -= 32 if card_is_onore?(card_item)
      pt_hands[card_item] -= 7 if card_is_part_of_napola?(card_item)
      pt_hands[card_item] += 17 if card_allow_combi_trick?(card_item)
    end
    max_val_tb = 0
    card_on_max = nil
    pt_hands.each do |k,v|
      if v > max_val_tb
        card_on_max = k
        max_val_tb = v
      end
    end
    @log.debug "Play a card NO take #{card_on_max} with score #{max_val_tb}"
    return [card_on_max]
  end#end play_like_a_master
  
  def card_allow_combi_trick?(card_item)
    tbl_tmp = []
    @table_cards.each {|x| tbl_tmp << x}
    tbl_tmp << card_item
    bres = false
    @cards_on_hand.each do |rest_card|
      next if rest_card == card_item
      list = @core_game.which_cards_pick(rest_card, tbl_tmp)
      #rank_picked(card_player, list_of_list)
      return true if list.size > 0
    end
    return false
  end
  
  def card_allow_scopa?(card_item, pt_table)
    return @deck_info[card_item][:rank] + pt_table <= 10
  end
  
  def calc_pt_card_arr(card_arr)
    sum = 0
    card_arr.each do |card_item|
      #p @deck_info[card_item]
      sum += @deck_info[card_item][:rank]
    end
    return sum
  end
  
  def rank_picked(card_player, list_of_list)
    max_pt = 0
    max_ix = 0
    list_of_list.each_index do |curr_ix|
      curr_pt = 0
      list = list_of_list[curr_ix]
      curr_pt += 100 if taken_is_scopa?(list)
      list.each do |card_tb|
        curr_pt += 3
        curr_pt += 20 if card_is_denari?(card_tb) 
        curr_pt += 40 if card_is_onore?(card_tb) 
        curr_pt += 20 if card_is_sette?(card_tb) 
        curr_pt += 5 if card_is_part_of_napola?(card_tb) 
      end
      if curr_pt >  max_pt 
        max_pt = curr_pt
        max_ix = curr_ix
      end
    end
    return max_pt, max_ix
  end
  
  def taken_is_scopa?(list_taken)
    return list_taken.size == @table_cards.size ? true : false
  end
  
  def card_is_denari?(card_tb)
    return @deck_info[card_tb][:segno] == :D
  end
  
  def card_is_onore?(card_tb)
    return card_tb == :_7d
  end
  
  def card_is_sette?(card_tb) 
    return @deck_info[card_tb][:symb] == :_sette 
  end
  
  def card_is_part_of_napola?(card_tb)
    return ((card_tb == :_Ad) or (card_tb == :_2d)or (card_tb == :_3d))
  end
  
end #end AlgCpuScopetta

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameScopetta.new
  replay_a_game = false # cambia questo flag se vuoi ripetere una partita
  if replay_a_game
    rep = ReplayerManager.new(log)
    match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/spazzino/saved_games/alg_flaw_02.yaml')
    #p match_info
    player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
    alg_cpu1 = AlgCpuScopetta.new(player1, core)
    
    player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
    alg_cpu2 = AlgCpuScopetta.new(player2, core)
    alg_cpu2.level_alg = :dummy
    
    alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
    segno_num = 0
    rep.alg_cpu_contest = true
    rep.replay_match(core, match_info, alg_coll, segno_num)
  else
    deck =  RandomManager.new
    deck.set_predefined_deck('_4c,_Fd,_Ad,_Cc,_7s,_Rs,_6s,_Ac,_Fs,_3d,_7b,_5d,_Ab,_5b,_5c,_2s,_Cs,_7d,_3s,_4d,_2c,_2d,_Cb,_2b,_Rc,_Fb,_5s,_4s,_4b,_3c,_6c,_3b,_Cd,_Rd,_As,_6b,_6d,_Rb,_7c,_Fc',0)
    core.rnd_mgr = deck 
    core.game_opt[:replay_game] = true
    
    # testa algoritmo
    player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
    player1.algorithm = AlgCpuScopetta.new(player1, core, nil)
    #player1.algorithm.level_alg = :master
    player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
    player2.algorithm = AlgCpuScopetta.new(player2, core, nil)
    player2.algorithm.level_alg = :master
    arr_players = [player1,player2]
    
    core.gui_new_match(arr_players)
    event_num = core.process_only_one_gevent
    while event_num > 0
      event_num = core.process_only_one_gevent
    end
  end
  
end
