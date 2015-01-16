# -*- coding: ISO-8859-1 -*-
# file: alg_cpu_tombolon.rb

if $0 == __FILE__
  require 'rubygems'
  require File.dirname(__FILE__) + '/../../base/core_game_base'
end

##################################################### 
##################################################### AlgCpuTombolon
#####################################################

##
# Class used to play automatically
class AlgCpuTombolon < AlgCpuSpazzino
  
  def initialize(player, coregame, cup_gui)
    super(player, coregame, cup_gui)
    @num_cards_on_hand = 4
  end
  
  def onalg_new_giocata(carte_player)
    @num_of_strib = 1
    @num_cards_on_hand = 4
    super(carte_player)
  end
  
  def onalg_pesca_carta(carte_player)
    @num_of_strib += 1
    if @num_of_strib >= 4
      @num_cards_on_hand = 6
    end
    if carte_player.size != @num_cards_on_hand
      @log.error "[ALG] programming error: number of cards picked unexpected"
    end
    super(carte_player)
  end
  
end #end AlgCpuTombolon

if $0 == __FILE__
 
end
