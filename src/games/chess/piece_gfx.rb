#file: piece_gfx


class PieceGfx
  attr_reader :board_info_item, :left, :top
  
  def initialize(left, top, image, piece)
    # pos_x stored
    @left = left
    # pos_y stored
    @top = top
    @image = image
    @square_width = image.width
    @square_height = image.height 
    @board_info_item = piece
    @visible = true
    # pos_x drawed
    @curr_left = @left
    # pos_y drawed
    @curr_top = @top
  end
  
  def point_is_inside?(x,y)
    if x > @left && x < (@left + @square_width) &&
       y > @top && y < (@top + @square_height)
      binside = true
    else
      binside = false
    end
    return binside
  end
  
  def drag_center_to(x,y)
    @curr_left = x - @square_width / 2
    @curr_top = y - @square_height / 2
  end
  
  def set_new_position(x,y)
    @left = x
    @top = y
    @curr_left = @left
    @curr_top = @top
  end
  
  def draw(dc)
    dc.drawIcon(@image, @curr_left, @curr_top) if @visible
  end
end

