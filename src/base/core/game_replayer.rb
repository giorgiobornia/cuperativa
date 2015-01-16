# -*- coding: ISO-8859-1 -*-
#file: game_replayer.rb

$:.unshift File.dirname(__FILE__)
#require 'rubygems'
require 'core_game_base'

##
# Used to record a game in order to re run it
class GameCoreRecorder
  
  def initialize
    @info_match = {}
  end
  
  ##
  # Store information when a new match start
  # players: player array (PlayerOnGame instances)
  # options: core game options
  # game_name: game name (e.g. "Briscola")
  def store_new_match(players, options, game_name)
    @info_match = {}
    pl_names = []
    players.each {|pl| pl_names << pl.name}
    @info_match[:players] = pl_names
    @info_match[:date] = Time.now
    @info_match[:giocate] = [ ] # items like { :deck => [], :first_plx => 0,  :actions => [] }
    @info_match[:game] = {:name => "#{game_name}", :opt => {}
    }
    # set options of the match
    options.each do |k,v|
      @info_match[:game][:opt][k] = v
    end
   
  end
  
  ##
  # Store info about match winner
  def store_end_match(best_pl_segni)
    @info_match[:match_winner] = best_pl_segni
  end
  ##
  # Store info about new giocata
  # deck: deck used
  # first_player: first player in the new giocata
  def store_new_giocata(deck, first_player)
    info_giocata = { 
      :deck => deck.dup, 
      :first_plx => first_player,  
      :actions => [] 
    }
    @info_match[:giocate] << info_giocata
  end
  
  ##
  # Store info about winner of giocata
  def store_end_giocata(info_winner)
    curr_giocata = @info_match[:giocate].last
    curr_giocata[:giocata_winner] = info_winner if curr_giocata
  end
  
  ##
  # Store a player action. An action need to be stored when game_core becomes a new
  # function called from gfx (i.e. alg_player_cardplayed_arr)
  # plname: player name
  # action: action type (:cardplayed, :change_briscola, :declare, :resign)
  def store_player_action(plname, action, *args)
    curr_giocata = @info_match[:giocate].last
    if curr_giocata
      curr_actions = {:pl_name => plname, :type => action, :arg => args}
      curr_giocata[:actions] << curr_actions
    end
  end
  
  ##
  # Save the current info match in a file
  def save_match_to_file(fname)
    #fname_old_loc = File.expand_path(File.join( File.dirname(__FILE__) + "/../..",fname))
    fname_old_loc = fname
    File.open( fname_old_loc, 'w' ) do |out|
      YAML.dump( @info_match, out )
    end
  end
end #end GameCoreRecorder

#####################################################################
#####################################################################
### RandomManager  ##################################################

##
# Manage random function in the core
class RandomManager
  
  def initialize
    # logger
    @log = Log4r::Logger["coregame_log"]
    @deck_to_use = []
    @first_player = 0
    @state = :rnd_fun
    #reset_rnd
  end
  
  ##
  # Reset the manager for using random function for live game
  def reset_rnd
    @log.debug "RandomManager: using random function"
    @state = :rnd_fun
  end
    
  ##
  # Set a predefined deck, this override the default random function 
  # deck_str: deck on string format (e.g. _7c,_5s,_As,_2b,_6c,_2s,_Rb ...)
  # first_player: player index that is returned when get_first_player is called (e.g. 0)
  def set_predefined_deck(deck_str, first_player)
    @log.info "CAUTION: Override current deck (set_predefined_deck) #{first_player}"
    @deck_to_use = deck_str.split(",").collect!{|x| x.to_sym}
    set_predefdeck_withready_deck(@deck_to_use, first_player)
  end
  
  # see set_predefined_deck, but using another format for deck
  # deck: array of cards symbols [_7c, _5s,...]
  def set_predefdeck_withready_deck(deck, first_player)
    @log.debug "RandomManager: set a user defined deck"
    @deck_to_use = deck
    @state = :predefined_game
    @first_player = first_player
  end
  
  def is_predefined_set?
    return @state == :predefined_game ? true : false
  end
  
  ##
  # Provides the deck for a new giocata
  # base_deck: complete unsorted deck
  def get_deck(base_deck)
    case @state
      when :predefined_game
        @log.debug "RM: using predifined deck size: #{@deck_to_use.size}"
        return @deck_to_use.dup
      else
        @log.debug "RM: using rnd deck size: #{base_deck.size}"
        return base_deck.sort_by{ rand }
    end
  end
  
  ##
  # Provides the first player
  # Total number of players
  def get_first_player(num_of_players)
    @log.debug "get first player: state #{@state}, first stored #{@first_player}"
    case @state
      when :predefined_game
        return @first_player
      else
        rand(num_of_players)
    end
  end
  
