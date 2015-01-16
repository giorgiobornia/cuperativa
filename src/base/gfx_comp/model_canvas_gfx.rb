#file : model_canvas_gfx.rb


##
# Holds information about game scene
class ModelCanvasGfx
  attr_accessor :info
  def initialize
    reset
  end
  
  def reset
    @info = {
      :canvas => {:width => 0, :height => 0}, :info_gfx_coord => {}, :deck_info => {},
      :card_played_pos => [], :card_played_pos_end => {}, 
    }
  end
  

  ##
  # Provides information about label player
  def info_label_player_get(player_sym)
    res = nil
    if @info[player_sym]
      res = @info[player_sym][:label]
    end
    return res
  end
  
  ##
  # Set information about label player
  def info_label_player_set(player_sym, label_info)
    unless @info[player_sym]
      @info[player_sym] = {}
    end
    @info[player_sym][:label] = label_info
  end
 
end
