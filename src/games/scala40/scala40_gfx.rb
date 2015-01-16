# scala40_gfx.rb

$:.unshift File.dirname(__FILE__)

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'base/gfx_general/gfx_elements'
require 'base/gfx_general/base_engine_gfx'
require 'core_game_scala40'

##
# Spazzino Gfx implementation
class Scala40Gfx < BaseEngineGfx
  
  INFO_GFX_COORD = { :x_top_opp_lx => 30, :y_top_opp_lx => 60, 
     :y_off_plgui_lx => 15, :y_off_plg_card => 10
  }
  
  # constructor 
  # parent_wnd : application gui     
  def initialize(parent_wnd)
    super(parent_wnd)
    
    @using_rotated_card = false
    @deck_france = true
    @core_game = nil
    @splash_name = File.join(@resource_path, "icons/scala40_title.png")

  end
 
end

if $0 == __FILE__
end
 

