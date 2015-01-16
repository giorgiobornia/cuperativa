# file: core_game_briscola5.rb
# handle the briscola game engine
#

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../briscola/core_game_briscola'
require File.dirname(__FILE__) + '/../../base/core/game_replayer'
require 'alg_cpu_briscola5'
require 'chiamata_mgr'

# Class to manage the core card game
class CoreGameBriscola5 < CoreGameBriscola
  
  def initialize
    super
    
    @game_opt[:num_of_players] = 5
    @num_of_cards_onhandplayer = 8
    # NOTE: @briscola_in_tav_lbl  => called card
  end
  
  def new_giocata_distribuite_cards
    # distribuite card to each player
    carte_player = []
    #briscola = @mazzo_gioco.pop 
    #@briscola_in_tav_lbl = @mazzo_gioco.last 
    
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
    submit_next_event(:begin_calling_stage)
  end
  
  def set_specific_options(options)
    p options[:games]
    #if options[:games][:briscola]
      #opt_briscola = options[:games][:briscola]
      #if opt_briscola[:num_segni_match]
        #@game_opt[:num_segni_match] = opt_briscola[:num_segni_match][:val]
      #end
      #if opt_briscola[:target_points_segno]
        #@game_opt[:target_points_segno] = opt_briscola[:target_points_segno][:val]
      #end
    #end
    #p @game_opt[:num_segni_match]
    exit
  end
  
  def new_match
    @points_curr_match = {}
    @players.each do |player| 
      @points_curr_match[player.name] = 0 
    end
    super
  end
  
  def mano_end
    super
    @caller_team[:game_point] = 0
    @opponent_team[:game_point] = 0
    @caller_team[:players].each{|name| @caller_team[:game_point] += @points_curr_segno[name]}
    @opponent_team[:players].each{|name| @opponent_team[:game_point] += @points_curr_segno[name]}
    @log.debug "Punti team chiamante: #{@caller_team[:game_point]} punti team altri: #{@opponent_team[:game_point]}"
  end
  
  def giocata_end_calc_bestpoints
    #p @calling_info
    best_points = {:winners => [], :losers =>[], :points_win => 0, :points_lose => 0}
    p_c = 2
    p_s = 1
    p_a = -1
    if @caller_team[:game_point] >= @calling_info[:target_points]
      # caller team wins
      @caller_team[:players].each{|name| best_points[:winners] << name }
      @opponent_team[:players].each{|name| best_points[:losers] << name }
      best_points[:points_win] = @caller_team[:game_point]
      best_points[:points_lose] =  @opponent_team[:game_point]
    else
      @caller_team[:players].each{|name| best_points[:losers] << name }
      @opponent_team[:players].each{|name| best_points[:winners] << name }
      best_points[:points_win] = @opponent_team[:game_point]
      best_points[:points_lose] =  @caller_team[:game_point]
      p_c = -2
      p_s = -1
      p_a = +1
    end
    if @calling_info[:target_points] > 70
      p_c = 2 * p_c
      p_s = 2 * p_s
      p_a = 2 * p_a
    end
    chiamante = @caller_team[:players][0]
    socio = @caller_team[:players][1]
    @points_curr_match[chiamante] += p_c
    @points_curr_match[socio] += p_s
    @opponent_team[:players].each do |pl_name_opp|
      @points_curr_match[pl_name_opp] += p_a
    end
    #p @points_curr_match
    tot_p =  @points_curr_match.values.inject(0){|sum, n| sum + n}
    if tot_p != 0
      @log.error("Error on player points: sum is not 0")
    end
    best_points[:current_match_stand] = @points_curr_match
    #p best_points
    return best_points
  end
  
  
  #################### calling stage #############
  
  ##
  # Start the phase when all players have to call the briscola
  def begin_calling_stage
    @log.debug "[CORE] begin_calling_stage"
    @calling_info = {}
    
    @chiamata_mgr = ChiamataManager.new
    @chiamata_mgr.intit_players(@round_players)
    
    @players.each{|pl| pl.algorithm.onalg_gameinfo({:infoitem => :begin_calling_stage}) }
    
    #inform_viewers(:onalg_have_to_play,player_onturn.name)
    submit_next_event(:calling_stage_do)
  end
  
  def end_calling_stage
    @briscola_in_tav_lbl = @calling_info[:briscola_card]
    @chiamata_mgr = nil
    #p @calling_info
    @log.debug "[CORE] calling stage is terminated, card called #{@briscola_in_tav_lbl}, points: #{@calling_info[:target_points]}"
    @players.each{|pl| pl.algorithm.onalg_gameinfo({:infoitem => :end_calling_stage}) }
    
    build_player_teams()
    
    submit_next_event(:new_mano)
  end
  
  def build_player_teams
    #p @calling_info
    caller_player = @calling_info[:player_name]
    socio = who_owns_cardlbl(@calling_info[:briscola_card])
    if socio == nil
      @log.error("[CORE] Socio unknown, programming error")
      return
    end 
    @log.debug("#{caller_player} and #{socio} are playing together")
    @caller_team = {:players => [caller_player, socio], :game_point => 0}
    opp_players = []
    @round_players.each do |player|
      if player.name != caller_player and
        player.name != socio
        opp_players << player.name
      end
    end
    @opponent_team = {:players => opp_players, :game_point => 0}
    #p @caller_team
    #p @opponent_team
  end
  
  def who_owns_cardlbl(card_lbl)
    @round_players.each do |player|
      ix = @carte_in_mano[player.name].index(card_lbl)
      if ix != nil
        return player.name if ix >= 0
      end
    end
    return nil
  end
  
  def calling_stage_do
    #p "calling_stage_do START"
    if @chiamata_mgr == nil
      @log.warn "Programming error, calling stage not initialized"
      return
    end
    if @chiamata_mgr.is_calling_terminate?
      @calling_info = @chiamata_mgr.get_calling_info
      submit_next_event(:end_calling_stage)
      return
    end
    
    gameinfo_arg = {:infoitem => @chiamata_mgr.get_action_msg, 
                   :det =>@chiamata_mgr.get_detail_msg}
                   
    if gameinfo_arg[:infoitem] == nil
      @log.warn "calling_stage_do: Nothing to signal"
      return
    end
                   
    @players.each do |pl|
      pl.algorithm.onalg_gameinfo(gameinfo_arg)
    end
    
    @chiamata_mgr.do_next_step
    
    if @chiamata_mgr.repeat_proc?
      submit_next_event(:calling_stage_do)
    end
    
    #p "calling_stage_do END"
  end
  
  def alg_player_gameinfo(arg)
    @chiamata_mgr.player_gameinfo(arg)
    
    submit_next_event(:calling_stage_do)
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
  core = CoreGameBriscola5.new
  rep = ReplayerManager.new(log)
  #match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscola5/saved_games/test.yaml')
  ##p match_info
  #player = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  #alg_coll = { "Gino B." => nil } 
  #segno_num = 0
  #rep.replay_match(core, match_info, alg_coll, segno_num)
  ##sleep 2
end
