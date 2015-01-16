# file: core_game_tombolon.rb
# handle the tombolon game engine
#

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

require 'base/core/game_replayer'
require 'games/spazzino/core_game_spazzino'
require 'alg_cpu_tombolon'

# Class to manage the core card game
class CoreGameTombolon < CoreGameSpazzino

  def initialize
    super
    @combiof_sum_initial = 7
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points => 31,
      :num_of_players => 2,
      :test_with_custom_deck => false,
      :test_custom_deckname => '01.yaml',
      :replay_game => false, # if true we are using information already stored
      :record_game => true,  # if true record the game
      :vale_napola => true, # if true count also the napola
      :combi_sum_lesscard => false # if true (e.g. on scopetta) combi card is restricted to the minimun number of cards
    }
    @test_deck_path = File.dirname(__FILE__) + '/../../test/tombolon/saved_games'
    @num_of_cards_onhandplayer = 4
    @lastcard_ondeck = nil
  end
  
  ##
  # Provides true if the deck is compatible with distribution
  # cards on table have to be conform to the game (avoid three 7 and higher cards)
  def deck_table_isok?(mazzo_gioco)
    tot = {:fan => 0, :set => 0, :cav => 0, :re => 0}
    mazzo_gioco[0..3].each do |lbl_card|
      tot.each do |k, v|
        tot[k] += 1 if @game_deckinfo[lbl_card][:symb] == k
      end
    end
    tot.each_value do |v|
      return false if v >= 3
    end
    return true
  end
  
  ##
  # Override new giocata to count distribution
  def new_giocata
    @num_of_ditribution = 1
    @num_of_cards_onhandplayer = 4
    # need to use a custom deck to check if table is ok
    unless @rnd_mgr.is_predefined_set?
      @log.debug "Create a new random manager to shuffle deck"
      # set a new deck only if it wasn't already set (e.g. game replayer)
      myrnd_mgr =  RandomManager.new
      create_deck
      @mazzo_gioco =  myrnd_mgr.get_deck(@mazzo_gioco)
      while(!deck_table_isok?(@mazzo_gioco))
        # cards on table are not admitted
        @mazzo_gioco =  rnd_mgr.get_deck(@mazzo_gioco)
      end
       #extract the first player
      first_player_ix = player_ix_afterthis(@players.size, @mazziere_ix)
      @rnd_mgr.set_predefdeck_withready_deck(@mazzo_gioco, first_player_ix)
      @rnd_mgr.reset_rnd # set to the random function to avoid predefined_game state the next giocata
    else
      @log.debug "Deck already defined, no shuffle"
    end
    
    super
    @lastcard_ondeck = @mazzo_gioco.first
    @log.debug "new_giocata base was called"
    @first_player = @round_players[0]
    @mazziere_player = @players[@mazziere_ix]
    @log.debug "The first player is #{@first_player.name}, the mazziere is #{@mazziere_player.name}"
    # signal the last card on the deck
    @round_players.each do |player|
      player.algorithm.onalg_gameinfo( {:deckcard => @lastcard_ondeck} )
    end
  end
  
  ##
  # Override pesca_carta because on the fourth distribution we have 6 cards
  def pesca_carta
    @num_of_ditribution += 1
    @log.debug "Pesca: distribution number #{@num_of_ditribution}"
    if @num_of_ditribution >= 4
      # we have now 6 cards
      @num_of_cards_onhandplayer = 6
    end
    super
  end
  
  ##
  # Provides scopa points for tombolon game
  def points_scopa(card)
    pt = 0
    case @game_deckinfo[card][:symb]
      when :fan
        pt = 3
      when :cav
        pt = 4
      when :re
        pt = 5
      else
        pt = @game_deckinfo[card][:rank]
    end
    return pt
  end
  
  ##
  # Check for scopa colore
  def check_for_scopa_colore(card_played, card_taken)
    pt_bager = check_for_bager(card_played, card_taken)
    if pt_bager > 0
      return points_scopa(card_played)
    end
    return 0
  end
  
  ##
  # Check for points when mano is terminated
  def check_forpoints_manoend(player_onturn, card_played, card_taken, last_card)
    val_spazz_events = []
    points_info = @points_curr_segno[player_onturn.name]
    # check for scopa colore (Note: outside of last_card check)
    points_scopa_colore = check_for_scopa_colore(card_played, card_taken)
    if points_scopa_colore > 0
      # scopa colore
      @log.debug "player #{player_onturn.name} make scopa colore"
      val_spazz_events << {:scopa_colore => points_scopa_colore}
      points_info[:scopa_colore] += points_scopa_colore
    end
    unless last_card
      # check for scopa
      if @carte_on_table.size == 0 
        # scopa
        @log.debug "player #{player_onturn.name} make scopa"
        scopa_points = points_scopa(card_played)
        val_spazz_events << {:scopa => scopa_points}
        points_info[:scopa] += scopa_points
      end
      if card_taken.size > 0
        # we have card taken, for this turn there is no card played on table
        @last_card_played_ontable = nil
      else
        @last_card_played_ontable = card_played
      end 
    end
    return val_spazz_events
  end
  
  ##
  # Provides a string with current points
  def points_segno_to_str(points_info)
    str = "tot = #{points_info[:tot]}, scope = #{points_info[:scopa]}, "
    str += "7d = #{points_info[:setbel]}, car = #{points_info[:carte ]}, spa = #{points_info[:spade]}"
    str.concat(", nap = #{points_info[:napola]}")
    str.concat(", fsp = #{points_info[:fantespade]}")
    str.concat(", scope_col = #{points_info[:scopa_colore]}")
    return str
  end
  
  ##
  # Reset points for new giocata
  def reset_points_newgiocata(player)
    @points_curr_segno[player.name] = {
      :scopa => 0,
      :scopa_colore => 0,  
      :carte => 0, 
      :spade => 0, 
      :napola => 0, 
      :setbel => 0,
      :fantespade => 0, 
      :duespade => 0,
      :extra_onori => 0,
      :tombolon => 0,
      :tot => 0}
  end
  
  
  ##
  # Update points of the player when a card is played.
  # player: player to be update as class Player
  def adjourn_points_manoend(player)
    carte_num = 0
    points_info = @points_curr_segno[player.name]
    spade_arr = [] # array of spade using index
    @log.debug "List of cards taken by #{player.name}: #{@carte_prese[player.name].join(",")}"
    @carte_prese[player.name].each do |card|
      carte_num += 1
      if @game_deckinfo[card][:segno] == :S
        ix = @game_deckinfo[card][:rank]
        # carta di spade
        spade_arr << ix
        # check onori
        if @game_deckinfo[card][:symb] == :fan
           points_info[:fantespade] = 1
        end
        if @game_deckinfo[card][:symb] == :due
           points_info[:duespade] = 1
        end
      end
      if @game_deckinfo[card][:symb] == :set and 
         @game_deckinfo[card][:segno] == :D
         # 7 bello onore
         points_info[:setbel] = 1
      end
    end
    
    # cards points (2 points)
    if  carte_num > 20
      points_info[:carte] = 2
    elsif carte_num == 20 and @first_player == player
      points_info[:carte] = 2
    end
    # spade points (1 point)
    if spade_arr.size == 5 and @first_player == player
      points_info[:spade] = 1
    elsif spade_arr.size > 5
      points_info[:spade] = 1
    end
    #napula (>=3 points)
    points_info[:napola] = calc_napula_points(spade_arr)
    #calculate total
    tot = 0
    points_info.each do |k,v|
      next if k == :tot
      tot += v
    end
    points_info[:tot] = tot
    totallpoints =  @points_curr_match[player.name] + points_info[:tot]
    # if the player make enought points, wins
    if totallpoints >= @game_opt[:target_points]
      @log.debug "Terminated the game because the player #{player.name} call out with #{totallpoints}."
      submit_next_event(:giocata_end)
      return
    end
  end
  
  ##
  # Check if the hand make a tombolon
  def check_for_tobolon(hand)
    count = 0
    set_den = false
    hand.each do |card|
      if @game_deckinfo[card][:segno] == :S
        count += 1
      end
      if @game_deckinfo[card][:symb] == :set and 
         @game_deckinfo[card][:segno] == :D
         set_den = true
      end
    end
    if count == 10 and hand.size > 20 and set_den
      # onori e 10 spade: tobolon
      return true
    end
    return false
  end
  
 
  ##
  # Giocata end check additional points
  def adjourn_points_giocataend
    # check for tombolon
    @log.debug "Giocata end check for additional points"
    player1 = @players[0]
    player2 = @players[1]
    hand1 = @carte_prese[player1.name]
    hand2 = @carte_prese[player2.name]
    hand_player_hash = [{:pl => player1, :hand => hand1}, 
                        {:pl => player2, :hand => hand2}]
    hand_player_hash.each do |info|
       hand = info[:hand]
       player = info[:pl]
       @log.debug "List of cards taken by #{player.name}: #{@carte_prese[player.name].join(",")}"
       is_tobolon = check_for_tobolon(hand)
       if is_tobolon
         # end the game, player for this hand win
         @log.info "Giocatore #{player.name} ha fatto tombolon e vince la partita"
         # set target points to force game termination
         @points_curr_segno[player.name][:tombolon] = @game_opt[:target_points]
         @points_curr_segno[player.name][:tot] += @points_curr_segno[player.name][:tombolon]
         #game_is_terminate_on_tombolon(player)
         #return 
       end
       if check_for_double_onori(hand)
         @log.info "Giocatore #{player.name} ha fatto 6 punti di onori, contano doppio, quindi fa 12 punti."
         @points_curr_segno[player.name][:extra_onori] = 6
         @points_curr_segno[player.name][:tot] += @points_curr_segno[player.name][:extra_onori]
       end
    end
   
  end
  
  ##
  # Check if there are double points in case a player make all onori
  def check_for_double_onori(hand)
    count = 0
    set_den = false
    fante_spade = false
    due_spade = false
    hand.each do |card|
      if @game_deckinfo[card][:segno] == :S
        count += 1
      end
      if @game_deckinfo[card][:symb] == :set and 
         @game_deckinfo[card][:segno] == :D
         set_den = true
      end
      if @game_deckinfo[card][:symb] == :fan and 
         @game_deckinfo[card][:segno] == :S
         fante_spade = true
      end
      if @game_deckinfo[card][:symb] == :due and 
         @game_deckinfo[card][:segno] == :S
         due_spade = true
      end
    end
    #p count
    #p  hand.size 
    #p set_den
    #p fante_spade
    if count > 5 and hand.size > 20 and set_den and fante_spade and due_spade
      # tutti gli onori
      return true
    end
    return false
  end
  
 
 
end #end CoreGameTombolon

if $0 == __FILE__
 
end
