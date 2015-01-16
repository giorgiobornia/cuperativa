#file :clickable_gfx.rb

$:.unshift File.dirname(__FILE__)

##
# Generic clickable widget
class ClickableGfx
  attr_accessor :pos_x, :pos_y,  :visible, :rotated, :z_order
  
  def initialize(x=0, y=0, zord=0, visb=true, rot=false )
    @pos_x = x       # x position
    @pos_y = y       # y position
    @visible = visb  # visible flag
    @rotated = rot   # rotated flag
    @z_order = zord
    @width = 0
    @height = 0
  end
  
  ##
  # Check if the point x,y is inside the card, in this case returns true, 
  # otherwise false
  def point_is_inside?(x,y)
    if x > @pos_x && x < (@pos_x + @width) &&
       y > @pos_y && y < (@pos_y + @height)
      binside = true
    else
      binside = false
    end
    return binside
  end
  
end
