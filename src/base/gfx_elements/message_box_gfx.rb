#file: message_box_gfx.rb

##
# Message box control for the canvas
class MessageBoxGfx
  attr_accessor :pos_x, :pos_y, :width, :height, :visible, :color, :z_order
  attr_accessor :caption, :text, :creator, :blocking
  
  def initialize(caption = "", text = "", x=0, y=0, w=0, h=0, font = 0, color=0, hvisb=true)
    @pos_x = x       # x position
    @pos_y = y       # y position
    @width = w
    @height = h   
    @visible = hvisb  # visible flag
    @color = color
    @text = text
    @caption = caption
    @font_text = font
    @bt_ok = ButtonGfx.new("OK", x + w/2, y+h-30)
    @bt_ok.font = font
    @bckcolor = Fox.FXRGB(34, 20, 90)
    @border_col = Fox.FXRGB(250, 250, 240)
    @caption_col = Fox.FXRGB(250, 42, 23)
    @text_col = Fox.FXRGB(255, 255, 255)
    @z_order = 0
    @creator = nil
    @blocking = false
  end
  
  def set_visible(val)
    @visible = val
  end
  
  ##
  # Draw the control
  def draw(dc)
    #check the text
    intra_line_y = 5
    cap_h = 30
    
    #check if the text fit the size
    lines = @text.split("\n")
    line1 = lines[0]
    hh_line = @font_text.getTextHeight(line1)
    max = 0
    lines.each do |l|
      # search the max width
      wl = @font_text.getTextWidth(l)
      max = wl if wl > max
    end
    hh_tot = (hh_line + intra_line_y) * lines.size 
    
    w_purp = max + 20
    h_purp = hh_tot + cap_h + 30 + @bt_ok.get_height
    # adjust dimension
    @height = h_purp if h_purp > 200
    @width = w_purp if w_purp > 200
    
    # border
    dc.foreground = @border_col
    dc.drawRectangle(@pos_x, @pos_y, @width, @height)
    
    # caption
    dc.foreground = @caption_col
    dc.fillRectangle(@pos_x + 1, @pos_y + 1, @width - 2, cap_h )
    
    posx_capt = @pos_x + (@width - @font_text.getTextWidth(@caption)) / 2 
    dc.font = @font_text
    dc.foreground = @text_col
    dc.drawText(posx_capt, @pos_y + cap_h - 5, @caption)
    
    dc.foreground = @border_col
    dc.drawRectangle(@pos_x + 1, @pos_y+1, @width-2, cap_h)
    
    # body
    dc.foreground = @bckcolor
    dc.fillRectangle(@pos_x + 2, @pos_y + 2 + cap_h, @width - 4, @height - (4 + cap_h ))
    dc.font = @font_text
    dc.foreground = @text_col
    posx_line = (@width - max) / 2 + @pos_x
    posy_line =  @pos_y +  cap_h + 10 + hh_line
    lines.each do |l|
      dc.drawText(posx_line, posy_line, l)
      posy_line += intra_line_y + hh_line
    end
    
    #draw ok button
    @bt_ok.pos_x = @pos_x + @width / 2
    @bt_ok.pos_y = @pos_y + @height - 40
    @bt_ok.draw(dc)
  end
  
  def on_mouse_lclick_up
  end
  
  ##
  # User click with left button
  def on_mouse_lclick(x,y)
    if @bt_ok.point_is_inside?(x,y)
      @visible = false
      @creator.send(:evgfx_click_on_msgbox_ok, self) if @creator
      return true
    end
  end
end
