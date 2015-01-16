# briscola5_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'base/gfx_general/base_engine_gfx'
require 'base/gfx_general/gfx_elements'
require 'core_game_briscola5'
require 'games/briscola/briscola_gfx'

##
# Briscola5Gfx implementation
class Briscola5Gfx < BriscolaGfx
  
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @splash_name = File.join(@resource_path, "icons/briscola5.png")
    @core_game = nil
    @algorithm_name = "AlgCpuBriscola5"  
    #core game name (created on base class)
    @core_name_class = 'CoreGameBriscola5'
  end
  
  def build_deck_on_newgiocata
    @deck_main.briscola = false
    @deck_main.build(nil)
    @deck_main.realgame_num_cards =  get_real_numofcards_indeck_initial(@players_on_match.size) 
  end
  
  def get_real_numofcards_indeck_initial(num_of_players)
    return 40 -  ( @core_game.num_of_cards_onhandplayer * num_of_players)
  end
 
  def set_briscola_on_deckmain(carte)
   
  end
  
  
end #end Briscola5Gfx

##############################################################################
##############################################################################

if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,800,530)
  
  # start game using a custom deck
  #deck =  RandomManager.new
  #deck.set_predefined_deck('_Ab,_2c,_Ad,_Ac,_5b,_7b,_3c,_2d,_Rb,_3b,_5s,_2s,_3d,_5d,_Cd,_5c,_As,_Fs,_Fc,_Rc,_Fd,_2b,_4s,_Cb,_6b,_3s,_Rd,_6s,_4c,_6c,_7c,_4d,_Cc,_Fb,_Cs,_7s,_4b,_7d,_Rs,_6d',1)
  #mainwindow.set_custom_deck(deck)
  # end test a custom deck
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('cpu1', nil, :cpu_local, 0)
  players << PlayerOnGame.new('cpu2', nil, :cpu_local, 0)
  players << PlayerOnGame.new('cpu3', nil, :cpu_local, 0)
  players << PlayerOnGame.new('cpu4', nil, :cpu_local, 0)
  
  mainwindow.init_gfx(Briscola5Gfx, players)
  theApp.run
end 