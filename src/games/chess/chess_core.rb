#file: chess_core.rb

$:.unshift File.dirname(__FILE__)

require File.dirname(__FILE__) + '/../../base/mod_core_queue'
require 'Board'
require 'alg_cpu_chess'

if $0 == __FILE__
  require File.dirname(__FILE__) + '/../../base/player_on_game'
end


class ChessCore
  attr_reader :board_core
  
  include CoreGameQueueHandler
  
  def initialize
    # board information core
    @board_core = nil
    @proc_queue = []
    @suspend_queue_proc = false
    @num_of_suspend = 0
    @log = Log4r::Logger["coregame_log"]
  end
  
  ##
  # Main app inform about starting a new match
  # players: array of PlayerOnGame
  def gui_new_match(players, options)
    @match_state = :match_started
    @board_core = Board.new
    @board_core.init_pos
    @players = players
    submit_next_event(:new_match)
  end
  
  def new_match
    @log.debug "new_match"
    
    @player_white = @players[0]
    @player_black = @players[1]
    @player_white.algorithm.onalg_new_match(:white, @player_black.name)
    @player_black.algorithm.onalg_new_match(:black, @player_white.name)
    
    @log.debug "#{@player_white.name} (white) - #{@player_black.name} (black)"
    
    
    #name_players = []
    #@players.each {|pl| name_players << pl.name}
    #inform_viewers(:onalg_new_match, @players.size, name_players)
    
    submit_next_event(:make_move_white)
  end
  
  def make_move_white
    @player_on_turn = @player_white
    @last_moved_info = {}
    @player_white.algorithm.onalg_have_to_move(@player_white)
  end
  
  def make_move_black
    @player_on_turn = @player_black
    @last_moved_info = {}
    @player_black.algorithm.onalg_have_to_move(@player_black)
  end
  
  def has_moved
    player = @last_moved_info[:player]
    color= @last_moved_info[:color]
    start_x= @last_moved_info[:start_x]
    start_y= @last_moved_info[:start_y]
    end_x= @last_moved_info[:end_x]
    end_y= @last_moved_info[:end_y]
    @log.debug "Player #{player.name} has moved: #{start_x},#{start_y} - #{end_x}, #{end_y}"
    @player_white.algorithm.onalg_player_has_moved(player,color, start_x, start_y, end_x, end_y)
    @player_black.algorithm.onalg_player_has_moved(player,color, start_x, start_y, end_x, end_y)
    if player == @player_white
      submit_next_event(:make_move_white)
    elsif player == @player_black
      submit_next_event(:make_move_black)
    end
  end
  
  def alg_player_move(player, color, start_x, start_y, end_x, end_y)
    if @player_on_turn != player
      @log.error("player not in turn")
      return
    end
    @last_moved_info = {:player => player, :color => color, 
       :start_x => start_x, :start_y => start_y, :end_x => end_x, :end_y => end_y}
    submit_next_event(:has_moved)
  end
    
end

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  core = ChessCore.new
  player1 = PlayerOnGame.new("Test1", nil, :cpu_alg, 0)
  player1.algorithm = AlgCpuChess.new(player1, core, nil)
  player2 = PlayerOnGame.new("Test2", nil, :cpu_alg, 1)
  player2.algorithm = AlgCpuChess.new(player2, core, nil)
  arr_players = [player1,player2]
  
  options = {}  
  core.gui_new_match(arr_players, options)
  event_num = core.process_only_one_gevent
  while event_num > 0
    event_num = core.process_only_one_gevent
  end
end