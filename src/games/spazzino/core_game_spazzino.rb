# file: core_game_spazzino.rb
# handle the spazzino game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../../base/core/game_replayer'
require 'alg_cpu_spazzino'

# Class to manage the core card game
class CoreGameSpazzino < CoreGameBase
  attr_accessor :game_opt, :rnd_mgr, :points_curr_match, :num_of_cards_onhandplayer

  def initialize
    super
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points => 21, #21,
      :num_of_players => 2,
      :test_with_custom_deck => false,
      :test_custom_deckname => 'spazz01.yaml',
      :replay_game => false, # if true we are using information already stored
      :record_game => true,  # if true record the game
      :combi_sum_lesscard => false # if true combi card is allowed with less card then all other 
    }
    @test_deck_path = File.dirname(__FILE__) + '/../../test/spazzino/saved_games'
    
    # players (instance of class PlayerOnGame) order that have to play
    @round_players = []
    #p @mazzo_gioco
    #p @@deck_info
    
    # array di simboli delle carte(:bA :c4 ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    # array of players (instance of class PlayerOnGame
    @players = []
    # cards on table. used like a stack  
    @carte_on_table = []
    # cards holds (to be played) for each player. The key is a player name, values are an array of card labels
    @carte_in_mano = {}
    # cards taken for each player. The key is a player name, values are an array of card labels
    @carte_prese = {}
    # points in current segno. For each player are stored info like: 
    # {:spazzino => 0, :picula => 0, :bager => 0, :carte => 0, :spade => 0, :napola => 0, :onori => 0, :tot => 0}
    @points_curr_segno = {}
    # points accumulated in the current match for each player. The key is a player name, 
    # value is current number of segni wons by the player.
    @points_curr_match = {}
    # segno state
    @segno_state = :undefined 
    # match state
    @match_state = :undefined
    # random manager
    @rnd_mgr = RandomManager.new
    # game recorder
    @game_core_recorder = GameCoreRecorder.new
    # number of card on each player
    @num_of_cards_onhandplayer = 3
    # last card played on the table
    @last_card_played_ontable = nil
    # using own game card info for rank and points
    @game_deckinfo = {}
    # last player that take all cards
    @lasttaken_player = nil
    # last player taken cards array
    @lasttaken_cards = nil
    # mazziere player index
    @mazziere_ix = 0
    # combi of sum to inspect
    @combiof_sum_initial = 7
    # number of cards on table
    @num_of_cards_ontable = 4
    # number of new_mano
    @mano_count = 0
    # info for card played correct
    @card_played_correct = {}
    @log = Log4r::Logger.new("coregame_log::CoreGameSpazzino") 
    end
  
  ##
  # Set options from external, for example from user using @app_settings
  # options: the cuperativa.app_settings hash
  def set_specific_options(options)
    if options["games"][:spazzino_game]
      if options["games"][:spazzino_game][:target_points]
        @game_opt[:target_points] = options["games"][:spazzino_game][:target_points]
      end
    end
  end
  
  ##
  # Save current game into a file
  def save_curr_game(fname)
    @log.info("Game saved on #{fname}")
    @game_core_recorder.save_match_to_file(fname)
  end
  
  ##
  # Build deck before shuffle
  def create_deck
    @log.debug("Create a deck with rank and points")
    # array di simboli delle carte(:_Ac :_4c ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    @game_deckinfo = {}
    # set card values and points
    val_arr_rank   = [1 , 2, 3, 4, 5, 6, 7, 8, 9,10] # card value order
    val_arr_points = [16,12,13,14,15,18,21,10,10,10] # card points
    # modifica il mazzo aggiungendo punti e valore delle carte per il gioco specifico della briscola
    @@deck_info.each do |k, card|  
      curr_index = card[:ix]
      #card[:rank] = val_arr_rank[curr_index % 10]
      #card[:points] = val_arr_points[curr_index % 10]
      @game_deckinfo[k] = card.dup
      @game_deckinfo[k][:rank] = val_arr_rank[curr_index % 10]
      @game_deckinfo[k][:points] = val_arr_points[curr_index % 10]
      # mazzo viene gestito solo coi simboli
      @mazzo_gioco << k
    end
    #p "RANK random on create_deck"
    #p @game_deckinfo[:_Ab][:rank]
    #p @game_deckinfo
  end
 
  
  ###
  # Log the current deck
  def dump_curr_deck
    #str = YAML.dump(@mazzo_gioco)
    str = @mazzo_gioco.join(",")
    @log.info("Current deck:\n#{str}")
  end
  
  ##
  # Test a game with a custom deck file
  def test_with_custom_deck
    @log.debug("Test a game with a custom deck")
    match_info = YAML::load_file(@test_deck_path + '/' + @game_opt[:test_custom_deckname])
    segni = match_info[:giocate] # catch all giocate, it is an array of hash
    curr_segno = segni[0]
    #p curr_segno
    @rnd_mgr.set_predefdeck_withready_deck(curr_segno[:deck], curr_segno[:first_plx])
  end
  
  ##
  # Col termine di giocata ci si riferisce al mescolamento delle carte e alla
  # sua distribuzione
  def new_giocata
    @log.info "new_giocata"
    @segno_state = :started
     # reset some data structure
    @mano_count = 0
    @carte_prese = {}
    @carte_in_mano = {}
    @carte_on_table = []
    @last_card_played_ontable = nil
    # reset also events queue
    clear_gevent
    
    #extract the first player
    first_player_ix = player_ix_afterthis(@players.size, @mazziere_ix)
    # calculate the player order (first is the player that have to play)
    @round_players = calc_round_players( @players, first_player_ix)
    
    create_deck
    #shuffle deck
    @mazzo_gioco = @rnd_mgr.get_deck(@mazzo_gioco) # @mazzo_gioco.sort_by{ rand } if @game_opt[:shuffle_deck]
    
    @game_core_recorder.store_new_giocata(@mazzo_gioco, first_player_ix) if @game_opt[:record_game]
    dump_curr_deck
    
    # distribuite card to each player
    carte_player = []
    # pop 4 cards for the table
    @num_of_cards_ontable.times{ @carte_on_table << @mazzo_gioco.pop}
    # inform about the mazziere
    @round_players.each{|e| e.algorithm.onalg_new_mazziere(@players[@mazziere_ix])}
    
    # distribute cards to each player
    @round_players.each do |player|
      @num_of_cards_onhandplayer.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player, @carte_on_table].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      reset_points_newgiocata(player)
    end
    #p @carte_prese
    
    @lasttaken_player = nil
    @lasttaken_cards = nil
    submit_next_event(:new_mano)
  end
  
  ##
  # Reset points for new giocata
  def reset_points_newgiocata(player)
    @points_curr_segno[player.name] = {:spazzino => 0, :picula => 0, :bager => 0, 
           :carte => 0, :spade => 0, :napola => 0, :duespade => 0,
           :fantespade => 0,  :setbel => 0,
           :tot => 0}
  end
  
  ##
  # Col termine di mano ci si riferisce a tutte le carte giocate dai giocatori
  # prima che ci sia una presa
  def new_mano
    @log.debug "new_mano"
    @mano_count += 1
    # reverse it for use pop
    @round_players.reverse!
    player_onturn = @round_players.last
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
    
    #inform about start new mano
    # usa un array, al primo posto il giocatore seguito dalle carte che
    #       ci sono sul tavolo
    @players.each{|pl| pl.algorithm.onalg_newmano([player_onturn, @carte_on_table]) }
    
    # notify all players about player that have to play
    @players.each do |pl|
      # don't notify commands declaration for player that are only informed
      pl.algorithm.onalg_have_to_play(player_onturn, [])
    end
  end
  
  ##
  # Check if the player has maked a bager
  # card_played: label card played
  # card_taken: array of label cards taken
  def check_for_bager(card_played, card_taken)
    #p card_taken
    points = 0
    if card_taken.size > 1
      segno = card_played.to_s()[2]
      card_taken.each do |item|
        segno_item = item.to_s()[2]
        if segno_item !=  segno
          return 0
        end
      end
      # now are cards have the same segno, this is a bager
      points = card_taken.size + 1
    end
    return points
  end 
  
  ##
  # Check if the player has maked picula.
  # card_played: label card played
  # last_card: last card played from opponent
  # card_taken: array of card taken
  def check_for_picula(card_played, last_card, card_taken)
    points = 0
    if last_card and card_played and card_taken.size == 1
      cs = card_played.to_s
      ls = last_card.to_s
      cardtks = card_taken[0].to_s
      if cs[1] == ls[1] and cs[1] == cardtks[1]  
        points = 1
      end
    end
    return points
  end
   
  ##
  # Check if giocata terminated because a player reach the target points
  def check_if_giocata_is_terminated
    tot_num_cards = 0
    @carte_in_mano.each do |k,card_arr|
      # cards in hand of player 
      tot_num_cards += card_arr.size
    end
    tot_num_cards += @mazzo_gioco.size
    
    if tot_num_cards <= 0
      # giocata is terminated
      return true
    end
    return false
  end
  
  ##
  # Player take cards from deck
  def pesca_carta
    @log.debug "pesca_carta"
    carte_player = []
    if @mazzo_gioco.size > 5
      # there are still cards to distibute   
      @round_players.each do |player|
        # distribute 3 cards
        @num_of_cards_onhandplayer.times do
          carte_player << @mazzo_gioco.pop
        end
        #p carte_player
        player.algorithm.onalg_pesca_carta(carte_player)
        # store cards to each player for check
        carte_player.each{|c| @carte_in_mano[player.name] << c}
        carte_player = [] # reset array for the next player
      end
    else
      @log.error "Carte non sufficienti nel mazzo da distribuire"
    end
    @log.info "Mazzo rimanenti: #{@mazzo_gioco.size}"
    submit_next_event(:new_mano)
  end
  
  ##
  # Update points of the player.
  # player: player to be update as class Player
  def adjourn_points_manoend(player)
    carte_num = 0
    points_info = @points_curr_segno[player.name]
    #onori = 0
    spade_arr = [] # array of spade using index
    @log.debug "Riepilogo carte prese da #{player.name}: #{@carte_prese[player.name].join(",")}"
    @carte_prese[player.name].each do |card|
      carte_num += 1
      if @game_deckinfo[card][:segno] == :S
        ix = @game_deckinfo[card][:rank]
        # carta di spade
        spade_arr << ix
        # check onori
        if @game_deckinfo[card][:symb] == :due 
          points_info[:duespade] = 1
        elsif   @game_deckinfo[card][:symb] == :fan
          #onori += 1
          points_info[:fantespade] = 1
        end
      end
      if @game_deckinfo[card][:symb] == :set and 
         @game_deckinfo[card][:segno] == :D
         # 7 bello onore
         #onori += 1
         points_info[:setbel] = 1
      end
    end
    
    # cards points
    if  carte_num > 20
      points_info[:carte] = 2
    elsif carte_num == 20
      points_info[:carte] = 1
    end
    # spade points
    if spade_arr.size == 5
      points_info[:spade] = 1
    elsif spade_arr.size > 5
      points_info[:spade] = 2
    end
    #onori
    #points_info[:onori] = onori
    #napula
    points_info[:napola] = calc_napula_points(spade_arr)
    #calculate total
    tot = 0
    points_info.each do |k,v|
      next if k == :tot
      tot += v
    end
    points_info[:tot] = tot
  end
  
  ##
  # Update points at the end of giocata
  def adjourn_points_giocataend
    # not needed for spazzino, points are updated during playing
    # on scopa this function is needed to calculate the primiera
  end
  
  ##
  # provides the napula points.
  # spade_arr: array of rank index on spade. (e.g [9,1,2,3,5,8] for a simple napula)
  def calc_napula_points(spade_arr)
    arr_ix = spade_arr.sort
    pt = 0
    mask = [0,1,1,1,0,0,0,0,0,0,0]
    arr_ix.each{|e| pt += mask[e]}
    if pt == 3
      # napula found
      (4..10).each do |allungo|
        # now each card taken in order make one points
        if arr_ix.index(allungo)
          pt += 1
        else
          #points for napula terminated
          break
        end
      end
    else
      # napola not found
      pt = 0
    end
    return pt
  end
  
  ##
  # All cards on the table are taken by the last player that taken a card
  # This method is called when the player that take is not last player on turn.
  # QUESTION: is this method obsolete? Resp: No is called from mano end
  def tablecards_alltaken
    @log.debug "Player #{@lasttaken_player.name} take the rest on table: #{@lasttaken_cards.join(",")}"
    @players.each{|pl| pl.algorithm.onalg_player_has_taken(@lasttaken_player, @lasttaken_cards ) }
    # points update
    @lasttaken_cards.each{|e| @carte_prese[@lasttaken_player.name] << e}
    adjourn_points_manoend(@lasttaken_player)
    str_points = points_segno_to_str(@points_curr_segno[@lasttaken_player.name])
    @log.info "Punteggio(#{@lasttaken_player.name}): #{str_points}"
    @lasttaken_cards = nil
    submit_next_event(:giocata_end)
  end
  
  ##
  # mano end
  def mano_end
    @log.debug "mano_end"
    player_onturn = @round_players.last
    
    card_played = nil
    card_taken = []
    #p @carte_gioc_mano_corr
    @carte_gioc_mano_corr.each do |lbl_card|
      if card_played == nil
        card_played = lbl_card
        @carte_prese[player_onturn.name] << lbl_card if @carte_gioc_mano_corr.size > 1
      else
        card_taken << lbl_card
        @carte_prese[player_onturn.name] << lbl_card
      end 
    end 
    # last card info
    last_card = check_if_giocata_is_terminated
    if last_card
      # last card played, check if the rest is taken by another player
      if @lasttaken_cards
        # another player take all cards
        #@log.debug "Player #{@lasttaken_player.name} take the rest on table: #{@lasttaken_cards.join(",")}"
      else
        # current player has played the last card take all cards
        @carte_on_table.each do |lbl_card_table|
          @carte_prese[player_onturn.name] << lbl_card_table
          card_taken << lbl_card_table
        end
        # there is a case if the player doesn't take anything =>  @carte_gioc_mano_corr.size == 1
        # in this case we have to add the played card to the taken deck
        if @carte_gioc_mano_corr.size == 1 # on bigger this case is already included
          @carte_prese[player_onturn.name] << card_played
        end
      end
    end
    
    # check for picula, spazzino and bager
    val_spazz_events = check_forpoints_manoend(player_onturn, card_played, card_taken, last_card)
    
    # notify events that could happens at this point: picula or spazzino 
    @players.each{|pl| pl.algorithm.onalg_manoend(player_onturn, nil, val_spazz_events) }
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
    
    points_info = @points_curr_segno[player_onturn.name]
    if card_taken.size > 0
      # update points for the current player
      adjourn_points_manoend(player_onturn)
      str_points = points_segno_to_str(points_info)
      @log.info "Punteggio(#{player_onturn.name}): #{str_points}"
    end 
    
    # build circle of players that have now to play
    # first remove the player that has played now
    @round_players.pop
    next_player = @round_players.last       
    first_player_ix = @players.index(next_player)
    # rebuild round_players, for two players it doesn't matter, 
    # for more we need to check if @round_players is empty
    @round_players = calc_round_players( @players, first_player_ix)
    
    if last_card
      if @lasttaken_cards
        # last card is played but the current player don't take the table
        # we need to notify card taken for the oppponent
        @log.debug("Last card on mano end: need to notify card on table are taken")
        submit_next_event(:tablecards_alltaken)
        return
      else
        # it was the last card played, submit giocata end
        # segno is terminated because no more card are to be played
        @log.debug("Giocata end beacuse no more cards are to be played")
        # check card taken
        num_pl1 = @carte_prese[@round_players[0].name].size
        num_pl2 = @carte_prese[@round_players[1].name].size
        sum_pl_taken = num_pl1 + num_pl2
        if sum_pl_taken != 40
          @log.error "Error: sum of take cards is not 40, but #{sum_pl_taken}"
          @round_players.each_index do |ix|
            @log.debug "  ER: cards taken by #{@round_players[ix].name} are (#{@carte_prese[@round_players[ix].name].size}): #{@carte_prese[@round_players[ix].name].join(",")}"
          end
        end
      end
      submit_next_event(:giocata_end)
      return
    end
    # giocata continue
    num_cards_on_playershand = 0
    @carte_in_mano.each do |k,v|
      num_cards_on_playershand += v.size
    end
      
    if @mazzo_gioco.size > 0 and num_cards_on_playershand == 0
      # nobody has cards on the hand 
      # now is time to take cards from deck
      submit_next_event(:pesca_carta)
      # cards redistribution, picula is invalid
      @last_card_played_ontable = nil
    else
      # continue without pick the card from deck
      submit_next_event(:new_mano)
    end
  end
  
  ##
  # Check for points when mano is terminated
  def check_forpoints_manoend(player_onturn, card_played, card_taken, last_card)
    val_spazz_events = []
    points_info = @points_curr_segno[player_onturn.name]
    unless last_card
      if @carte_on_table.size == 0 
        # spazzino
        @log.debug "player #{player_onturn.name} make spazzino"
        val_spazz_events << {:spazzino => 1}
        points_info[:spazzino] += 1
      end
      points_picula = check_for_picula(card_played, @last_card_played_ontable, card_taken)
      if points_picula > 0
        # picula
        @log.debug "player #{player_onturn.name} make picula"
        val_spazz_events << {:picula => 1}
        points_info[:picula] += 1
      end
      if card_taken.size > 0
        # we have card taken, for this turn there is no card played on table
        @last_card_played_ontable = nil
      else
        @last_card_played_ontable = card_played
      end 
      points_bager = check_for_bager(card_played, card_taken)
      if points_bager > 0
        # bager
        @log.debug "player #{player_onturn.name} make bager"
        val_spazz_events << {:bager => points_bager}
        points_info[:bager] += points_bager
      end
    end
    return val_spazz_events
  end
  
  ##
  # Provides a string with current points
  def points_segno_to_str(points_info)
    str = "tot = #{points_info[:tot]}, spaz = #{points_info[:spazzino]}, nap = #{points_info[:napola]}, pic = #{points_info[:picula]}, bag = #{points_info[:bager]}, car = #{points_info[:carte ]}, spa = #{points_info[:spade]}"
    return str
  end
  
  
  ##
  # Segno finito
  def giocata_end
    @log.info "giocata_end"
    @segno_state = :end
    
    adjourn_points_giocataend
    
    @round_players.each do |player|
      points_info = @points_curr_segno[player.name]
      num_cards = @carte_prese[player.name].size
      str_points = points_segno_to_str(points_info)
      @log.info "Points(#{player.name}): #{str_points}, num cards: #{num_cards}"
    end
    
    # notifica tutti i giocatori chi ha vinto il segno
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 45], ["zorro", 33], ["alla", 23], ["casa", 10]]
    #p @points_curr_segno.to_a
    best_pl_points =  @points_curr_segno.to_a.sort{|x,y| y[1][:tot] <=> x[1][:tot]}
    #adjust match points
    @points_curr_segno.each do |k,v|
      @points_curr_match[k] += v[:tot] 
      @log.debug(" Total match points(#{k}): #{@points_curr_match[k]}")
    end
    if @game_opt[:record_game]
      @game_core_recorder.store_end_giocata(best_pl_points)
    end
    # prepare the next mazziere
    @mazziere_ix = player_ix_afterthis(@players.size, @mazziere_ix)
    # send points state
    @players.each{|pl| pl.algorithm.onalg_giocataend(best_pl_points) }
  end
  
  ##
  # Match finito
  def match_end
    @match_state = :match_terminated
    # we don't need events anymore
    clear_gevent
    # notifica tutti i giocatori chi ha vinto la partita
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 4], ["zorro", 1]]
    best_pl_segni =  points_curr_match_sorted()
    if @game_opt[:record_game]
      @game_core_recorder.store_end_match(best_pl_segni)
    end
    @players.each{|pl| pl.algorithm.onalg_game_end(best_pl_segni) }
  end
  
  def points_curr_match_sorted
    return @points_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
  end
  
  ##
  # return true is the current match as a minimun information for score
  def is_matchsuitable_forscore?
    tot_points = 0
    @points_curr_match.each{|v| tot_points += v[1] }
    if tot_points > 0 or @mano_count > 4
      return true
    end
    return false
  end
  
  ##
  # Return player  that catch the current mano and also the card played
  # carte_giocate: an array of hash with label and player (e.g [:_A =>player1])
  def vincitore_mano(carte_giocate)
  
  end
  
  ##
  # Return true if the player is the first on this mano
  def first_to_play?(player)
    # a player is first when @round_players is not yet consumed
    # and on the last position of @round_players there is the player
    if @round_players.size ==  @players.size
      if @round_players.last == player
        return true
      end
    end
    return false
  end
  
  ##
  # Provides true if the game in progress is ongoing
  def is_game_ongoing?
    return @match_state == :match_started
  end
  
  ## Algorithm and GUI notification calls ####################
  
  ##
  # Player resign a game
  # player: instance of PlayerOnGame
  # reason: :abandon or :disconnection
  def alg_player_resign(player, reason)
    if @segno_state == :end
      return :not_allowed
    end
    @log.info "alg_player_resign: giocatore perde la partita"
    if @game_opt[:record_game]
      @game_core_recorder.store_player_action(player.name, :resign, player.name, reason)
    end
    @segno_state = :end
    submit_next_event(:match_end)
    # set negative value for segni in order to make player marked as looser
    @points_curr_match[player.name] = -1
    #process_next_gevent
  end
  
  ##
  # Notification player change his card with the card on table that define briscola
  # Only the 7 of briscola is allowed to make this change
  def alg_player_change_briscola(player, card_briscola, card_on_hand )
    @log.error("alg_player_change_briscola not supported ")
    return :not_allowed
  end
  
  ##
  # Notification player has make a declaration
  # name_decl: name of mariazza declaration defined in @mariazze_def (e.g. :mar_den)
  def alg_player_declare(player, name_decl)
    @log.error("alg_player_declare not supported")
    return :not_allowed
  end
  
  ##
  # Notification player has played a card
  # arr_lbl_card: array of card played label (e.g. [:_Ab, ;_As])
  #    first card is the card played, rest are card taken
  def alg_player_cardplayed_arr(player, arr_lbl_card)
    @log.debug "core: alg_player_cardplayed_arr: #{arr_lbl_card.join(',')}"
    #p arr_lbl_card
    if @segno_state == :end
      @log.warn "01Card #{arr_lbl_card.join(",")} not allowed  from player #{player.name} because giocata end"
      #player.algorithm.onalg_player_cardsnot_allowed(player, arr_lbl_card)
      @card_played_erronous = {:player => player, :arr_lbl_card => arr_lbl_card}
      submit_next_event(:card_played_is_erronous)
      return :not_allowed
    end
    arr_lbl_card.delete(nil)
    res = :not_allowed
    if  arr_lbl_card.size < 1
      @log.warn "02Card #{arr_lbl_card.join(",")} not allowed to be played from player #{player.name}"
      #player.algorithm.onalg_player_cardsnot_allowed(player, arr_lbl_card)
      @card_played_erronous = {:player => player, :arr_lbl_card => arr_lbl_card}
      submit_next_event(:card_played_is_erronous)
      return :not_allowed
    end
    #p arr_lbl_card
    lbl_card = arr_lbl_card[0]
    card_taken = []
    if arr_lbl_card.size > 1
      card_taken = arr_lbl_card[1..-1]
    end
    
    if @round_players.last == player
      # check and update list of cards on table
      if check_takentable_cards(lbl_card, card_taken)
        # the player on turn has played, ok
        cards = @carte_in_mano[player.name]
        pos = cards.index(lbl_card) if cards
        if pos
          # card is allowed to be played
          res = :allowed
          if @game_opt[:record_game]
            @game_core_recorder.store_player_action(player.name, :cardplayedarr, player.name, arr_lbl_card)
          end
          # remove it from list of availablecards
          @carte_in_mano[player.name].delete_at(pos)
          # update table
          card_taken.each do |c_taked|
            @carte_on_table.delete(c_taked)
          end
          last_card = check_if_giocata_is_terminated
          if card_taken.size > 0
            @lasttaken_player = player
          end
          if last_card  
            @log.info "Last card played, #{@lasttaken_player.name } take all the rest"
            if @lasttaken_player == player
              # last card played, it take all cards on the table
              @carte_on_table.each do |lbl_card_table|
                card_taken << lbl_card_table
              end
            else
              # the opponent take cards that are still on table
              @log.info "Cards on table collected by opponent of the player playing"
              @lasttaken_cards = []
              @carte_on_table.each do |lbl_card_table|
                @lasttaken_cards << lbl_card_table
              end
              # also the card played from current player
              @lasttaken_cards << lbl_card
            end
          end #last_card
          if card_taken.size == 0
            # card played don't take any card on the table, then set it on table
            @carte_on_table << lbl_card
          end
          str_card_taken = card_taken.join(",")
          str_card_played = "Card #{lbl_card} played from  #{player.name}. "
          str_card_played.concat("Taken: #{str_card_taken}") if card_taken.size > 0
          @log.info str_card_played
          @log.info "Table now: #{@carte_on_table.join(",")}"
          #store it in array of card played during the current mano
          @carte_gioc_mano_corr = arr_lbl_card
          
          @card_played_correct = {:player => player, :lbl_card => lbl_card, :card_taken => card_taken  }
          submit_next_event(:card_played_is_correct)
          ## notify all players that a player has played a card
          #@players.each{|pl| pl.algorithm.onalg_player_has_played(player, [lbl_card, card_taken]) }
          #submit_next_event(:mano_end)
        end #end if pos
      else
        @log.debug "card don't take what is given as input:  #{arr_lbl_card}"
      end #end if check_takentable_cards
    end
    if res == :not_allowed
      #crash
      #p @carte_in_mano
      @log.warn "03Card #{arr_lbl_card.join(",")} not allowed to be played from player #{player.name}"
      #player.algorithm.onalg_player_cardsnot_allowed(player, arr_lbl_card)
      @card_played_erronous = {:player => player, :arr_lbl_card => arr_lbl_card}
      submit_next_event(:card_played_is_erronous)
    end 
    
    #process_next_gevent
    
    return res
  end
  
  def card_played_is_correct
    # notify all players that a player has played a card
    player = @card_played_correct[:player]
    lbl_card = @card_played_correct[:lbl_card]
    card_taken = @card_played_correct[:card_taken]
    @players.each{|pl| pl.algorithm.onalg_player_has_played(player, [lbl_card, card_taken]) }
    submit_next_event(:mano_end)
  end
  
  def card_played_is_erronous
    player = @card_played_erronous[:player]
    arr_lbl_card = @card_played_erronous[:arr_lbl_card]
    player.algorithm.onalg_player_cardsnot_allowed(player, arr_lbl_card)
  end
  
  ##
  # Main app inform about starting a new match
  # players: array of PlayerOnGame
  def gui_new_match(players)
    @log.info "gui_new_match"
    unless @game_opt[:num_of_players] == players.size
      @log.error "Number of players don't match with option"
      return
    end
    @match_state = :match_started
    
    if @game_opt[:test_with_custom_deck]
      # we are using a custom deck from a file
      test_with_custom_deck
    else 
      unless @game_opt[:replay_game]
        # we are not replay a game, reset random manager
        @rnd_mgr.reset_rnd 
      end
    end
    if @game_opt[:record_game]
      @game_core_recorder.store_new_match(players, @game_opt, "Spazzino")
    end
    
    # here we have to extract the "mazziere", then in new_giocata
    # we have to calculate the next one
    first_ix = @rnd_mgr.get_first_player(players.size)
    @log.debug "First player ist #{first_ix}"
    @mazziere_ix = player_ix_beforethis(players.size, first_ix)
    @log.debug "Mazziere ist #{@mazziere_ix}"
    
    @players = players
    # notify all players about new match
    @players.each do |player| 
      player.algorithm.onalg_new_match( @players )
      if @rnd_mgr.is_predefined_set?
        # on replayed game we need to accumulate points between matches
        @points_curr_match[player.name] = 0 unless @points_curr_match[player.name]
      else
        @points_curr_match[player.name] = 0
      end 
    end
    
    submit_next_event(:new_giocata)
    #process_next_gevent
  end
  
  ##
  # Trigger a new segno by gui. This action is done by gui and it a 
  # reaction of giocata_end. This is done using the gui because
  # we expect an user interaction after giocata_end and before
  # starting a new segno.
  def gui_new_segno
    unless @segno_state == :end
      # reject request to start a new segno if it wasn't terminated
      @log.info "gui_new_segno request rejected"
      return
    end
    # when a new segno start, the game event queue should be empty
    clear_gevent
    str_status_segni = ""
    @points_curr_match.each do |k,v|
      str_status_segni += "#{k} = #{v} "
    end
    @log.info "gui_new_segno #{str_status_segni}"
    max_points = @points_curr_match.values.max
    # check if the max was done only by a single player
    arr_points = @points_curr_match.values.select{|x| x == max_points}
       
    if max_points < @game_opt[:target_points]
      # trigger a new giocata
      submit_next_event(:new_giocata)
      #process_next_gevent
    elsif arr_points.size > 1
      @log.debug "Game over the target points of #{@game_opt[:target_points]} but deuced, continue."
      submit_next_event(:new_giocata)
      #process_next_gevent
    else
      #  wait for a new match
      @log.info "gui_new_segno: aspetta inizio nuovo match"
      submit_next_event(:match_end)
      #process_next_gevent
      return :match_end
    end
    return :new_giocata
  end
  
  ##
  # Check if the played card lbl_card and taken cards
  # card_taken is compatible with cards on table
  # card_taken: array of label cards [:_Ab]
  # lbl_card: card played
  def check_takentable_cards(lbl_card, card_taken)
    taken_sum = 0
    #p card_taken
    if card_taken.size == 0
      # card played for table
      list = which_cards_pick(lbl_card, @carte_on_table)
      if list.size == 0
        # card don't take, played on table ok
        #@log.debug "Card #{lbl_card} is compatible with table"
        return true
      else
        # card take something on the table
        @log.debug "Card #{lbl_card} take something on the table #{list}"
      end
    end
    card_taken.each do |card|
      if @carte_on_table.index(card)
        taken_sum += @game_deckinfo[card][:rank]
      else
        # card not on table
        return false
      end
    end
    r1_rank = @game_deckinfo[lbl_card][:rank]
    if r1_rank != taken_sum
      return false
    end
    if r1_rank > @combiof_sum_initial or r1_rank < 2
      # this is a case for unique card taken
      if card_taken.size > 1
        return false
      end
    end
    return true
      
  end
  
  ##
  # Set cards on table. Used for test purpose
  def set_card_on_table(card_on_table)
    @carte_on_table = card_on_table.dup
  end
  
  ##
  # Provides the list of card that are picked from played card lbl_card
  def which_cards_pick(lbl_card, cards_on_table )
    #p lbl_card, cards_on_table
    res = []
    rank_play_card = @game_deckinfo[lbl_card][:rank]
    cards_on_table.each do |card|
      rank_curr_table_item = @game_deckinfo[card][:rank]
      if rank_curr_table_item == rank_play_card
        # match ok beause the same rank
        res << [card]
      end 
    end
    if rank_play_card >= 2 and rank_play_card <= @combiof_sum_initial
      # its possible to sum the rank of cards on the table
      #p cards_on_table, rank_play_card
      list_combi = combi_of_sum(cards_on_table, rank_play_card)
      # append result, all combinations are allowed
      list_combi.each{|e| res << e}
      if @game_opt[:combi_sum_lesscard] and res.size > 1
        # we have a combination restriction. Only the combination with the smaller size
        # of cards is allowed
        #@log.debug("which_cards_pick: Combination is restricted to the min")
        tmp = res.sort{|a,b| a.size <=> b.size}
        res = []
        size_min = tmp.last.size
        tmp.each do |arr|
          if arr.size <= size_min
            res << arr
            size_min = arr.size 
          else
            break
          end 
        end
        #p res
      end
    else
      #@log.debug("which_cards_pick: card outside the rank(2-#{@combiof_sum_initial})")
    end
    #p "which_cards_pick, Resul:#{res}"
    return res
  end
  
  ##
  # Check the combination of list_curr with additional rest_arr on target valtarget
  # This function is built to be used in recursion mode
  def combi_of_sum(arr_cards_input, val)
    arr_cards = arr_cards_input.sort{ |x,y| @game_deckinfo[x][:rank] <=> @game_deckinfo[y][:rank] }
    #p "combi_of_sum #{arr_cards}, #{val}"
    #p @game_deckinfo
    res = []
    res_rank_sorted = []
    if val > @combiof_sum_initial or val < 2
      # search only combination  2 - @combiof_sum_initial
      return res
    end
    @result_combi = []
    ix = 1
    arr_cards.each do |c1|
      rest_arr = arr_cards[ix..-1]
      combi_line(c1, rest_arr, val)
      ix += 1
    end
    return @result_combi
  end
  
  ##
  # Check the combination of list_curr with additional rest_arr on target valtarget
  # This function is built to be used in recursion mode
  def combi_line(list_curr, rest_arr, valtarget)
    ix = 1
    rest_arr.each do |c2|
      list_new = [list_curr, c2].flatten
      #p "checking listnew #{list_new.join(",")}"
      # calculate the sum of list_new
      sum_curr = list_new.inject(0) do |sum, x|
        sum += @game_deckinfo[x][:rank]
      end   
      if sum_curr == valtarget
        # combination found
        #p "Combi found #{list_new.join(",")}"
        @result_combi << list_new
        # here do nothing, build another list_new with the next c2
        # we can than have another combination with the next c2 
      elsif sum_curr > valtarget
        # at this point sum can only be bigger then target, break search
        return
      else
        # sum is smaller
        combi_line(list_new, rest_arr[ix..-1], valtarget)
      end
      ix += 1
    end
  end
 
end

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
  core = CoreGameSpazzino.new
  rep = ReplayerManager.new(log)
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/spazzino/saved_games/test.yaml')
  #p match_info
  player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  alg_coll = { "Gino B." => nil } 
  segno_num = 0
  rep.replay_match(core, match_info, alg_coll, segno_num)
  #sleep 2
end
