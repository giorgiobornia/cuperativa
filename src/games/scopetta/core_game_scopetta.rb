# file: core_game_spazzino.rb
# handle the spazzino game engine
#

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

require 'base/core/game_replayer'
require 'games/spazzino/core_game_spazzino'
require 'alg_cpu_scopetta'

# Class to manage the core card game
class CoreGameScopetta < CoreGameSpazzino

  def initialize
    super
    @combiof_sum_initial = 10
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points => 11,
      :num_of_players => 2,
      :test_with_custom_deck => false,
      :test_custom_deckname => 'scopet01.yaml',
      :replay_game => false, # if true we are using information already stored
      :record_game => true,  # if true record the game
      :vale_napola => true, # if true count also the napola
      :combi_sum_lesscard => true # if true combi card is allowed with less card then all other
    }
    @test_deck_path = File.dirname(__FILE__) + '/../../test/scopetta/saved_games'
    @log = Log4r::Logger.new("coregame_log::CoreGameScopetta") 
  end
  
  ##
  # Check for points when mano is terminated
  def check_forpoints_manoend(player_onturn, card_played, card_taken, last_card)
    val_spazz_events = []
    points_info = @points_curr_segno[player_onturn.name]
    unless last_card
      if @carte_on_table.size == 0 
        # scopa
        @log.debug "player #{player_onturn.name} make scopa"
        val_spazz_events << {:scopa => 1}
        points_info[:scopa] += 1
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
    str = "tot = #{points_info[:tot]}, scope = #{points_info[:scopa]}, 7d = #{points_info[:setbel]}, car = #{points_info[:carte ]}, den = #{points_info[:denari]}, prim = #{points_info[:primiera]}"
    if @game_opt[:vale_napola]
      str.concat(", nap = #{points_info[:napola]}")
    end
    return str
  end
  
  ##
  # Reset points for new giocata
  def reset_points_newgiocata(player)
    @points_curr_segno[player.name] = {
      :scopa => 0,  
      :carte => 0, 
      :denari => 0, 
      :napola => 0, 
      :setbel => 0,
      :primiera => 0, 
      :tot => 0}
  end
  
  ##
  # Update points at the end of giocata
  def adjourn_points_giocataend
    # at the end of the game remain to calculate the primiera
    player1 = @players[0]
    player2 = @players[1]
    hand1 = @carte_prese[player1.name]
    hand2 = @carte_prese[player2.name]
    prim_res_arr = calculate_primiera(hand1, hand2)
    @log.debug("Primiera of #{player1.name}:#{prim_res_arr[0]}, #{player2.name}: #{prim_res_arr[1]}")
    # update points on all players
    ix = 0
    [player1, player2].each do |pl|
      points_info = @points_curr_segno[pl.name]
      points_info[:primiera] = prim_res_arr[ix]
      #calculate total
      tot = 0
      points_info.each do |k,v|
        next if k == :tot
        tot += v
      end
      points_info[:tot] = tot
      ix += 1
    end
  end
  
  ##
  # Calculate primiera. Returns an array with primiera points for each player
  # First element is the result for player 1, second for player 2
  # hand1: cards taken from player 1
  # hand2: cards taken from player 2
  def calculate_primiera(hand1, hand2)
    res = [0,0]
    #p hand1
    #p hand2
    # first get the max card on each suit
    max_pt = []
    [hand1, hand2].each do |curr_hand|
      # reset max
      max_pt << {:D => 0, :B => 0, :C => 0, :S => 0 }
      curr_hand.each do |lbl|
        points = @game_deckinfo[lbl][:points]
        suit = @game_deckinfo[lbl][:segno]
        if points > max_pt.last[suit]
          # max on suit
          max_pt.last[suit] = points
        end
      end
      #p max_pt.last
    end
    # using inject, 0 is the first value of the accumulator sum, tha assume the
    # value of the block provided. x assume each value of the max_pt.first
    # x becomes a pair like max_pt.first.each{|k,v|}. For example x = [:S, 21]
    arr_sum_points = []
    max_pt.each do |maxitem|
      arr_sum_points <<  maxitem.inject(0) do |sum, x|
        if x[1] > 0 and sum >= 0  
          sum  + x[1]
        else
          # this is a particular case, we don't have points on a particular suit
          # in this case there is no primiera. Then stay on -1.
          sum = -1
        end
      end
    end
    #p arr_sum_points
    if arr_sum_points[0] > arr_sum_points[1]
      #primiera on the first hand
      res[0] = 1
      res[1] = 0
    elsif arr_sum_points[0] == arr_sum_points[1]
      # same points, primiera is not assigned
      res[0] = 0
      res[1] = 0
    else
      #primiera on the second hand
      res[0] = 0
      res[1] = 1
    end 
    #p res
    return res
  end
  
  ##
  # Update points of the player when a card is played.
  # player: player to be update as class Player
  def adjourn_points_manoend(player)
    carte_num = 0
    points_info = @points_curr_segno[player.name]
    denari_arr = [] # array of denari using index
    @log.debug "Riepilogo carte prese da #{player.name}: #{@carte_prese[player.name].join(",")}"
    @carte_prese[player.name].each do |card|
      carte_num += 1
      if @game_deckinfo[card][:segno] == :D
        ix = @game_deckinfo[card][:rank]
        # carta di denari
        denari_arr << ix
      end
      if @game_deckinfo[card][:symb] == :set and 
         @game_deckinfo[card][:segno] == :D
         # 7 bello onore
         points_info[:setbel] = 1
      end
    end
    points_info = @points_curr_segno[player.name]
    # cards points
    if  carte_num > 20
      points_info[:carte] = 1
    elsif carte_num == 20
      points_info[:carte] = 0
    end
    # spade points
    if denari_arr.size == 5
      points_info[:denari] = 0
    elsif denari_arr.size > 5
      points_info[:denari] = 1
    end
    #napula
    if @game_opt[:vale_napola]
      points_info[:napola] = calc_napula_points(denari_arr)
    else
      points_info[:napola] = 0
    end
    #calculate total
    tot = 0
    points_info.each do |k,v|
      next if k == :tot
      tot += v
    end
    points_info[:tot] = tot
  end
 
  ##
end

if $0 == __FILE__
 
end
