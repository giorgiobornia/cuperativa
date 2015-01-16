#file: turn_marker_gfx.rb

##
# Holds information about player mark that have to play
class TurnMarkerGfx
  attr_accessor :pos_x, :pos_y, :width, :height, :visible, :color
  def initialize(x=0, y=0, w=0, h=0, color=0, hvisb=true)
    @pos_x = x       # x position
    @pos_y = y       # y position
    @width = w
    @height = h   
    @visible = hvisb  # visible flag
    @color = color
  end
  
  ##
  # Draw player marker control
  def draw_marker(dc)
    return unless @visible
    dc.foreground = @color
    dc.drawRectangle(@pos_x, @pos_y, @width, @height ) 
    dc.fillRectangle(@pos_x, @pos_y, @width, @height )
  end
  
end