end

#####################################################################
#####################################################################
### FixAutoplayer  ##################################################

##
# Class used to play a saved game. This can replay a game of an user sending
# automatically all events and forward core callbacks to a gfx engine
class FixAutoplayer < AlgCpuPlayerBase
  attr_accessor :alg_player
  
  def initialize(log, core_game, game_replayer)
    # a :slave don'forward all callback to a gui, a :master forward all callbacks to a gfx
    @cond_auto = :slave
    @log = log
    # instance PlayerOnGame bind
    @alg_player = nil
    @gui_gfx = nil
    # actions queue to be replayed
    @action_queue = []
    # core game
    @core_game = core_game
    # game replayer
    @game_replayer = game_replayer
  end
  
  ##
  # Bind the autoplayer algorithm with a player 
  # player:PlayerOnGame instance
  def bind_player(player)
    @alg_player = player
    @log.info("Autoplayer #{@alg_player.type} bind with #{player.name}")
    @action_queue = []
  end
  
  ##
  # Append an action to the action queue
  # action_det: action detail (e.g. {:type=>:cardplayed, :arg=>["Gino B.", :_Cc]})
  def append_action(action_det)
    @action_queue << action_det
  end
  
  def onalg_have_to_play(player,command_decl_avail)
    if player.type == @alg_player.type
      # now we have to play
      @log.info("[#{@alg_player.type}]onalg_have_to_play-> #{player.name}, cmds(#{command_decl_avail.size})")
      if @action_queue.size > 0
        action = @action_queue.slice!(0)
        @game_replayer.submit_core_action(@alg_player, action)
        # if we call here @core we are still on a callback and we execute the game
        # without living the stack. Maybe we get a stack overflow. To solve it
        # we store the action and we execute it when the callback is terminated
      else
        @log.info("@action_queue for #{player.name} is empty")
      end
    end 
  end
  
end  

#######################################################################
### ReplayerManager  ##################################################
#######################################################################

