# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_briscola5.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../briscola/core_game_briscola'
end

##################################################### 
##################################################### AlgCpuBriscola5
#####################################################

##
# Class used to play  automatically
class AlgCpuBriscola5 < AlgCpuBriscola
  attr_accessor :level_alg, :alg_player
  ##
  # Initialize algorithm of player
  # player: player that use this algorithm instance
  # coregame: core game instance used to notify game changes
  def initialize(player, coregame, cup_gui)
    super
  end
  
  def onalg_new_giocata(carte_player)
    ["b", "d", "s", "c"].each do |segno|
      @strozzi_on_suite[segno] = 2
    end
    
    @num_cards_on_deck = 40 - 5 * @players.size 
   
    str_card = ""
    @cards_on_hand = []
    carte_player.each do |card_lbl| 
      @cards_on_hand << card_lbl
    end
    build_information_for_calling_stage
    @cards_on_hand.each{|card| str_card << "#{card.to_s} "}
    @players.each do |pl|
      @points_segno[pl.name] = 0
    end 
    @log.info "#{@alg_player.name} cards: #{str_card}"
  end
  
  def build_information_for_calling_stage
    points_for_call = {:B => 0, :C => 0, :D => 0, :S => 0 }
    cards_on_segno = {:B => [], :C => [], :D => [], :S => [] }
    @cards_on_hand.each do |card_lbl|
      segno = @deck_info[card_lbl][:segno]
      points_for_call[segno] += @deck_info[card_lbl][:points]
      cards_on_segno[segno] << card_lbl 
    end
    #p cards_on_segno
    max_info = points_for_call.max {|a,b| a[1] <=> b[1]}
    segno_max =  max_info[0] 
    cards_rev_max =  build_missed_seq_tocall( cards_on_segno[segno_max])
    maxpoints_call = calc_maxpoint_tocall(cards_rev_max, max_info[1])
    call_seq_fin = cut_call_seq(cards_rev_max, max_info[1], maxpoints_call)
    @info_for_call = {:segno => segno_max, :call_seq => call_seq_fin, :maxpoints_call => maxpoints_call}
  end
  
  def cut_call_seq(call_seq, points_on_hand, maxpoints_call)
    #p points_on_hand
    res = []
    cut_point = -1
    if maxpoints_call == 61
      if call_seq[0] == :asso 
        cut_point = 2
      elsif call_seq[0] == :tre and points_on_hand < 18
        cut_point = 3
      end
    end
    res = call_seq[0..cut_point]
    return res
  end
  
  def calc_maxpoint_tocall(call_seq, points_on_hand)
    maxpoints_call = 61
    add_points = points_on_hand - 18 
    if call_seq.first != :asso and add_points > 0
      maxpoints_call += add_points + 10 - call_seq.size
    end
    return maxpoints_call
  end
  
  def build_missed_seq_tocall(cards_on_segno)
    #p cards_on_segno
    #p ss = @deck_info[cards_on_segno[0]][:symb]
    seq_result = []
    card_seq = [:asso, :tre, :re, :cav, :fan, :set, :sei, :cin, :qua, :due]
    #p card_seq.index(ss)
    card_seq.each do |seq|
      pres = cards_on_segno.select{|v| @deck_info[v][:symb] == seq}
      if pres.size == 0
        seq_result << seq 
      end
    end
    return seq_result
  end
    
  def onalg_gameinfo(args)
    #p args
    #begin
      send args[:infoitem], args[:det]
    #rescue
    #  @log.error "onalg_gameinfo handler #{$!}"
    #end
  end
  
  
  
  def build_declaration(curr_card_called, current_points_called)
    info_card_type = {:asso => 'A', :due => '2', :tre => '3', :qua => '4', :cin => '5', :sei => '6', :set => '7', :fan => 'F', :cav => 'C',  :re => 'R'}
    info_card_segno = {:B => 'b', :C => 'c', :D => 'd', :S => 's' }
    segno = @info_for_call[:segno]
    #p curr_card_called 
    card_type = info_card_type[curr_card_called]
    card_segno = info_card_segno[segno]
    card_lbl = "_#{card_type}#{card_segno}"
    card_called_sym = card_lbl.to_sym
    resp = {:action => :declaration, 
    :det => {:player_name => @alg_player.name, :card => card_called_sym  }}
    return resp
  end
  
  def build_response_to(curr_card_called, current_points_called)
    resp = {:action => :called, :det => {:player_name => @alg_player.name }}
    #p curr_card_called
    #p @info_for_call
    is_ok, call_seq, points_called = check_if_user_call(curr_card_called,current_points_called)
    #p is_ok
    #p call_seq
    #p points_called
    if is_ok
      resp[:det][:card_rank] = call_seq
      resp[:det][:points] = points_called
      resp[:det][:type] = :has_called
    else
      resp[:det][:type] = :has_fold
    end
    return resp
  end
  
  def check_if_user_call(curr_card_called,current_points_called)
    is_ok = false
    call_seq = :nothing
    points_called = 61
    points_seq = {:nothing => 100, :asso => 12, :tre => 11, :re => 10, :cav => 9, :fan => 8, :set => 7, :sei => 6, :cin => 5, :qua => 1, :due => 0}
    #p @info_for_call
    rank_seq_curr_called = points_seq[curr_card_called]
    if current_points_called == 61
      @info_for_call[:call_seq].each do |seq_item|
        rank_seq_item = points_seq[seq_item]
        if rank_seq_item < rank_seq_curr_called
          is_ok = true
          call_seq = seq_item
          break
        end
      end
    end
    
    #check for call points
    if !is_ok 
      seq_item = @info_for_call[:call_seq].last
      rank_seq_item = points_seq[seq_item]
      if rank_seq_item < 5 and rank_seq_curr_called < 5
        # card called is 4 or 2, call points
        if @info_for_call[:maxpoints_call] > current_points_called
          is_ok = true
          call_seq = seq_item
          points_called = current_points_called + 1
        end
      end
    end#end if !is_ok 
    
    return [is_ok, call_seq, points_called]
  end
  
  ####### chiamata callbacks 
  def have_to_call(args)
    #@log.debug("Have to call: #{args}")
    #p args
    player_info =  args[:player]
    current_candidate = args[:player_owner_call]
    if @alg_player.name == player_info[:player_name] and
      @alg_player.name != current_candidate 
      @log.debug "[ALG] #{@alg_player.name} has to call, curent candidate #{current_candidate}"
      response = build_response_to(args[:card_rank], args[:points])
      @core_game.alg_player_gameinfo(response)
    end
  end
  
  def has_called(args)
    #@log.debug("[ALG] Has called: #{args}")
  end
  
  def declaration_needed(args)
    if @alg_player.name == args[:player]
      @log.debug("[ALG] Declaration needed for #{@alg_player.name}")
      response = build_declaration(args[:card_rank], args[:points])
      @core_game.alg_player_gameinfo(response)
    end
  end

  def has_declared(args)
    #p args
    @calling_player = args[:player]
    @briscola = args[:called_card]
    @socio_player = nil
  end
  
  def begin_calling_stage(args)
  end
  
  def end_calling_stage(args)
  end
  
end #end AlgCpuBriscola5

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_briscola5'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameBriscola5.new
  # rep = ReplayerManager.new(log)
  # match_info = YAML::load_file(File.dirname(__FILE__) + '/../../test/briscola/saved_games/alg_flaw_02.yaml')
  # #p match_info
  # player1 = PlayerOnGame.new("Gino B.", nil, :cpu_alg, 0)
  # alg_cpu1 = AlgCpuBriscola.new(player1, core)
  
  # player2 = PlayerOnGame.new("Toro", nil, :cpu_alg, 0)
  # alg_cpu2 = AlgCpuBriscola.new(player2, core)
  # alg_cpu2.level_alg = :master
  
  # alg_coll = { "Gino B." => alg_cpu1, "Toro" => alg_cpu2 } 
  # segno_num = 0
  # rep.alg_cpu_contest = true
  # rep.replay_match(core, match_info, alg_coll, segno_num)
end
