#file: player_on_game.rb


##
# Class to manage information about the card player
class PlayerOnGame
  attr_accessor :name, :algorithm, :type, :position
  
  def initialize(nome, alg, tipo, pos)
    @name = nome
    # algoritmo di gioco
    @algorithm = alg
    @type =  tipo# :human_local, :human_remote, :cpu_local
    @position = pos
  end
   
end
