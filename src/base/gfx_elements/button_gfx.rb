#file: button_gfx.rb

$:.unshift File.dirname(__FILE__)

require 'clickable_gfx'

##
# Holds information about  Button
class ButtonGfx < ClickableGfx
  attr_accessor :caption, :font 
  
  def initialize(caption="", x=0, y=0, zord=0, visb=true, rot=false, font=0)
    super(x,y,zord,visb,rot)
    @caption = caption
    @font=font
    @border_col = Fox.FXRGB(250, 250, 240)
    @text_col = Fox.FXRGB(255, 255, 255)
  end
  
  def get_height
    @height = @font.getTextHeight(@caption) + 10
    return @height 
  end
  
  def get_width
    @width = @font.getTextWidth(@caption) + 10
    @width = 70 if @width < 70
    return @width 
  end
  
  def draw(dc)
    # posx is set to the middle of the parent, we have to center it
    width_text = @font.getTextWidth(@caption)
    @width = get_width
    @height = get_height
    @pos_x = @pos_x - @width / 2
    # draw the button
    dc.foreground = @border_col
    dc.drawRectangle(@pos_x, @pos_y, @width, @height)
    # draw the text
    dc.font = @font
    dc.foreground = @text_col
    dc.drawText(@pos_x + (@width - width_text) / 2, @pos_y + @height - 5, @caption)
  end
  
end
