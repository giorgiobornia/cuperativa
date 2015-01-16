# file: core_game_briscola.rb
# handle the briscola game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../../base/core/game_replayer'
require 'alg_cpu_briscola'

# Class to manage the core card game
class CoreGameBriscola < CoreGameBase
  attr_accessor :game_opt, :rnd_mgr
  attr_reader :num_of_cards_onhandplayer
  
  @@TEST_DECK_BRISCOLA_PATH = File.dirname(__FILE__) + '/../../test/briscola/saved_games'
  
  def initialize
    super
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points_segno => 61, 
      :num_segni_match => 2, 
      :num_of_players => 2,
      :test_with_custom_deck => false,
      :test_custom_deckname => 'brisc01.yaml',
      :replay_game => false, # if true we are using information already stored
      :record_game => true  # if true record the game
    } 
    
    # players (instance of class PlayerOnGame) order that have to play
    @round_players = []
    #p @mazzo_gioco
    #p @@deck_info
    
    # array di simboli delle carte(:bA :c4 ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    # array of players (instance of class PlayerOnGame
    @players = []
    # cards played during the mano on the table. Array of hash with lbl_card => player
    @carte_gioc_mano_corr = []
    # cards holds (to be played) for each player. The key is a player name, values are an array of card labels
    @carte_in_mano = {}
    # cards taken for each player. The key is a player name, values are an array of card labels
    @carte_prese = {}
    # points accumulated in the current segno for each player. The key is a player name, 
    # value is current player score.
    @points_curr_segno = {}
    # segni accumulated in the current match for each player. The key is a player name, 
    # value is current number of segni wons by the player.
    @segni_curr_match = {}
    # briscola in tavola. Simple card label
    @briscola_in_tav_lbl = nil
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
    # count the number of hands inside a giocata
    @mano_count = 0
  end
  
  ##
  #Provides an hash with for the viewer to build the current game state
  def on_viewer_get_state()
    res = {}
    #points
    res[:points_curr_segno] = @points_curr_segno
    # players
    players_name = []
    @players.each{|x| players_name << x.name}
    res[:players] = players_name
    # number of cards in hand
    num_carte_player = {} 
    @carte_in_mano.each do |k,v|
      num_carte_player[k] = 0
      v.each{|lbl| num_carte_player[k] += 1}
    end
    res[:carte_in_mano] = num_carte_player 
    # taken cards
    res[:carte_prese] = @carte_prese
    #segni
    res[:segni_curr_match] = @segni_curr_match
    # briscola
    res[:briscola_in_tav_lbl] = @briscola_in_tav_lbl
    # deck
    res[:decksize] = @mazzo_gioco.size
    
    return res
  end
  
  ##
  # Save current game into a file
  def save_curr_game(fname)
    @log.info("Game saved on #{fname}")
    @game_core_recorder.save_match_to_file(fname)
  end
  
  ##
  # return true is the current match as a minimun information for score
  def is_matchsuitable_forscore?
    tot_segni = 0
    @segni_curr_match.each_value{|v| tot_segni += v }
    if tot_segni > 0 or @mano_count > 3
      return true
    end
    return false
  end
  
  ##
  # Build deck before shuffle
  def create_deck
    @log.debug("Create a deck with rank and points")
    # array di simboli delle carte(:_Ac :_4c ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    # set card values and points
    val_arr_rank   = [12,2,11,4,5,6,7,8,9,10] # card value order
    val_arr_points = [11,0,10,0,0,0,0,2,3,4] # card points
    # modifica il mazzo aggiungendo punti e valore delle carte per il gioco specifico della briscola
    @@deck_info.each do |k, card| 
      curr_index = card[:ix]
      card[:rank] = val_arr_rank[curr_index % 10]
      card[:points] = val_arr_points[curr_index % 10]
      # mazzo viene gestito solo coi simboli
      @mazzo_gioco << k
    end
  end
  
  ###
  # Log the current deck
  def dump_curr_deck
    #str = YAML.dump(@mazzo_gioco)
    str = @mazzo_gioco.join(",")
    @log.info("Current deck:\n#{str}")
  end
  
  def set_specific_options(options)
    #p options[:games][:briscola]
    if options[:games][:briscola]
      opt_briscola = options[:games][:briscola]
      if opt_briscola[:num_segni_match]
        @game_opt[:num_segni_match] = opt_briscola[:num_segni_match][:val]
      end
      if opt_briscola[:target_points_segno]
        @game_opt[:target_points_segno] = opt_briscola[:target_points_segno][:val]
      end
    end
    #p @game_opt[:num_segni_match]
  end
  
  ##
  # Test a game with a custom deck file
  def test_with_custom_deck
    @log.debug("Test a game with a custom deck")
    match_info = YAML::load_file(@@TEST_DECK_BRISCOLA_PATH + '/' + @game_opt[:test_custom_deckname])
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
    @carte_prese = {}
    @carte_in_mano = {}
    @mano_count = 0
    # reset also events queue
    clear_gevent
    
     #extract the first player
    first_player_ix = @rnd_mgr.get_first_player(@players.size) #rand(@players.size)
    # calculate the player order (first is the player that have to play)
    @round_players = calc_round_players( @players, first_player_ix)
    
    create_deck
    #shuffle deck
    @mazzo_gioco = @rnd_mgr.get_deck(@mazzo_gioco)
    
    @game_core_recorder.store_new_giocata(@mazzo_gioco, first_player_ix) if @game_opt[:record_game]
    dump_curr_deck
    
    new_giocata_distribuite_cards
    
  end
  
  def new_giocata_distribuite_cards
    # distribuite card to each player
    carte_player = []
    briscola = @mazzo_gioco.pop 
    @briscola_in_tav_lbl = briscola
    @round_players.each do |player|
      @num_of_cards_onhandplayer.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player, briscola].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      @points_curr_segno[player.name] = 0
    end
    inform_viewers(:onalg_new_giocata,@num_of_cards_onhandplayer, briscola)
    #p @carte_prese
    submit_next_event(:new_mano)
  end
  
  ##
  # Col termine di mano ci si riferisce a tutte le carte giocate dai giocatori
  # prima che ci sia una presa
  def new_mano
    @log.info "new_mano"
    # reverse it for use pop
    @round_players.reverse!
    player_onturn = @round_players.last
    
    #inform about start new mano
    @players.each{|pl| pl.algorithm.onalg_newmano(player_onturn) }
    
    # notify all players about player that have to play
    @players.each do |pl|
      pl.algorithm.onalg_have_to_play(player_onturn, [])
    end
    inform_viewers(:onalg_have_to_play,player_onturn.name)
  end
  

  ##
  # Check if giocata terminated because a player reach the target points
  def check_if_giocata_is_terminated
    tot_num_cards = 0
    @carte_in_mano.each do |k,card_arr|
      # cards in hand of player
      #p card_arr 
      tot_num_cards += card_arr.size
    end
    tot_num_cards += @mazzo_gioco.size
    @log.debug "Giocata end? cards yet in game are: #{tot_num_cards}"
    
    if tot_num_cards <= 0
      # segno is terminated because no more card are to be played
      @log.debug("Giocata end beacuse no more cards have to be played")
      submit_next_event(:giocata_end)
      return true
    end
    return false
  end
  
  ##
  # Tempo di pescare una carta dal mazzo
  def pesca_carta
    @log.info "pesca_carta"
    carte_player = []
    briscola_in_tavola = true
    if @mazzo_gioco.size > 0
      # ci sono ancora carte da pescare dal mazzo   
      @round_players.each do |player|
        # pesca una sola carta
        if @mazzo_gioco.size > 0
          carte_player << @mazzo_gioco.pop
        elsif briscola_in_tavola == true
          carte_player << @briscola_in_tav_lbl
          @log.info "pesca_carta: distribuisce anche la briscola"
          briscola_in_tavola = false
        else
          @log.error "Pesca la briscola che non c'e' piu'"
        end 
        #p carte_player
        player.algorithm.onalg_pesca_carta(carte_player)
        inform_viewers(:onalg_pesca_carta,player.name,carte_player.size, briscola_in_tavola)
        # store cards to each player for check
        carte_player.each{|c| @carte_in_mano[player.name] << c}
        carte_player = [] # reset array for the next player
      end
    else
      @log.error "Pesca in un mazzo vuoto"
    end
    @log.info "Mazzo rimanenti: #{@mazzo_gioco.size}"
    submit_next_event(:new_mano)
  end
  
  ##
  # Una carta e' stata giocata con successo, continua la mano se
  # ci sono ancora giocatori che devono giocare, altrimenti la mano finisce.
  def continua_mano
    @log.info "continua_mano"
    player_onturn = @round_players.last
    if player_onturn
      # notify all players about player that have to play
      @players.each do |pl|
        if pl == player_onturn
          command_decl_avail = []
          pl.algorithm.onalg_have_to_play(player_onturn, command_decl_avail)
        else
          # don't notify declaration for player that are only informed
          pl.algorithm.onalg_have_to_play(player_onturn, [])
        end 
      end
      inform_viewers(:onalg_have_to_play,player_onturn.name)
    else
      # no more player have to play
      submit_next_event(:mano_end)
    end
  end
  
  ##
  # mano end
  def mano_end
    # mano end calcola chi vince la mano e ricomincia da capo
    # usa @carte_gioc_mano_corr per calcolare chi vince la mano; 
    # accumula le carte prese nell hash @carte_prese
    @log.info "mano_end"
    lbl_best,player_best =  vincitore_mano(@carte_gioc_mano_corr)
    @log.info "mano vinta da #{player_best.name}"
    @mano_count += 1
    
    @carte_gioc_mano_corr.each do |hash_card| 
      hash_card.keys.each{|lbl_card| @carte_prese[player_best.name] << lbl_card }
    end 
    # build circle of player that have now to play
    first_player_ix = @players.index(player_best)
    @round_players = calc_round_players( @players, first_player_ix)
    
    # prepare notification
    carte_prese_mano = []
    @carte_gioc_mano_corr.each do |hash_card| 
      hash_card.keys.each{|k| carte_prese_mano << k }
    end
    
    punti_presi = calc_puneggio(carte_prese_mano)
    @log.info "Punti fatti nella mano #{punti_presi}" 
    @players.each{|pl| pl.algorithm.onalg_manoend(player_best, carte_prese_mano, punti_presi) }
    
    inform_viewers(:onalg_manoend,player_best.name, carte_prese_mano, punti_presi)
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
  
    # add points
    @points_curr_segno[player_best.name] +=  punti_presi
    str_points = ""
    @points_curr_segno.each do |k,v|
      str_points += "#{k} = #{v} "
    end
    @log.info "Punteggio attuale: #{str_points}" 
    
    # check if giocata is terminated
    if check_if_giocata_is_terminated
      return
    end
    
    if @mazzo_gioco.size > 0
      # there are some cards in the deck
      submit_next_event(:pesca_carta)
    else
      # continue without pick the card from deck
      submit_next_event(:new_mano)
    end
  end
  
  def giocata_end_calc_bestpoints
    # notifica tutti i giocatori chi ha vinto il segno
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 45], ["zorro", 33], ["alla", 23], ["casa", 10]]
    best_pl_points =  @points_curr_segno.to_a.sort{|x,y| y[1] <=> x[1]}
    nome_gioc_max = best_pl_points[0][0]
    # increment segni counter
    if best_pl_points[0][1] == 60
      @log.info "Game pareggiato both players with 60 points"
    else
      @segni_curr_match[nome_gioc_max] += 1
    end
    return best_pl_points
  end
  
  ##
  # Segno finito
  def giocata_end
    @log.info "giocata_end"
    @segno_state = :end
    best_pl_points = giocata_end_calc_bestpoints
    if @game_opt[:record_game]
      @game_core_recorder.store_end_giocata(best_pl_points)
    end
    
    @players.each{|pl| pl.algorithm.onalg_giocataend(best_pl_points) }
    inform_viewers(:onalg_giocataend,best_pl_points)
  end
  
  ##
  # Match finito
  def match_end
    @log.info "match_end"
    @match_state = :match_terminated
    # we don't need events anymore
    clear_gevent
    # notifica tutti i giocatori chi ha vinto la partita
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 4], ["zorro", 1]]
    best_pl_segni =  segni_curr_match_sorted
    if @game_opt[:record_game]
      @game_core_recorder.store_end_match(best_pl_segni)
    end
    @players.each{|pl| pl.algorithm.onalg_game_end(best_pl_segni) }
    inform_viewers(:onalg_game_end,best_pl_segni)
  end
  
  ##
  # Provides an array for score, something like : [["rudy", 4], ["zorro", 1]]
  def segni_curr_match_sorted
    return @segni_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
  end
  
  ##
  # Calcola il punteggio delle carte in input
  # carte_prese_mano: card label array (e.g. [:_Ab, :_2s,...])
  def calc_puneggio(carte_prese_mano)
    punti = 0
    carte_prese_mano.each do |card_lbl|
      @@deck_info[card_lbl]
      punti += @@deck_info[card_lbl][:points]
    end
    
    return punti
  end
  
  ##
  # Return player  that catch the current mano and also the card played
  # carte_giocate: an array of hash with label and player (e.g [:_A =>player1])
  def vincitore_mano(carte_giocate)
    lbl_best = nil
    player_best = nil
    carte_giocate.each do |card_gioc|
      # card_gioc is an hash with only one key
      lbl_curr = card_gioc.keys.first
      player_curr = card_gioc[lbl_curr]
      unless lbl_best
        # first card is the best
        lbl_best = lbl_curr
        player_best = player_curr
        # continue with the next
        next
      end
      # now check with the best card
      info_cardhash_best = @@deck_info[lbl_best]
      info_cardhash_curr = @@deck_info[lbl_curr]
      if is_briscola?(lbl_curr) && !is_briscola?(lbl_best)
        # current wins because is briscola and best not
        lbl_best = lbl_curr; player_best = player_curr
      elsif !is_briscola?(lbl_curr) && is_briscola?(lbl_best)
        # best wins because is briscola and current not, do nothing
      else 
        # cards are both briscola or both not, rank decide when both cards are on the same seed
        if info_cardhash_curr[:segno] == info_cardhash_best[:segno]
          if info_cardhash_curr[:rank] > info_cardhash_best[:rank]
            # current wins because is higher
            lbl_best = lbl_curr; player_best = player_curr
          else
            # best wins because is briscola, do nothing
          end
        else
          # cards are not on the same suit, first win, it mean best
        end
      end 
    end
    return lbl_best, player_best
  end
  
  ##
  # Say if the lbl_card is a briscola. 
  # lbl_card: card label (e.g. :_Ab)
  def is_briscola?(lbl_card)
    segno_card = @@deck_info[lbl_card][:segno]
    segno_brisc = @@deck_info[@briscola_in_tav_lbl][:segno]
    return segno_brisc == segno_card 
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
    # set negative value for segni in order to make player marked as looser
    @segni_curr_match[player.name] = -1
    
    submit_next_event(:match_end)
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
  # lbl_card: card played label (e.g. :_Ab)
  def alg_player_cardplayed(player, lbl_card)
    if @segno_state == :end
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn has played, ok
      cards = @carte_in_mano[player.name]
      pos = cards.index(lbl_card) if cards
      if pos
        # card is allowed to be played
        res = :allowed
        if @game_opt[:record_game]
          @game_core_recorder.store_player_action(player.name, :cardplayed, player.name, lbl_card)
        end
        # remove it from list of availablecards
        @carte_in_mano[player.name].delete_at(pos)
        # uses a special trace to recognize this entry
        @log.info "++#{@mano_count},#{@carte_gioc_mano_corr.size},Card #{lbl_card} played from player #{player.name}"
        #store it in array of card played during the current mano
        @carte_gioc_mano_corr << {lbl_card => player}
        
        submit_next_event(:card_played_is_correct)
 
      end 
    end
    if res == :not_allowed
      submit_next_event(:card_played_is_erronous)
    end 
    
    #process_next_gevent
    
    return res
  end
  
  def card_played_is_correct
    #p @carte_gioc_mano_corr
    lbl_card = @carte_gioc_mano_corr.last.keys[0]
    player = @carte_gioc_mano_corr.last.values[0]
    # notify all players that a player has played a card
    @players.each{|pl| pl.algorithm.onalg_player_has_played(player, lbl_card) }
    inform_viewers(:onalg_player_has_played, player.name, lbl_card)
    # remove player from list of players that have to play
    @round_players.pop
    submit_next_event(:continua_mano)
  end
  
  def card_played_is_erronous
    player = @carte_gioc_mano_corr.last.keys[0]
    lbl_card = @carte_gioc_mano_corr.last.values[0]
    player.algorithm.onalg_player_cardsnot_allowed(player, [lbl_card])
    @log.warn "Card #{lbl_card} not allowed to be played from player #{player.name}"
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
      @game_core_recorder.store_new_match(players, @game_opt, "Briscola")
    end
   
    @players = players
    
    submit_next_event(:new_match)
  end
  
  def new_match
    # notify all players about new match
    @log.debug "new_match"
    @players.each do |player| 
      player.algorithm.onalg_new_match( @players )
      @segni_curr_match[player.name] = 0 
    end
    name_players = []
    @players.each {|pl| name_players << pl.name}
    inform_viewers(:onalg_new_match, @players.size, name_players)
    
    submit_next_event(:new_giocata)
  end
  
  ##
  # Trigger a new segno by gui. This action is done by gui and it a 
  # reaction of giocata_end. This is done using the gui because
  # we expect an user interaction after giocata_end and before
  # starting a new segno.
  def gui_new_segno
    @log.debug "gui_new_segno"
    unless @segno_state == :end
      # reject request to start a new segno if it wasn't terminated
      @log.info "gui_new_segno request rejected"
      return
    end
    # when a new segno start, the game event queue should be empty
    clear_gevent
    str_status_segni = ""
    @segni_curr_match.each do |k,v|
      str_status_segni += "#{k} = #{v} "
    end
    @log.info "gui_new_segno #{str_status_segni}"
    if @segni_curr_match.values.max < @game_opt[:num_segni_match]
      # trigger a new giocata
      submit_next_event(:new_giocata)
      #process_next_gevent
    else
      #  wait for a new match
      @log.info "gui_new_segno: aspetta inizio nuovo match"
      submit_next_event(:match_end)
      #process_next_gevent
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
  core = CoreGameBriscola.new
  rep = ReplayerManager.new(log)
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscola/saved_games/test.yaml')
  #p match_info
  player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  alg_coll = { "Gino B." => nil } 
  segno_num = 0
  rep.replay_match(core, match_info, alg_coll, segno_num)
  #sleep 2
end