##
# Class used to manage a replay of a game
class ReplayerManager
  attr_accessor :alg_cpu_contest
  
  @@ACTION_TO_CORE_CALL = {
     :cardplayed => :alg_player_cardplayed,
     :cardplayedarr => :alg_player_cardplayed_arr, 
     :change_briscola => :alg_player_change_briscola, 
     :declare => :alg_player_declare, 
     :resign => :alg_player_resign}
  
  def initialize(log)
    # array of PlayerOnGame
    @players = []
    # key is PlayerOnGame and value is FixAutoplayer
    @alg_name_conn = {}
    # core action queue, an array of couple player action
    @core_execute_queue = []
    # game core
    @core_game = nil
    # when you test only cpu algorithms with recorded match, set it to true
    @alg_cpu_contest = false
    # logger
    @log = log
  end
  
  ##
  # Create array of PlayerOnGame
  # name_array: array with player names (e.g ["toro", "gino"])
  # core: core game
  # alg_coll: hash with algorithm and player name e.g {"Toro" => algcpumariaz}
  def create_players(name_array, core, alg_coll)
    @players = []
    @alg_name_conn = {}
    alg = nil
    pl = nil
    name_array.each_index do |ix|
      alg = alg_coll[name_array[ix]]
      if alg
        # we have already define an aoutmated algorithm, take it
        pl = alg.alg_player
        pl.algorithm = alg
        pl.position = ix
        @log.info("Autoplayer #{pl.type} bind with #{pl.name}")  
      else
        alg = FixAutoplayer.new(@log, core, self) 
        pl = PlayerOnGame.new(name_array[ix], alg, "replicant_#{ix}".to_sym, ix)
        alg.bind_player(pl)
      end
      @players << pl
      @alg_name_conn[pl.name] = alg
    end
  end
  
  ##
  # Fill the action queue on each FixAutoplayer instance
  # curr_segno: segno hash info e.g. {:first_plx=>1, :actions=>[{:type=>:cardplayed, :arg=>["Gino B.", :_Cc]}...
  def build_action_queue(curr_segno)
    #check curr_segno and use @alg_name_conn to fill the action queue
    curr_segno[:actions].each do |action|
      name_player = action[:pl_name]
      alg = @alg_name_conn[name_player]
      #p alg.alg_player.type
      if alg.alg_player.type.to_s =~ /replicant/
        #append action only on replicant algorithm
        alg.append_action({:type => action[:type], :arg => action[:arg]})
      end
    end
  end
  
  ##
  # Submit an action to be processed when the core give the control back to the replayer
  # action: action detail (e.g. {:type=>:cardplayed, :arg=>["Gino B.", :_Cc]})
  # player: player on game
  def submit_core_action(player, action)
    @core_execute_queue <<  [player, action]
  end
  
  ##
  # EXecute the next core action
  def execute_core_action
    # each item of @core_execute_queue is [player, action]
    player, action = @core_execute_queue.slice!(0)
    alg_call = @@ACTION_TO_CORE_CALL[action[:type]]
    case action[:type]
      when :cardplayedarr
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2) 
      when :cardplayed 
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2)
      when :change_briscola
        arg1 = action[:arg][0]; arg2 = action[:arg][1]; arg3 = action[:arg][2]
        @core_game.send(alg_call, player, arg2, arg3)
      when :declare
        arg1 = action[:arg][0]; arg2 = action[:arg][1]
        @core_game.send(alg_call, player, arg2)
      when :resign
        arg1 = action[:arg][0]; arg2 = action[:arg][1] 
        @core_game.send(alg_call, player, arg2)
      else
        @log.error("execute_core_action: Action #{action[:type]} for #{player.name} not recognized")
    end
  end
  
  # Start a replay of match. All actions, player names and core is provided
  # as input. We can replay a game using the description for all players (FixAutoplayer instance)
  # or the user can provides own algorithm binded to a playername. 
  # core: core game
  # match_info: match information to be replayed, usually is yaml load result of 
  # a previous saved game
  # alg_coll: hash with algorithm and player name e.g {"Toro" => algcpumariaz}
  # If you don't want to set algcpu, but only a replayer set "name" => nil
  # segno_toplay: segno index to be replayed
  def replay_match(core, match_info, alg_coll, segno_toplay)
    @core_game = core
    # create players
    create_players(match_info[:players], core, alg_coll)
    # set core options
    match_info[:game][:opt].each do |k,v|
      core.game_opt[k] = v
    end
    #turn off recording (why?, not needed)
    #core.game_opt[:record_game] = false
    # turn on replay
    core.game_opt[:replay_game] = true
    # set info about deck and first player on the random manager
    segni = match_info[:giocate] # catch all giocate, it is an array of hash
    curr_segno = segni[segno_toplay]
    #p curr_segno
    core.rnd_mgr.set_predefdeck_withready_deck(curr_segno[:deck], curr_segno[:first_plx])
    # prepare action queue
    build_action_queue(curr_segno)
    
    if @alg_cpu_contest
      # we are testing a game between algorithms, we can't use @core_execute_queue
      core.suspend_proc_gevents
      core.gui_new_match(@players)
      event_num = core.process_only_one_gevent
      while event_num > 0
        event_num = core.process_only_one_gevent
      end
    else
      # now we can start the game on the core
      core.gui_new_match(@players)
      while @core_execute_queue.size > 0
        execute_core_action
      end
    end
    @log.info("No more action to execute, replay_match terminate")
  end
  
  ##
  # Just continue with the next smazzata or segno after replay_match
  def replaynext_smazzata(core, match_info, alg_coll, segno_toplay)
    @log.info "++++++++++ NEXT SMAZZATA or SEGNO ++++++++++++++++"
    segni = match_info[:giocate] # catch all giocate, it is an array of hash
    curr_segno = segni[segno_toplay]
    #p curr_segno
    core.rnd_mgr.set_predefdeck_withready_deck(curr_segno[:deck], curr_segno[:first_plx])
    # prepare action queue
    build_action_queue(curr_segno)
    if @alg_cpu_contest
      # we are testing a game between algorithms, we can't use @core_execute_queue
      core.suspend_proc_gevents
      core.gui_new_match(@players)
      event_num = core.process_only_one_gevent
      while event_num > 0
        event_num = core.process_only_one_gevent
      end
    else
      # now we can start the game on the core
      core.gui_new_match(@players)
      while @core_execute_queue.size > 0
        execute_core_action
      end
    end
    @log.info("No more action to execute, replay_match terminate")
  end
  
end


if $0 == __FILE__
  
  
end
