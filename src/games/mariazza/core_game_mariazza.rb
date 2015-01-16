# file: core_game_mariazza.rb
# handle the mariazza game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../../base/core/game_replayer'
require 'alg_cpu_mariazza'

# Class to manage the core card game
class CoreGameMariazza < CoreGameBase
  attr_accessor :game_opt, :rnd_mgr
  attr_reader :num_of_cards_onhandplayer
  
  TEST_DECK_MARIAZ_PATH = File.dirname(__FILE__) + '/../../test'
  
  def initialize
    super
    # set all options related to the game
    @game_opt = {
      :shuffle_deck => true, 
      :target_points_segno => 41, 
      :num_segni_match => 4, 
      :testmariazza_deck => false,
      :test_sette => false,
      :test_with_custom_deck => false,
      :num_of_players => 2,
      :replay_game => false, # if true we are using information already stored
      :record_game => true  # if true record the game
    } 
    # defines mariazza declaration
    @mariazze_def = {:mar_den => {:name_lbl => "Mariazza di denari", :carte => [:_Cd, :_Rd]}, 
                     :mar_spa => {:name_lbl => "Mariazza di spade", :carte => [:_Cs, :_Rs]},
                     :mar_cop => {:name_lbl => "Mariazza di coppe", :carte => [:_Cc, :_Rc]},
                     :mar_bas => {:name_lbl => "Mariazza di bastoni", :carte => [:_Cb, :_Rb]}
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
    # declaration done for each player. The key is a player name, values are an array of
    # keys of @mariazze_def hash
    @declaration_done = {}
    # points accumulated in the current segno for each player. The key is a player name, 
    # value is current player score.
    @points_curr_segno = {}
    # segni accumulated in the current match for each player. The key is a player name, 
    # value is current number of segni wons by the player.
    @segni_curr_match = {}
    # briscola in tavola. Simple card label
    @briscola_in_tav_lbl = nil
    # mariazza point for the next declaration
    @mariazza_points_nextdecl = 20
    # pending points mariazza declaration on the second mano
    @pending_mariazza_points = {}
    # segno state
    @segno_state = :undefined 
    # match state
    @match_state = :undefined
    # random manager
    @rnd_mgr = RandomManager.new
    # game recorder
    @game_core_recorder = GameCoreRecorder.new
    # number of card on each player
    @num_of_cards_onhandplayer = 5
  end
  
  ##
  # Save current game into a file
  def save_curr_game(fname)
    @log.info("Game saved on #{fname}")
    @game_core_recorder.save_match_to_file(fname)
  end
  
  ##
  # Provides an array for score, something like : [["rudy", 4], ["zorro", 1]]
  def segni_curr_match_sorted
    return @segni_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
  end
  
  def num_cards_on_mazzo
    return @mazzo_gioco.size
  end
  
   ##
  # return true is the current match as a minimun information for score
  def is_matchsuitable_forscore?
    tot_segni = 0
    @segni_curr_match.each_value{|v| tot_segni += v }
    if tot_segni > 0
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
    # modifica il mazzo aggiungendo punti e valore delle carte per il gioco specifico della mariazza
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
  
  ##
  # Prepare deck for mariazza declaration
  def test_mazzo_per_mariazza_decl
    @log.info "Test Mariazza declaration..."
    # briscola is the first card popped, than opponent an than gui player card.
    # remember we are using the deck from last element to the first.
    index_pl1 = (@mazzo_gioco.size - 1) - 6 # player on the gui (jump briscola and opponent cards)
    #index_pl1 = (@mazzo_gioco.size - 1) - 1 # player algorithm (jump the briscola)
    # we are extracting card from the end of the deck using pop method 
    # set mariazza of denari
    @mazzo_gioco[index_pl1] = :_Cd
    @mazzo_gioco[index_pl1 - 1] = :_Rd
  end
  
  ##
  # Prepare deck for 7 that take the card on table for briscola
  def test_mazzo_per_sette
    player = @round_players[0]
    extra = 6
    if player.type == :human_local
      extra = 1
    end
    index_pl_gui = (@mazzo_gioco.size - 1) - extra
    index_briscola = (@mazzo_gioco.size - 1)
    @mazzo_gioco[index_pl_gui] = :_7s
    @mazzo_gioco[index_pl_gui - 1] = :_Rs
    @mazzo_gioco[index_briscola] = :_Cs
  end
  
  ##
  # Test a game with a custom deck file
  def test_with_custom_deck
    @log.debug("Test a game with a custom deck")
    match_info = YAML::load_file(TEST_DECK_MARIAZ_PATH + '/mariaz_acc_secd_04.yaml')
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
    @declaration_done = {}
    @mariazza_points_nextdecl = 20
    @pending_mariazza_points = {}
    # reset also events queue
    clear_gevent
    
     #extract the first player
    first_player_ix = @rnd_mgr.get_first_player(@players.size) #rand(@players.size)
    # calculate the player order (first is the player that have to play)
    @round_players = calc_round_players( @players, first_player_ix)
    
    create_deck
    #shuffle deck
    @mazzo_gioco = @rnd_mgr.get_deck(@mazzo_gioco) 
    test_mazzo_per_mariazza_decl if @game_opt[:testmariazza_deck]
    test_mazzo_per_sette if@game_opt[:test_sette]
    
    
    @game_core_recorder.store_new_giocata(@mazzo_gioco, first_player_ix) if @game_opt[:record_game]
    dump_curr_deck
    
    # distribuite card to each player
    carte_player = []
    briscola = @mazzo_gioco.pop 
    @briscola_in_tav_lbl = briscola
    @round_players.each do |player|
      5.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player, briscola].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      @points_curr_segno[player.name] = 0
      @declaration_done[player.name] = []
    end
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
      if pl == player_onturn  
        if @pending_mariazza_points[player_onturn.name]
          # player now can get points prieviously declared
          points_get = @pending_mariazza_points[player_onturn.name][:points]
          # don't reset all @pending_mariazza_points because it could be more mariazza declaration pending
          @pending_mariazza_points[player_onturn.name] = nil #points are consumed
          @log.info "Player #{player_onturn.name} get #{points_get} points for declaration in the past"
          @points_curr_segno[player_onturn.name] += points_get
          # notify all players that a player has got points
          @players.each do |player_to_ntf|
            # pay attention with the name because we are already iterating @players
            player_to_ntf.algorithm.onalg_player_has_getpoints(player_onturn, points_get) 
          end
          # check if the player reach a target points
          if check_if_giocata_is_terminated
            # we don't need to continue anymore
            return 
          end
        end
        # check which mariazza declarations are availables
        command_decl_avail = check_mariaz_declaration(player_onturn)
        #check for additional change of the briscola command
        check_change_briscola(player_onturn, command_decl_avail )
        # notify player about his available commands 
        pl.algorithm.onalg_have_to_play(player_onturn, command_decl_avail)
      else
        # don't notify commands declaration for player that are only informed
        pl.algorithm.onalg_have_to_play(player_onturn, [])
      end
    end
  end
  
  ##
  # Check if the player can make a chage of briscola on table
  # command_decl_avail: array of hash with command definition 
  # We are using 3 index: :name, :points and :change_briscola. :name, :points
  # are always set, :change_briscola is only in this function
  def check_change_briscola(player, command_decl_avail )
    cards = @carte_in_mano[player.name]
    cards.each do |card_on_hand|
      symb_card_on_hand = get_card_logical_symb(card_on_hand)
      if is_briscola?(card_on_hand) and symb_card_on_hand == :set and @mazzo_gioco.size > 0
        # 7 of briscola is present on player hand and there is briscola on the table to take
        command_decl_avail << {
            :name => :change_brisc,
            :points => 0,
            # briscola change
            :change_briscola => {
              :briscola => @briscola_in_tav_lbl,
              :on_hand => card_on_hand
            } 
          }
        break
      end
    end
    
  end
  
  ##
  # Check if the player has some declaration, and if yes give availables commands
  # This function return an array of hash. A command use alway index :name and :points.
  def check_mariaz_declaration(player)
    commands_avail = []
    carte_player = @carte_in_mano[player.name]
    @mariazze_def.each do |k, mariaz_ref|
      ix1 = carte_player.index(mariaz_ref[:carte][0])
      ix2 = carte_player.index(mariaz_ref[:carte][1])
      if ix1 and ix2
        #found mariazza
        # check if it was already declared
        decl_ix = @declaration_done[player.name].index(k)
        unless decl_ix
          # mariazza not declared
          @log.debug "Found mariazza #{mariaz_ref[:name_lbl]}"
          # if mariazza has the same seed like briscola it has 20 points more
          seed_b = @briscola_in_tav_lbl.to_s[2..-1]
          seed_mariaz = mariaz_ref[:carte][0].to_s[2..-1]
          extra_points = 0
          if seed_b == seed_mariaz
            # mariazza on the same seed of briscola
            @log.debug "Found mariazza on briscola, 20 more points"
            extra_points = 20
          end
          commands_avail << {
            #name of the command
            :name => k,
            #point of the command 
            :points => @mariazza_points_nextdecl + extra_points,
            # briscola change
            :change_briscola => nil 
          }
        end
      end
    end 
    return commands_avail   
  end
  
  ##
  # Check if giocata terminated because a player reach the target points
  def check_if_giocata_is_terminated
    # usando max(metodo di enumerable) per un hash, ogni valore e' un array
    # dove il primo valore e' la chiave il secondo il valore (ex: ["toro", 40]).
    # max fornisce un solo array, ma questo non e' un problema
    nome_gioc_max, punti_attuali_max = @points_curr_segno.max{|a,b| a[1]<=>b[1]}
    # il pareggio non e' possibile in quanto il gioco finisce subito dopo che
    # un giocatore raggiunge i 41 punti
    str_points = ""
    @points_curr_segno.each do |k,v|
      str_points += "#{k} = #{v} "
    end
    @log.info "Punteggio attuale: #{str_points}" 
    if punti_attuali_max >= @game_opt[:target_points_segno]
      # segno is terminated target points is reached
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
          # check which declaration are availables
          # expert say that mariazza declaration is always available, but points 
          # are given when the player start to play
          command_decl_avail = []
          command_decl_avail = check_mariaz_declaration(player_onturn) 
          check_change_briscola(player_onturn, command_decl_avail )
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
    @log.info "mano_end"
    lbl_best,player_best =  vincitore_mano(@carte_gioc_mano_corr)
    @log.info "mano vinta da #{player_best.name}"
    
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
    
    # reset cards played on  the current mano
    @carte_gioc_mano_corr = []
    
    # vedi su uno dei due giocatori ha raggiunto o superato il punteggio finale
    # se e' cosi' termina la giocata
    
    # add points
    @points_curr_segno[player_best.name] +=  punti_presi
    # check if segno is finished
    # usando max(metodo di enumerable) per un hash, ogni valore e' un array
    # dove il primo valore e' la chiave il secondo il valore (ex: ["toro", 40]).
    # max fornisce un solo array, ma questo non e' un problema
    nome_gioc_max, punti_attuali_max = @points_curr_segno.max{|a,b| a[1]<=>b[1]}
    # il pareggio non e' possibile in quanto il gioco finisce subito dopo che
    # un giocatore raggiunge i 41 punti
    str_points = ""
    @points_curr_segno.each do |k,v|
      str_points += "#{k} = #{v} "
    end
    @log.info "Punteggio attuale: #{str_points}" 
    # segno finisce quando si raggiunge il punteggio target oppure non ci sono
    # più carte da giocare
    flag_carte_da_giocare = false
    @carte_in_mano.each do |k,v|
      # guarda in mano a tutti i giocatori se hanno in mano delle carte da giocare
      if v.size > 0
        # qualcuno ha ancora carte da giocare, fine ricerca
        flag_carte_da_giocare = true
        break
      end
    end
    if punti_attuali_max >= @game_opt[:target_points_segno] or !flag_carte_da_giocare
      # segno finito, punteggio raggiunto oppure nessuna carta da giocare
      submit_next_event(:giocata_end)
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
  
  ##
  # Segno finito
  def giocata_end
    @log.info "giocata_end"
    @segno_state = :end
    
    # notifica tutti i giocatori chi ha vinto il segno
    # crea un array di coppie fatte da nome e punteggio, esempio: 
    # [["rudy", 45], ["zorro", 33], ["alla", 23], ["casa", 10]]
    best_pl_points =  @points_curr_segno.to_a.sort{|x,y| y[1] <=> x[1]}
    nome_gioc_max = best_pl_points[0][0]
    # increment segni counter
    @segni_curr_match[nome_gioc_max] += 1
    if @game_opt[:record_game]
      @game_core_recorder.store_end_giocata(best_pl_points)
    end
    
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
    best_pl_segni =  @segni_curr_match.to_a.sort{|x,y| y[1] <=> x[1]}
    if @game_opt[:record_game]
      @game_core_recorder.store_end_match(best_pl_segni)
    end
    @players.each{|pl| pl.algorithm.onalg_game_end(best_pl_segni) }
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
          # cards are not on the same seed, first win, it mean best
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
    submit_next_event(:match_end)
    # set negative value for segni in order to make player marked as looser
    @segni_curr_match[player.name] = -1
    #process_next_gevent
  end
  
  ##
  # Notification player change his card with the card on table that define briscola
  # Only the 7 of briscola is allowed to make this change
  def alg_player_change_briscola(player, card_briscola, card_on_hand )
    if @segno_state == :end
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn want to change briscola: ok
      cards = @carte_in_mano[player.name]
      if cards 
        pos1 = cards.index(card_on_hand)
        if pos1 and @briscola_in_tav_lbl == card_briscola
          symb_card_on_hand = get_card_logical_symb(card_on_hand)
          if is_briscola?(card_on_hand) and symb_card_on_hand == :set  
            # 7 of briscola  is really in the hand of the player
            res = :allowed
            if @game_opt[:record_game]
              @game_core_recorder.store_player_action(player.name, :change_briscola, player.name, card_briscola, card_on_hand)
            end
            # swap 7 with briscola
            @carte_in_mano[player.name][pos1] = card_briscola
            @briscola_in_tav_lbl =  card_on_hand
            @log.info "Player #{player.name} changes the briscola on table " +
                "#{CoreGameBase.nome_carta_completo(card_briscola)} with #{CoreGameBase.nome_carta_completo(card_on_hand)}"
            # notify all players that a briscola was changed
            @players.each do |pl| 
              pl.algorithm.onalg_player_has_changed_brisc(player, card_briscola, card_on_hand) 
            end
            #notify the player that have to play with a recalculation of commands
            # mariazza is available only if we start firts
            command_decl_avail = []
            #if @carte_gioc_mano_corr.size == 0
            command_decl_avail = check_mariaz_declaration(player)
            #end
            # don't need to check change briscola
            # remember the player have to play
            player.algorithm.onalg_have_to_play(player, command_decl_avail)
          end
        end
      end 
    end
    @log.info "Changing #{card_briscola} with #{card_on_hand} not allowed from player #{player.name}" if res == :not_allowed
    
    #process_next_gevent
    
    return res
  end
  
  ##
  # Notification player has make a declaration
  # name_decl: name of mariazza declaration defined in @mariazze_def (e.g. :mar_den)
  def alg_player_declare(player, name_decl)
    if @segno_state == :end
      return :not_allowed
    end
    res = :not_allowed
    if @round_players.last == player
      # the player on turn want to declare: ok
      cards = @carte_in_mano[player.name]
      if cards and @mariazze_def[name_decl]
        c1_mar = @mariazze_def[name_decl][:carte][0]
        c2_mar = @mariazze_def[name_decl][:carte][1]
        pos1 = cards.index(c1_mar)
        pos2 = cards.index(c2_mar)
        if pos1 and pos2
          # mariazza is really in the hand of the player
          # check if it is already declared
          decl_ix = @declaration_done[player.name].index(name_decl) 
          unless decl_ix
            # Mariazza declaration OK, check points
            # first instace of mariazza declaration 
            # add mariazza points
            seed_b = @briscola_in_tav_lbl.to_s[2..-1]
            seed_mariaz = c1_mar.to_s[2..-1]
            extra_points = 0
            if seed_b == seed_mariaz
              # mariazza on the same seed of briscola
              extra_points = 20
            end
            points_mariazza_decl = @mariazza_points_nextdecl + extra_points
            if first_to_play?(player)
              @points_curr_segno[player.name] += points_mariazza_decl
              # don't reset all @pending_mariazza_points because it could be more mariazza declaration pending
              @pending_mariazza_points[player.name] = nil #points are consumed
            else
              # we are not on first mano, that mean we can declare but poits are assigned when 
              # we are first
              @log.debug("Player #{player.name} accumulate points (#{points_mariazza_decl}) assigned when he start")
              @pending_mariazza_points[player.name] ||=  { :points => 0}
              @pending_mariazza_points[player.name][:points] += points_mariazza_decl
              points_mariazza_decl = 0
            end 
            @declaration_done[player.name] << name_decl 
            res = :allowed
            if @game_opt[:record_game]
              @game_core_recorder.store_player_action(player.name, :declare, player.name, name_decl)
            end
            @log.info "Player #{player.name} declare #{@mariazze_def[name_decl][:name_lbl]}"
            # notify all players that a player has declared
            @players.each do |pl| 
              pl.algorithm.onalg_player_has_declared(player, name_decl, points_mariazza_decl) 
            end
            # check if the giocata is terminated
            if check_if_giocata_is_terminated
              @log.debug("Giocata is terminated with declaration")
            else
            
              # set points for next mariazza declaration
              #@mariazza_points_nextdecl += 20
              # experts in Breda say that mariazza is always 20 points
              @mariazza_points_nextdecl = 20
            
              # remember the player have to play
              command_decl_avail=[]
              check_change_briscola(player, command_decl_avail )
              player.algorithm.onalg_have_to_play(player, command_decl_avail)
            end
          end
        end
      end 
    end
    if res == :not_allowed
      @log.info "Declaration #{name_decl} not allowed from player #{player.name}"
    end 
    
    #process_next_gevent
    
    return res
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
        @log.info "Card #{lbl_card} played from player #{player.name}"
        #store it in array of card played during the current mano
        @carte_gioc_mano_corr << {lbl_card => player}
        # notify all players that a player has played a card
        @players.each{|pl| pl.algorithm.onalg_player_has_played(player, lbl_card) }
        # remove player from list of players that have to play
        @round_players.pop
        submit_next_event(:continua_mano)
      end 
    end
    if res == :not_allowed
      #crash
      #p @carte_in_mano
      @log.warn "Card #{lbl_card} not allowed to be played from player #{player.name}"
    end 
    
    #process_next_gevent
    
    return res
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
      @game_core_recorder.store_new_match(players, @game_opt, "Mariazza")
    end
   
    @players = players
    # notify all players about new match
    @players.each do |player| 
      player.algorithm.onalg_new_match( @players )
      @segni_curr_match[player.name] = 0 
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
  core = CoreGameMariazza.new
  rep = ReplayerManager.new(log)
  # test algorithm change briscola
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/mariazza/saved_games/mariaz_sett_cam_brisc.yaml')
  # test mariazza declaration second
  match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/mariazza/saved_games/mariaz_acc_secd_03.yaml')
  #p match_info
  player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_cpu = AlgCpuMariazza.new(player, core, nil)
  #alg_coll = { "Gino B." => alg_cpu } 
  alg_coll = { "Gino B." => nil } 
  segno_num = 0
  rep.replay_match(core, match_info, alg_coll, segno_num)
  #sleep 2
end
