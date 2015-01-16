#file: taken_cards_gfx.rb

$:.unshift File.dirname(__FILE__)

require 'clickable_gfx'

##
# Holds information taken cards gfx
class TakenCardsGfx  < ClickableGfx
  attr_accessor :font_color, :x_txt, :y_txt, 
                :points, :creator, :data_custom
  attr_reader  :image
  
  def initialize(x=0, y=0, image=nil, fntcol=nil, txtx=0, txty=0, points=0, font=nil, hvisb=true)
    super(x,y,99,hvisb,0)
    @image = image
    @font_color = fntcol   
    @x_txt = txtx
    @y_txt = txty
    @points = points
    @font = font
    @creator = nil
    @data_custom = {}
    @width = @image.width
    @height = @image.height
  end
  
  ##
  # Draw card taken gfx object
  def draw_cardtaken(dc)
    return unless @visible
    dc.font = @font
    dc.drawIcon(@image, @pos_x, @pos_y)
    dc.foreground = @font_color
    dc.drawText(@x_txt, @y_txt, @points.to_s )
  end
  
  def on_mouse_lclick_up
    #p 'mouse taste up'
  end
  
  ##
  # User click with left button (callback on each element for @widget_list_clickable)
  def on_mouse_lclick(x,y)
    #p "on_mouse_lclick ct #{x}, #{y}"
    #p point_is_inside?(x,y)
    if @visible and point_is_inside?(x,y)
      @creator.send(:evgfx_click_on_takencard, self)
      return true
    end
    return false
  end
  
end #end TakenCardsGfx
