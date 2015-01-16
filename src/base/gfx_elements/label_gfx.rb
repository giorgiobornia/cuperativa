#file: label_gfx.rb

##
# Holds information about labels on the canvas
class LabelGfx
  attr_accessor :pos_x, :pos_y, :text, :font, :visible, :font_color, :info_tag
  def initialize(x=0, y=0, testo="",font = nil, fntcol=nil, visb=true)
    @pos_x = x       # x position
    @pos_y = y       # y position
    @text = testo    # label text
    @visible = visb  # visible flag
    @font = font     # label font
    @font_color = fntcol
    @info_tag = {}  
  end
  
  ##
  # Draw the control label
  def draw_label(dc)
    return unless @visible
    dc.font = @font
    dc.foreground = @font_color
    dc.drawText(@pos_x, @pos_y, @text )
  end
  
end
