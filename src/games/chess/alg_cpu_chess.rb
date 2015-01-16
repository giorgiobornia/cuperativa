#file: alg_cpu_chess.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../../base/core_game_base'
end

require 'huo2'

class AlgCpuChess 
  
  def initialize(player, coregame, timeout_handler)
    @timeout_handler = timeout_handler
    @alg_player = player
    @log = Log4r::Logger["coregame_log"]
    @core_game = coregame
  end
  
  def onalg_new_match(your_color, opponent_name)
    @opponent_name = opponent_name
    @alg_color = your_color
    huoChess_new_depth_2 = HuoChess_main.new;
    huoChess_new_depth_4 = HuoChess_main.new;
    huoChess_new_depth_6 = HuoChess_main.new;
    huoChess_new_depth_8 = HuoChess_main.new;
    huoChess_new_depth_10 = HuoChess_main.new;
    huoChess_new_depth_12 = HuoChess_main.new;
    huoChess_new_depth_14 = HuoChess_main.new;
    huoChess_new_depth_16 = HuoChess_main.new;
    huoChess_new_depth_18 = HuoChess_main.new;
    huoChess_new_depth_20 = HuoChess_main.new;
    
    @huo_alg = HuoChess_main.new
    @huo_alg.set_huo_deph(huoChess_new_depth_2,huoChess_new_depth_4,huoChess_new_depth_6,huoChess_new_depth_8,
      huoChess_new_depth_10, huoChess_new_depth_12, huoChess_new_depth_14, huoChess_new_depth_16, 
      huoChess_new_depth_18, huoChess_new_depth_20)
      
    @huo_alg.set_initial_color_of_hy(your_color)
    @log.debug("Player #{@alg_player.name} is #{your_color}")
    @huo_alg.init_game(@alg_player.name)
  end
  
  def onalg_have_to_move(player)
    if player == @alg_player
      @log.debug("onalg_have_to_move cpu alg: #{@alg_player.name}")
      if @timeout_handler
        @timeout_handler.registerTimeout(@option_gfx[:timeout_haveplay], :onTimeoutAlgorithmHaveToPlay, self)
        # suspend core event process until timeout
        # this is used to sloow down the algorithm play
        @core_game.suspend_proc_gevents
        
      else
        # no wait for gfx stuff, continue immediately to play
        alg_make_move
      end
      # continue on onTimeoutHaveToPlay
    end 
  end
  
  # color: :white :black
  # start_x, start_y, end_x, end_y : integer 0..7
  def onalg_player_has_moved(player,color, start_x, start_y, end_x, end_y)
    if player != @alg_player
      start_col = BoardInfoItem.column_to_s(start_x).upcase
      start_rank = start_y + 1
      fin_col = BoardInfoItem.column_to_s(end_x).upcase
      fin_rank = end_y + 1
      @huo_alg.set_human_move(start_col, start_rank, fin_col, fin_rank)
    end
  end
  
  ##
  # onTimeoutHaveToPlay: after wait a little for gfx purpose the algorithm make a move
  def onTimeoutAlgorithmHaveToPlay
    alg_make_move
    # restore event process
    @core_game.continue_process_events if @core_game
  end
  
  def alg_make_move
    move_info_arr = @huo_alg.make_hy_move
    if move_info_arr.size == 4
      #p move_info_arr
      start_x = BoardInfoItem.colupstr_to_int( move_info_arr[0])
      start_y = move_info_arr[1] - 1 
      end_x = BoardInfoItem.colupstr_to_int( move_info_arr[2])
      end_y = move_info_arr[3] - 1
      @core_game.alg_player_move(@alg_player, @alg_color, start_x, start_y, end_x, end_y)
    else
      @log.error('huo invalid move')
    end
  end
end