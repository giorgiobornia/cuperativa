# file: core_game_tressette.rb


$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

require 'base/core/game_replayer'
require 'alg_cpu_tressette'

class CoreGameTressette < CoreGameBase
  attr_accessor :game_opt, :rnd_mgr
  attr_reader :num_of_cards_onhandplayer
  
  def initialize
    super
    @game_opt = {
      :shuffle_deck => true, 
      :target_points => 21, 
      :num_of_players => 2,
      :test_with_custom_deck => false,
      :test_custom_deckname => 'tre01.yaml',
      :replay_game => false, # if true we are using information already stored
      :record_game => true  # if true record the game
    }
    @test_deck_path = File.dirname(__FILE__) + '/../../test/tressette/saved_games'
    # players (instance of class PlayerOnGame) order that have to play
    @round_players = []
    # array di simboli delle carte(:bA :c4 ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    # array of players (instance of class PlayerOnGame
    @players = []
     # cards holds (to be played) for each player. The key is a player name, values are an array of card labels
    @carte_in_mano = {}
    # cards taken for each player. The key is a player name, values are an array of card labels
    @carte_prese = {}
    # points accumulated in the current segno for each player. The key is a player name, 
    # value is current player score.
    @points_curr_smazzata = {}
    # points accumulated in the current match for each player. The key is a player name.
    @points_curr_match = {} 
    @num_of_cards_onhandplayer = 10
    # segno state
    @smazzata_state = :undefined 
    # match state
    @match_state = :undefined
    # random manager
    @rnd_mgr = RandomManager.new
    # game recorder
    @game_core_recorder = GameCoreRecorder.new
    # count the number of hands inside a giocata
    @mano_count = 0
    # mazziere player index
    @mazziere_ix = 0
    @log = Log4r::Logger.new("coregame_log::CoreGameTressette") 
  end
  
  ## Algorithm and GUI notification calls ####################
  
  ##
  # Player resign a game
  # player: instance of PlayerOnGame
  # reason: :abandon or :disconnection
  def alg_player_resign(player, reason)
    if @smazzata_state == :end
      @log.warn "Resign not valid in state #{@smazzata_state} (#{get_curr_stack_call})"
      return :not_allowed
    end
    @log.info "alg_player_resign: giocatore perde la partita"
    if @game_opt[:record_game]
      @game_core_recorder.store_player_action(player.name, :resign, player.name, reason)
    end
    @smazzata_state = :end
    submit_next_event(:match_end)
    # set negative value for segni in order to make player marked as looser
    @points_curr_match[player.name] = -1
  end
  
  ##
  # Notification player has make a declaration
  # name_decl: name of mariazza declaration defined in @mariazze_def (e.g. :mar_den)
  def alg_player_declare(player, name_decl)
    
  end
  
  # carte_gioc_mano_corr: same as @carte_gioc_mano_corr. Used as parameter for gfx calls
  def card_could_be_played?(player_carte_in_mano, lbl_card, carte_gioc_mano_corr)
    bres = false
    if player_carte_in_mano.index(lbl_card)
      if carte_gioc_mano_corr.size > 0
        # we have suit
        suit = @suit_curr_mano
        card_played_segno = @game_deckinfo[lbl_card][:segno]
        if suit == card_played_segno
          return true
        else
           player_carte_in_mano.each do |carta_in_mano|
             card_inmano_segno = @game_deckinfo[carta_in_mano][:segno]
             if card_inmano_segno == suit
               @log.debug "Found card playble #{carta_in_mano}, player can't play #{lbl_card} because is not #{suit}"
               return false # trovata in mano una carta giocabile dello stesso segno della prima
             end
           end
           return true
        end
      else
        # prima mano tutto lecito
        return true
      end
    end
    return bres     
  end
  
  ##
  # Notification player has played a card
  # lbl_card: card played label (e.g. :_Ab)
  def alg_player_cardplayed(player, lbl_card)
    @carta_giocata_sbagliata = {:card => lbl_card, :player => player}
    if @smazzata_state == :end
      @carta_giocata_sbagliata[:reason] = "smazzata_state not end"
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn has played, ok
      cards = @carte_in_mano[player.name]
      #pos = cards.index(lbl_card) if cards
      #if pos
      if card_could_be_played?(cards, lbl_card, @carte_gioc_mano_corr)
        # card is allowed to be played
        res = :allowed
        if @game_opt[:record_game]
          @game_core_recorder.store_player_action(player.name, :cardplayed, player.name, lbl_card)
        end
        # remove it from list of availablecards
        pos = cards.index(lbl_card)
        @carte_in_mano[player.name].delete_at(pos)
        # uses a special trace to recognize this entry
        @log.info "++#{@mano_count},#{@carte_gioc_mano_corr.size},Card #{lbl_card} played from player #{player.name}"
        #store it in array of card played during the current mano
        card_played_segno = @game_deckinfo[lbl_card][:segno]
        if @carte_gioc_mano_corr.size == 0
          @suit_curr_mano = card_played_segno
        end
        @carte_gioc_mano_corr << {:card_lbl => lbl_card,  :player_name => player.name}
        
        submit_next_event(:card_played_is_correct)
      else
        @carta_giocata_sbagliata[:reason] = "card not ruled"
      end 
    else
      @carta_giocata_sbagliata[:reason] = "player not in turn"
    end
    
    if res == :not_allowed
      submit_next_event(:card_played_is_erronous)
    end 
    
    return res
  end
  
  def card_played_is_correct
    @log.debug "Card is played correctly"
    #p @carte_gioc_mano_corr
    card_played_info = @carte_gioc_mano_corr.last
    lbl_card = card_played_info[:card_lbl]
    player_name = card_played_info[:player_name]
    player = @players_name_to_player[player_name]
    # notify all players that a player has played a card
    @players.each{|pl| pl.algorithm.onalg_player_has_played(player, lbl_card) }
    # remove player from list of players that have to play
    @round_players.pop
    submit_next_event(:continua_mano)
  end
  
  def card_played_is_erronous
    player = @carta_giocata_sbagliata[:player]
    lbl_card = @carta_giocata_sbagliata[:card]
    player.algorithm.onalg_player_cardsnot_allowed(player, [lbl_card])
    @log.warn "Card #{lbl_card} not allowed to be played from player #{player.name}: #{@carta_giocata_sbagliata[:reason]}"
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
    @players_name_to_player = {}
    # notify all players about new match
    @players.each do |player| 
      @players_name_to_player[player.name] = player
      player.algorithm.onalg_new_match( @players )
      if @rnd_mgr.is_predefined_set?
        # on replayed game we need to accumulate points between matches
        @points_curr_match[player.name] = 0 unless @points_curr_match[player.name]
      else
        @points_curr_match[player.name] = 0
      end 
    end
    
    submit_next_event(:new_giocata)
  end
  
  ###
  # Log the current deck
  def dump_curr_deck
    #str = YAML.dump(@mazzo_gioco)
    str = @mazzo_gioco.join(",")
    @log.info("Current deck:\n#{str}")
  end
  
  ##
  # Build deck before shuffle
  def create_deck
    @log.debug("[core]Create a deck with rank and points")
    # array di simboli delle carte(:_Ac :_4c ...) gestisce il mazzo delle carte durante la partita
    @mazzo_gioco = []
    @game_deckinfo = {}
    # set card values and points
    val_arr_rank   = [11 , 12, 13, 4, 5, 6, 7, 8, 9,10] # card value order
    val_arr_points = [3,1,1,0,0,0,0,1,1,1] # using triple points
    @@deck_info.each do |k, card|
      curr_index = card[:ix]
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
  
  ##
  # Reset points for new giocata
  def reset_points_newgiocata(player)
    @points_curr_smazzata[player.name] = {:pezze => 0, :assi => 0,
           :tot => 0}
  end
  
  ##
  # Col termine di giocata ci si riferisce al mescolamento delle carte e alla
  # sua distribuzione
  def new_giocata
    @log.info "new_giocata"
    @smazzata_state = :started
     # reset some data structure
    @mano_count = 0
    @carte_prese = {}
    @carte_in_mano = {}
    # reset also events queue
    clear_gevent
    
    #extract the first player
    first_player_ix = player_ix_afterthis(@players.size, @mazziere_ix)
    # calculate the player order (first is the player that have to play)
    @round_players = calc_round_players( @players, first_player_ix)
    
    create_deck
    #shuffle deck
    @mazzo_gioco = @rnd_mgr.get_deck(@mazzo_gioco) 
    
    @game_core_recorder.store_new_giocata(@mazzo_gioco, first_player_ix) if @game_opt[:record_game]
    dump_curr_deck
    
    # distribuite card to each player
    carte_player = []
    # inform about the mazziere
    @round_players.each{|e| e.algorithm.onalg_new_mazziere(@players[@mazziere_ix])}
    
    # distribute cards to each player
    @round_players.each do |player|
      @num_of_cards_onhandplayer.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      reset_points_newgiocata(player)
    end
    #p @carte_prese
    submit_next_event(:new_mano)
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
    @players.each{|pl| pl.algorithm.onalg_newmano(player_onturn) }
    
    # notify all players about player that have to play
    @players.each do |pl|
      # don't notify commands declaration for player that are only informed
      pl.algorithm.onalg_have_to_play(player_onturn, [])
    end
  end
  
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
    @log.info "mano_end #{@carte_gioc_mano_corr}"
    lbl_best,player_best_name =  vincitore_mano(@carte_gioc_mano_corr)
    player_best = @players_name_to_player[player_best_name]
    @log.info "mano vinta da #{player_best_name}"
    @mano_count += 1
    @last_playername_taken = player_best.name
    
    carte_prese_mano = []
    @carte_gioc_mano_corr.each do |card_played_info|
      lbl_card = card_played_info[:card_lbl]
      carte_prese_mano << lbl_card
      @carte_prese[player_best_name] << lbl_card
    end 
    
    # build circle of player that have now to play
    first_player_ix = @players.index(player_best)
    @round_players = calc_round_players( @players, first_player_ix)
    
    # prepare notification
    punti_presi = calc_punteggio(carte_prese_mano)
    @log.info "Punti fatti nella mano #{punti_presi}" 
    @players.each{|pl| pl.algorithm.onalg_manoend(player_best, carte_prese_mano, punti_presi) }
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
  
    # add points
    @points_curr_smazzata[player_best.name][:pezze] +=  punti_presi[:pezze]
    @points_curr_smazzata[player_best.name][:assi] +=  punti_presi[:assi]
    @points_curr_smazzata[player_best.name][:tot] =  @points_curr_smazzata[player_best.name][:assi] + @points_curr_smazzata[player_best.name][:pezze] / 3 
    
    str_points = string_punteggio()
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
  
  def string_punteggio
    str_points = ""
    @points_curr_smazzata.each do |k,v|
      str_det_points = "Tot #{v[:tot]},Pezze #{v[:pezze]},Assi #{v[:assi]};"
      str_points += "#{k} => #{str_det_points} "
    end
    return str_points
  end
  
  def pesca_carta
    @log.info "pesca_carta"
    carte_player = []
    if @mazzo_gioco.size > 0
      # ci sono ancora carte da pescare dal mazzo   
      @round_players.each do |player|
        # pesca una sola carta
        if @mazzo_gioco.size > 0
          carte_player << @mazzo_gioco.pop
        else
          @log.error "Pesca ma non ci sono carte"
        end 
        #p carte_player
        @round_players.each do |player_to_info|
          player_to_info.algorithm.onalg_player_pickcards(player, carte_player)
        end
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
  
  def match_end
    @log.info "match_end"
    @match_state = :match_terminated
    clear_gevent
    # notifica tutti i giocatori chi ha vinto la partita
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 4], ["zorro", 1]]
    best_pl_segni =  points_curr_match_sorted
    if @game_opt[:record_game]
      @game_core_recorder.store_end_match(best_pl_segni)
    end
    @players.each{|pl| pl.algorithm.onalg_game_end(best_pl_segni) }
    #inform_viewers(:onalg_game_end,best_pl_segni)
  end
  
  def points_curr_match_sorted
    return @points_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
  end
  
  ##
  # Return player  that catch the current mano and also the card played
  # carte_giocate: an array of hash with label and player (e.g [:_A =>player1])
  def vincitore_mano(carte_giocate)
    #p carte_giocate
    lbl_best = nil
    player_best = nil
    carte_giocate.each do |card_gioc|
      #{:card_lbl => lbl_card,  :player_name => player.name}
      lbl_curr = card_gioc[:card_lbl]
      player_curr = card_gioc[:player_name]
      unless lbl_best
        # first card is the best
        lbl_best = lbl_curr
        player_best = player_curr
        # continue with the next
        next
      end
      # now check with the best card
      info_cardhash_best = @game_deckinfo[lbl_best]
      info_cardhash_curr = @game_deckinfo[lbl_curr]
      # card best  rank decide when both cards are on the same seed
      if info_cardhash_curr[:segno] == info_cardhash_best[:segno]
        if info_cardhash_curr[:rank] > info_cardhash_best[:rank]
          # current wins because is higher
          lbl_best = lbl_curr; player_best = player_curr
        else
          # best wins  do nothing
        end
      else
        # cards are not on the same seed, first win, it mean best
      end
    end
    return lbl_best, player_best
  end
  
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
      @log.debug("Giocata end beacuse no more cards are to be played")
      submit_next_event(:giocata_end)
      return true
    end
    return false
  end
  
  def giocata_end
    @log.info "giocata_end"
    @smazzata_state = :end
    
    #aggiungi 1 punto ultima mano
    @points_curr_smazzata[@last_playername_taken][:ultima] = 1
    @points_curr_smazzata[@last_playername_taken][:tot] += 1
    
    # notifica tutti i giocatori chi ha vinto il segno
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    #[["Test1", {:assi=>3, :tot=>5, :pezze=>6}], ["Test2", {:assi=>1, :tot=>5, :pezze=>14}]]
    best_pl_points =  @points_curr_smazzata.to_a.sort{|x,y| y[1][:tot] <=> x[1][:tot]}
    
    tot_points_players = best_pl_points[0][1][:tot] + best_pl_points[1][1][:tot]
    if tot_points_players != 11
      @log.error "Programming error: punteggio in somma deve essere 11 e non #{tot_points_players}"
      return
    end 
    
    #adjust match points
    @points_curr_smazzata.each do |k,v|
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
  # Calcola il punteggio delle carte in input
  # carte_prese_mano: card label array (e.g. [:_Ab, :_2s,...])
  def calc_punteggio(carte_prese_mano)
    punti = 0
    assi = 0
    pezze = 0
    carte_prese_mano.each do |card_lbl|
      @game_deckinfo[card_lbl]
      punti += @game_deckinfo[card_lbl][:points]
      assi += 1  if card_is_asso?(card_lbl)
      pezze += 1  if card_is_pezza?(card_lbl)
    end
    punti_info = {:tot=>punti / 3, :pezze=>pezze, :assi=>assi}
    
    return punti_info
  end
  
  def  card_is_asso?(card_lbl)
    return @game_deckinfo[card_lbl][:points] == 3 ? true : false
  end
  
  def  card_is_pezza?(card_lbl)
    return @game_deckinfo[card_lbl][:points] == 1 ? true : false
  end
  
  ##
  # Trigger a new segno by gui. This action is done by gui and it a 
  # reaction of giocata_end. This is done using the gui because
  # we expect an user interaction after giocata_end and before
  # starting a new segno.
  def gui_new_segno
    unless @smazzata_state == :end
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
    @log.debug "gui_new_segno #{str_status_segni}"
    max_points = @points_curr_match.values.max
    # check if the max was done only by a single player
    arr_points = @points_curr_match.values.select{|x| x == max_points}
       
    if max_points < @game_opt[:target_points]
      # trigger a new giocata
      submit_next_event(:new_giocata)
    elsif arr_points.size > 1
      @log.debug "Game over the target points of #{@game_opt[:target_points]} but deuced, continue."
      submit_next_event(:new_giocata)
    else
      #  wait for a new match
      @log.info "gui_new_segno: aspetta inizio nuovo match"
      submit_next_event(:match_end)
      return :match_end
    end
    return :new_giocata
  end
  
  ##
  # Save current game into a file
  def save_curr_game(fname)
    @log.info("Game saved on #{fname}")
    @game_core_recorder.save_match_to_file(fname)
  end
  
end#end CoreGameTressette

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
  core = CoreGameTressette.new
  rep = ReplayerManager.new(log)
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscolone/saved_games/test.yaml')
  ##p match_info
  #player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_coll = { "Gino B." => nil } 
  #segno_num = 0
  #rep.replay_match(core, match_info, alg_coll, segno_num)
  ##sleep 2
end
