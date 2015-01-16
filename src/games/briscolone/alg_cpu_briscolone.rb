# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_briscolone.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../briscola/core_game_briscola'
end

##################################################### 
##################################################### AlgCpuBriscolone
#####################################################

##
# Class used to play  automatically
class AlgCpuBriscolone < AlgCpuBriscola
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
    carte_player.each do |card| 
      @cards_on_hand << card
    end
    @cards_on_hand.each{|card| str_card << "#{card.to_s} "}
    @players.each do |pl|
      @points_segno[pl.name] = 0
    end 
    @log.info "#{@alg_player.name} cards: #{str_card}"
  end
  
  
end #end AlgCpuBriscola

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  require 'core_game_briscolone'
  
  #require 'ruby-debug' # funziona con 0.9.3, con la versione 0.1.0 no
  #Debugger.start
  #debugger
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  core = CoreGameBriscolone.new
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
