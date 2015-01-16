#file: card_gfx.rb

$:.unshift File.dirname(__FILE__)

require 'clickable_gfx'

##
# Holds information about the card to be displayed in the static scene
class CardGfx < ClickableGfx
  attr_accessor :blit_reverse, :originate_multchoice, :cd_data
  attr_accessor :data_info, :type, :vel_x, :vel_y, :anistate, :z_order
  attr_reader  :image, :lbl
  
  def initialize(creator=nil, x=0, y=0, img=nil, lbl=:not_def, zord=0, visb=true, rot=false )
    super(x,y,zord,visb,rot)
    @creator = creator
    @image = img     # image
    @lbl = lbl       # card label name (e.g. bA, c3, ...)
    @z_order = zord + 10
    @vel_x = 0
    @vel_y = 0
    @blit_reverse = false
    @data_info = nil
    @type = nil
    @width = @image.width
    @height = @image.height
    @border_active = false
    @originate_multchoice = false
    @cd_selected = false
    @anistate = :static
    # used to store custom data
    @cd_data = {}
  end
  
  ##
  # Draw this card control
  def draw_card(dc)
    return unless @visible
    if @blit_reverse
      # use another blitter for drawing (default 3)
      orig_blitter =  dc.function 
      dc.function = BLT_SRC_XOR_DST
      # under windows BLT_SRC_XOR_DST is not implemented for drawIcon (look on file FXDCWindow.cpp)
      #dc.drawIcon(@image, @pos_x, @pos_y) 
      dc.drawImage(@image, @pos_x, @pos_y)
      dc.function = orig_blitter
    else
      if @border_active and @border_color
        dc.foreground = @border_color
        dc.drawRectangle(@pos_x - 1, @pos_y - 1, @width + 2, @height + 2 )
        dc.drawRectangle(@pos_x - 3, @pos_y - 3, @width + 6, @height + 6 )
        dc.drawRectangle(@pos_x - 5, @pos_y - 5, @width + 10, @height + 10 )
        dc.drawIcon(@image, @pos_x, @pos_y)        
      else
        dc.drawIcon(@image, @pos_x, @pos_y)
      end
    end
  end
  
  ##
  # Return tru if this card is selected
  def is_selected?
    return @cd_selected
  end
  
  ##
  # Return true if this card has originat multiple choice
  def originate_multiplechoice?
    return @originate_multchoice
  end
  
  ##
  # Activate border selection
  # curr_color: color of the border
  def activate_border_sel(curr_color)
    @border_active = true
    @border_color = curr_color
    unless @border_color
      @border_active = false
      @cd_selected = false
      return
    end
    @cd_selected = true
  end
  
  ##
  # Deactivate border selection
  def deactivate_border_sel()
    @border_active = false
    @cd_selected = false
  end
  
  ##
  # Image and label have to be consinstent, allow to change it only together
  def change_image(img, lbl)
    @image = img 
    @lbl = lbl
  end
  
  ##
  # Set velocity
  def set_vel_xy(vel_x, vel_y)
    #p "set_vel_xy: #{vel_x}, #{vel_y}" 
    @vel_x = vel_x
    @vel_y = vel_y
  end
  
  ##
  # Update position based on velocity
  def update_pos_xy(tt)
    @pos_x += @vel_x * tt 
    @pos_y += @vel_y * tt
  end
  
  def update_pos_xy_factor(tt, factor)
    @pos_x += @vel_x * tt / factor
    @pos_y += @vel_y * tt / factor
  end
  
  ##
  # Update position based on velocity
  def update_pos_x(tt)
    @pos_x += @vel_x * tt 
  end
  
  def update_pos_x_factor(tt, factor)
    @pos_x += (@vel_x * tt) / factor
  end
  
  ##
  # Update position based on velocity
  def update_pos_y(tt)
    @pos_y += @vel_y * tt 
  end
  
  def update_pos_y_factor(tt, factor)
    @pos_y += (@vel_y * tt) / factor
  end
  
  def on_mouse_lclick_up
  end
  
  ##
  # User click with left button
  def on_mouse_lclick(x,y)
    if point_is_inside?(x,y)
      @creator.send(:evgfx_click_on_card, self)
      return true
    end
    return false
  end
 
end #end CardGfx
