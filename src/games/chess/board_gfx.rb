#file:board_gfx.rb
# handler of graphic board

require 'rubygems'
require 'piece_gfx'


class BoardChessGfx
  attr_accessor :dragging_piece
  
  def initialize(boardcore, images, init_x, init_y)
    @boardcore = boardcore
    # hash with all pieces (PieceGfx) on the board
    @piece_gfx_list = {}
    @image_gfx_resource = images
    @init_x = init_x
    @init_y = init_y
    # pixel width of a column
    @col_width = 0
    # pixel height of a row
    @col_height = 0
    # if true show the board for the black player
    @show_reversed = false
    
    @log = Log4r::Logger["coregame_log"]
    
    init_piece_list
    init_dragging_piece
  end
  
  def init_dragging_piece
    #info with dragging piece: {:pos_ini => [pos_x,pos_y], :piecegfx => piecegfx}
    # state: :idle, :begin_drag, :waiting_for_validation
    @dragging_piece = {}
    @dragging_piece[:state] = :idle 
  end
  
  def draw(dc)
    draw_board_withoutpieces(dc)
    draw_pieces(dc)
  end
  
  def draw_pieces(dc)
    if @dragging_piece[:state] != :idle
      @piece_gfx_list.each do |k,v|
        if @dragging_piece[:piecegfx] != v
          v.draw(dc)
        end  
      end
      # dragging pice is in foreground
      @dragging_piece[:piecegfx].draw(dc)
    else
      @piece_gfx_list.each do |k,v|
        v.draw(dc) 
      end
    end
  end
  
  def init_piece_list
    color_board =  :board_white
    @col_width = @image_gfx_resource[color_board].width
    @col_height = @image_gfx_resource[color_board].height
    
    @piece_gfx_list = {}
    @boardcore.pieces.each do |k,piece|
      #piece is here BoardInfoItem
      x = get_xpos_by_column(piece.column_start)
      y = get_ypos_by_row(piece.row_start)
      resource_key = piece.name_short.to_sym
      img = @image_gfx_resource[resource_key]
      @piece_gfx_list[k] = PieceGfx.new(x,y,img, piece)
    end
  end
  
  def find_row_onposy(pos_y)
    ret_y =  ((pos_y - @init_y)/@col_height).floor
    # 7- : we are interested on num row from the bottom, not from top
    return 7 - ret_y
  end
  
  def find_col_onposx(pos_x)
    ret_x = ((pos_x - @init_x)/@col_width).floor
    return ret_x
  end
  
  def get_ypos_by_row(row)
    y = @init_y + @col_height *  (7-row)
    if @show_reversed
      y = @init_y + @col_height *  (row)
    end
    return y  
  end
  
  def get_xpos_by_column(column)
    x  = @init_x + @col_width * column 
    if @show_reversed
      x = @init_x + @col_width * (7-column)
    end
    return x
  end
  
  def update_after_move
    # pezzi nuovi sono arrivati (promozione)
  end
  
  def draw_board_withoutpieces(dc)
    x = @init_x
    y = @init_y
    img_teil = nil
    col =  :board_white
    8.times do |iy|
      8.times do |ix|
        img_teil = @image_gfx_resource[col]
        dc.drawImage(img_teil, x, y)
        x  += img_teil.width
        col = :board_white == col  ? :board_black : :board_white
      end
      col = :board_white == col  ? :board_black : :board_white
      y  += img_teil.height
      x = @init_x
    end
  end
  
  def start_drag_piece(pos_x, pos_y)
    return false if @dragging_piece[:state] != :idle
    
    init_dragging_piece
    
    @piece_gfx_list.each do |k,piecegfx|
      if piecegfx.point_is_inside?(pos_x, pos_y)
        if @boardcore.color_on_turn == piecegfx.board_info_item.color_piece
          piecegfx.drag_center_to(pos_x,pos_y)
          @log.debug "Start drag on #{piecegfx.board_info_item.type_piece} on #{piecegfx.board_info_item.colix_tostr}#{piecegfx.board_info_item.row_start+1}"
          @dragging_piece = {:pos_ini => { :x => piecegfx.left, :y => piecegfx.top}, :piecegfx => piecegfx}
          @dragging_piece[:row_start] = piecegfx.board_info_item.row_start
          @dragging_piece[:col_start] = piecegfx.board_info_item.column_start
          @dragging_piece[:state] = :begin_drag
          return true
        end
      end
    end
    return false
  end
  
  def drag_moved_on(pos_x, pos_y)
    piecegfx = @dragging_piece[:piecegfx]
    piecegfx.drag_center_to(pos_x,pos_y) if piecegfx
  end
  
  def end_drag_piece(pos_x, pos_y)
    piecegfx = @dragging_piece[:piecegfx]
    column = find_col_onposx(pos_x)
    x = get_xpos_by_column(column)
    row = find_row_onposy(pos_y)
    y = get_ypos_by_row(row)
    piecegfx.set_new_position(x,y)
    @dragging_piece[:pos_fin] = [x,y]
    @dragging_piece[:col_end] = column
    @dragging_piece[:row_end] = row
    @dragging_piece[:state] = :waiting_for_validation
  end
  
  def is_draggingpiece_valid?
    color = @dragging_piece[:piecegfx].board_info_item.color_piece
    start_x = @dragging_piece[:col_start]
    start_y  = @dragging_piece[:row_start]
    end_x = @dragging_piece[:col_end]
    end_y = @dragging_piece[:row_end]
    @dragging_piece[:movetype] = @boardcore.get_move_igorchess_type(color, start_x, start_y, end_x, end_y)
    return @dragging_piece[:movetype] != :invalid ? true : false
  end
  
  def dragpiece_move_validcandidate 
    @log.debug "drag piece is valid candidate"
    @dragging_piece[:state] = :idle 
  end
  
  def dragpiece_move_invalid
    @log.debug "drag piece is an invalid move, restore to the origin"
    piecegfx = @dragging_piece[:piecegfx]
    #restore initial position of the gfx
    x = @dragging_piece[:pos_ini][:x]
    y = @dragging_piece[:pos_ini][:y]
    piecegfx.set_new_position(x,y)
    @dragging_piece[:state] = :idle 
  end
  
  
end