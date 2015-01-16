# file: core_game_briscola.rb
# handle the briscola game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../briscola/core_game_briscola'
require File.dirname(__FILE__) + '/../../base/core/game_replayer'
require 'alg_cpu_briscolone'

# Class to manage the core card game
class CoreGameBriscolone < CoreGameBriscola
  
  def initialize
    super
    
    @num_of_cards_onhandplayer = 5
    
  end
  
  def new_giocata_distribuite_cards
    # distribuite card to each player
    carte_player = []
    #briscola = @mazzo_gioco.pop 
    #@briscola_in_tav_lbl = briscola
    @round_players.each do |player|
      @num_of_cards_onhandplayer.times{carte_player << @mazzo_gioco.pop}
      #p carte_player
      player.algorithm.onalg_new_giocata( [carte_player].flatten)
      # store cards to each player for check
      @carte_in_mano[player.name] = carte_player
      carte_player = [] # reset array for the next player
      # reset cards taken during the giocata
      @carte_prese[player.name] = [] # uso il nome per rendere la chiave piccola 
      @points_curr_segno[player.name] = 0
    end
    #p @carte_prese
    submit_next_event(:new_mano)
  end
  
  
  ##
  # Tempo di pescare una carta dal mazzo
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
          @log.error "Pesca la briscola che non c'è più"
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
  # Say if the lbl_card is a briscola. 
  # lbl_card: card label (e.g. :_Ab)
  def is_briscola?(lbl_card)
    # in briscolone there is no briscola
    return false
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
  core = CoreGameBriscolone.new
  rep = ReplayerManager.new(log)
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscolone/saved_games/test.yaml')
  ##p match_info
  #player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_coll = { "Gino B." => nil } 
  #segno_num = 0
  #rep.replay_match(core, match_info, alg_coll, segno_num)
  ##sleep 2
end
