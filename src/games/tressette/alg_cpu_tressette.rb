# file: alg_cpu_tressette.rb

require 'rubygems'

##
# Class used to play  automatically
class AlgCpuTressette < AlgCpuPlayerBase
  attr_accessor :level_alg, :alg_player
  ##
  # Initialize algorithm of player
  # player: player that use this algorithm instance
  # coregame: core game instance used to notify game changes
  def initialize(player, coregame, game_wnd)
    @game_wnd = game_wnd
    # set algorithm player
    @alg_player = player
    # logger
    @log = Log4r::Logger.new("coregame_log::AlgCpuTressette") 
    # core game
    @core_game = coregame
    # cards in current player
    @cards_on_hand = {:B => [], :D => [], :C => [], :S => []}
    @num_carte_gioc_in_suit = {:B => 10, :C=> 10, :D=> 10, :S=> 10}
    # points hash using player name as key, with array of card label
    @points_segno = {}
    # card played on table
    @card_played = []
    # array of players
    @players = nil
    # alg level 
    @level_alg = :master
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
    # predifined game
    @action_queue = []
    # num of cards on hand 
    @num_cards_on_hand = @core_game.num_of_cards_onhandplayer
    @points_player = {}
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
  
  def onalg_new_giocata(carte_player)
    @num_mani = 0
    @num_carte_gioc_in_suit = {:B => 10, :C=> 10, :D=> 10, :S=> 10}
    @num_cards_on_deck = 40 - @num_cards_on_hand * @players.size
    str_card = ""
    @cards_on_hand = {:B => [], :D => [], :C => [], :S => []}
    #p @num_cards_on_hand
    carte_player[0..@num_cards_on_hand - 1].each do |card| 
      put_cards_onhand(card)
    end
    @cards_on_hand.each{|card| str_card << "#{card.to_s} "}
    @players.each do |pl|
      @points_segno[pl.name] = 0
    end 
    @log.info "ALG:#{@alg_player.name} cards: #{str_card}"
  end
  
  def count_cards_onhand
    res = 0
    @cards_on_hand.each do |k,v|
      res += v.size
    end
    return res
  end
  
  ##
  # Algorithm have to play
  def onalg_have_to_play(player,command_decl_avail)
    cards = []
    if player == @alg_player
      @log.debug("onalg_have_to_play cpu alg: #{player.name}")
      nr_cards_on_hand = count_cards_onhand
      if nr_cards_on_hand == 0
        @log.warn "do nothing because no cards are available"
        return
      end
      if command_decl_avail.size > 0
        # there are declaration
        
      end
      case @level_alg 
      when :master
        card = play_like_a_master
      when :predefined
        card = play_with_predifined
      else
        card = play_like_a_dummy
      end
      # notify card played to core game
      @core_game.alg_player_cardplayed(@alg_player, card)
      @log.error "No cards on hand - programming error" unless cards
    end 
  end
  
  ##
  # Play using a predifined playing algorithmus
  def play_with_predifined
    while @action_queue.size > 0
      action = @action_queue.slice!(0)
      #p "Action....."
      #action is something like: {:type=>:cardplayed, :arg=>["Alex", :_6d}
      #p action
      if action[:type] == :cardplayed
        cards = action[:arg][1]
        # use predifined action
        return cards
      end
    end
    # no cards found in action
    @log.warn "No cards found in predifined action, use dummy alg"
    return play_like_a_dummy
  end
  
  def is_card_ok_forplay?(card_lbl)
    suit = @card_played[:suit]
    if suit
      if @cards_on_hand[suit].size > 0
        ix = @cards_on_hand[suit].index(card_lbl)
        #p @cards_on_hand[suit]
        #p card_lbl
        if ix == nil or ix < 0
          @log.debug "Card should be from [#{@cards_on_hand[suit]}], but #{card_lbl} doesn't"
          return false
        end
      else
        return true
      end
    else
      return true
    end
    return true
  end
  
  def play_like_a_master
    card = nil
    if @card_played[:suit] == nil 
      card = master_player_first
    else
      card = master_play_second
    end 
    return card
  end
  
  def master_player_first
    @log.debug "master player first"
    pt_hands = {}
    
    #collect info on suit
    suite_rk = {}
    [:B, :C, :D, :S].each do |suit|
      s_size = @cards_on_hand[suit].size
      rk_max = 0
      asso = false
      franco = @num_carte_gioc_in_suit[suit] - s_size == 0 ? true : false
      @cards_on_hand[suit].each do |card_lbl|
        info = @deck_info[card_lbl]
        rk_max = info[:rank] if rk_max < info[:rank]
        asso = true  if info[:points] == 3
      end
      suite_rk[suit] = {:rk_max => rk_max, :size => s_size, :asso => asso, :franco => franco}
    end
    
    #retrives max suit
    suit_points_hash = {}
    suite_rk.each do |k, suite_info|
      next if suite_info[:size] == 0
      suit_points_hash[k] = 1000
      suit_points_hash[k] += 300 if suite_info[:franco] == true
      suit_points_hash[k] += 10 + suite_info[:size]
      suit_points_hash[k] -= 10 if suite_info[:asso] == true
      suit_points_hash[k] += 3 + suite_info[:rk_max]
      suit_points_hash[k] += 12 if suite_info[:asso] == true and suite_info[:size] > 4 
    end
    max_val_suite = 0
    suit_max = nil
    suit_points_hash.each do |k,v|
      if v > max_val_suite
        suit_max = k
        max_val_suite = v
      end
    end
    if suit_max != nil and suite_rk[suit_max] != nil
      @log.debug "Suit max is #{suit_max} (Len: #{suite_rk[suit_max][:size]}, maxRank: #{suite_rk[suit_max][:rk_max]}, #{@cards_on_hand[suit_max]})"
    else
      return nil
    end
    
    #search inside suit max
    @cards_on_hand[suit_max].each do |card_lbl|
      pt_hands[card_lbl] = 1000
      pt_hands[card_lbl] -= 100 if card_is_asso?(card_lbl)
      if @num_mani < 4
        pt_hands[card_lbl] -= 10 if card_is_pezza?(card_lbl)
      else
        pt_hands[card_lbl] += 10 if card_is_pezza?(card_lbl)
      end
      if @deck_info[card_lbl][:rank] < 11
        pt_hands[card_lbl] += @deck_info[card_lbl][:rank]
      else
        pt_hands[card_lbl] -= (@deck_info[card_lbl][:rank] - 10 + 30)
      end
    end
    
    #play card with max points
    max_val_tb = 0
    card_on_max = nil
    pt_hands.each do |k,v|
      if v > max_val_tb
        card_on_max = k
        max_val_tb = v
      end
    end
    @log.debug "Play first this #{card_on_max}, points #{max_val_tb}"
    return card_on_max
  end
  
  def master_play_second
    @log.debug "master player second"
    suit = @card_played[:suit]
    card_played = @card_played[:seq][0]
    rank_cp = @deck_info[card_played][:rank]
    points_cp = @deck_info[card_played][:points]
    pt_hands = {}
    
    taken_card = []
    leave_card = []
    @cards_on_hand[suit].each do |card_lbl|
      if card_can_take?(card_lbl, card_played)
        taken_card << card_lbl
      else
        leave_card << card_lbl
      end
    end
    @log.debug "Taken card: #{taken_card}, leave: #{leave_card}"
    
    if taken_card.size == 0 and leave_card.size > 0
      # leave on the same suit
      @log.debug "Forced to leave"
      leave_card.each do |card_l|
        pt_hands[card_l] = 1000  
        pt_hands[card_l] -= @deck_info[card_l][:rank]
        pt_hands[card_l] -= 400 if card_is_asso?(card_l)
      end
    elsif taken_card.size > 0 and leave_card.size > 0
      # take or leave?
      if points_cp >= 1 or @num_mani > 4
        #take
        @log.debug "Take or leave? TAKE"
        taken_card.each do |card_t|
          pt_hands[card_t] = 100
          pt_hands[card_t] += 5 if card_is_asso?(card_t)
          pt_hands[card_t] += 25 if card_is_asso?(card_t) and points_cp == 1 
          pt_hands[card_t] += 15 - @deck_info[card_t][:rank]
          pt_hands[card_t] += 5 if card_is_pezza?(card_t)
        end 
      else
        #leave
        @log.debug "Take or leave? LEAVE"
        leave_card.each do |card_l|
          pt_hands[card_l] = 1000  
          pt_hands[card_l] -= @deck_info[card_l][:rank]
          pt_hands[card_l] -= 100 if card_is_asso?(card_l)
        end
      end
    elsif taken_card.size > 0 and leave_card.size == 0
      # take
      @log.debug "Forced to take"
      taken_card.each do |card_t|
        pt_hands[card_t] = 100
        pt_hands[card_t] += 5 if card_is_asso?(card_t) 
        pt_hands[card_t] += 15 - @deck_info[card_t][:rank]
        pt_hands[card_t] += 3 if card_is_pezza?(card_t) 
      end
    elsif taken_card.size == 0 and leave_card.size == 0
      # leave on another suit
      @log.debug "Leave on another suit"
      @cards_on_hand.each do |k_suit, arrcards|
        size_suite = arrcards.size
        arrcards.each do |card_ls|
          pt_hands[card_ls] = 1000
          pt_hands[card_ls] -= 500 if card_is_asso?(card_ls) 
          pt_hands[card_ls] -= 200 if card_is_pezza?(card_ls) 
          pt_hands[card_ls] -= 50 + @deck_info[card_ls][:rank]
          pt_hands[card_ls] += 20 + size_suite
        end
      end
    end
    
    max_val_tb = 0
    card_on_max = nil
    pt_hands.each do |k,v|
      if v > max_val_tb
        card_on_max = k
        max_val_tb = v
      end
    end
    @log.debug "Play as second #{card_on_max} with #{max_val_tb}"
    return card_on_max
  end
  
  def card_is_asso?(card)
    is_asso = @deck_info[card][:symb] == :asso
    #p " **** Card #{card} is asso? #{is_asso}" 
    return is_asso
  end
  
  def card_is_pezza?(card)
    is_pezza = @deck_info[card][:points] == 1
    #p " **** Card #{card} is pezza? #{is_pezza}" 
    return is_pezza 
  end
  
  # true if card_lbl can take card_played
  def card_can_take?(card_lbl, card_played)
    return @deck_info[card_lbl][:rank] > @deck_info[card_played][:rank] ? true : false
  end
  
  ##
  # Provides the card to play in a very dummy way
  def play_like_a_dummy
    # very brutal algorithm , always play the first card
    #card = @cards_on_hand.pop
    #p @cards_on_hand.size
    @log.debug "Cards on hand before play: #{cards_on_hand_to_s}"
    suit = @card_played[:suit]
    card = nil
    if suit
      card = @cards_on_hand[suit][0]  if @cards_on_hand[suit].size > 0
    end
    if card == nil
      @cards_on_hand.each do |k_suit, arrcards|
        return arrcards[0] if arrcards.size > 0
      end
    end
    
    if card
      return card
    end
    raise "Error, play a nil cards. Current cards on hand #{cards_on_hand_to_s}" 
  end
  
  def cards_on_hand_to_s
    res = ""
    @cards_on_hand.each do |k_suit, card_arr|
      res += "#{k_suit}: "
      res += card_arr.join(",")
      res += " - "
    end
    return res
  end
  
  #
  #table_player_info: array of two elements: first is the player, second are cards on table
  def onalg_newmano(player)
    @card_played = {:seq => [], :suit => nil}
  end
  
  def onalg_manoend(player_best, carte_prese_mano, punti_presi)
    #p carte_prese_mano
    carte_prese_mano.each do |card|
      suit = @deck_info[card][:segno]
      @num_carte_gioc_in_suit[suit] -= 1
    end
    @num_mani += 1
  end
  
  def onalg_player_pickcards(player, cards_arr)
    @log.info "ALG[#{player.name}]: card picked #{cards_arr.join(",")}"
    if player.name == @alg_player.name
      cards_arr.each do |card|
        put_cards_onhand(card)
      end 
      if @cards_on_hand.size > @num_cards_on_hand
        raise "ERROR onalg_pesca_carta: #{@cards_on_hand}"
      end
    end
    @num_cards_on_deck -= cards_arr.size
  end
  
  def put_cards_onhand(card)
    info = @deck_info[card]
    @cards_on_hand[info[:segno]] << card
  end
  
  def onalg_player_has_played(player, card)
    #p "onalg_player_has_played, #{player.name}, #{card}"
    @card_played[:seq] << card
    card_played_segno = @deck_info[card][:segno]
    if @card_played[:seq].size == 1
      @card_played[:suit] = card_played_segno
    end
    
    if player.name == @alg_player.name   
      #p "delete #{card}"
      @cards_on_hand[card_played_segno].delete(card)
      #p @cards_on_hand
    end
  end
  
  
  def onalg_new_match(players)
    @log.debug "Player level: #{@level_alg}"
    @opp_names = []
    @team_mates = []
    @players = players
    players.each{|pl| @points_player[pl.name.to_sym] = 0}
    # we have a raw deck_info, build information for rank and points
    val_arr_rank   = [11,12,13,4,5,6,7,8,9,10] # card value order
    val_arr_points = [3,1,1,0,0,0,0,1,1,1] # card points
    @deck_info.each do |k, card|
      # add points and rank 
      curr_index = card[:ix]
      card[:rank] = val_arr_rank[curr_index % 10]
      card[:points] = val_arr_points[curr_index % 10]
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
  
  #best_pl_points:
  #[["Test1", {:assi=>3, :tot=>5, :pezze=>6}], ["Test2", {:assi=>1, :tot=>5, :pezze=>14}]]
  def onalg_giocataend(best_pl_points)
    best_pl_points.each do |player_info|
      player_name = player_info[0]
      player_pt = player_info[1][:tot]
      
      @points_player[player_name.to_sym] += player_pt
    end
    player_info = best_pl_points[0]
    player_loser = best_pl_points[1]
    @log.debug "Giocata end: #{player_info[0]}  batte #{player_loser[0]}, #{player_info[1][:tot]} a #{player_loser[1][:tot]}" 
  end
  
  def onalg_game_end(best_pl_segni)
    @log.debug "Game end #{best_pl_segni}"
  end
  
  #best_pl_segni:
  # [["rudy", 4], ["zorro", 1]]
  def onalg_game_end(best_pl_segni)
    @log.debug "Match end, winner: #{best_pl_segni[0][0]} pt: #{best_pl_segni[0][1]}"
    @log.debug "Match end, loser: #{best_pl_segni[1][0]} pt: #{best_pl_segni[1][1]}"
  end
  
  def get_tot_points(player_key)
    return @points_player[player_key]
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
  
  
end #end AlgCpuTressette

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_tressette'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  #core = CoreGameBriscolone.new
  # rep = ReplayerManager.new(log)
  # match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscola/saved_games/alg_flaw_02.yaml')
  # #p match_info
  # player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  # alg_cpu1 = AlgCpuBriscola.new(player1, core)
  
  # player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
  # alg_cpu2 = AlgCpuBriscola.new(player2, core)
  # alg_cpu2.level_alg = :master
  
  # alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
  # segno_num = 0
  # rep.alg_cpu_contest = true
  # rep.replay_match(core, match_info, alg_coll, segno_num)
end
