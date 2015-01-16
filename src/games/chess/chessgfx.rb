#file: chess.rb
#Main view for chess game

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'

if $0 == __FILE__
  # we are testing this gfx, then load all dependencies
  require '../../cuperativa_gui.rb' 
end

require 'chess_core'
require 'board_gfx'


class ChessGfx 
  attr_accessor :color_backround
  
  def initialize(app)
    @cupera_gui= app
    @border_col = Fox.FXRGB(243, 240, 100)
    @image_gfx_resource = {}
    @font = FXFont.new(getApp(), "comic", 10)
    @font.create
    @log = Log4r::Logger["coregame_log"] 
    @resource_path = @cupera_gui.get_resource_path
    @color_backround = nil
    @state_game = :splash
    load_resource
  end
  
  def onSizeChange(width,height)
  end
  
  def set_canvas_frame(canvasFrame)
  end
  
  def create_wait_for_play_screen
    
  end
  
  def load_resource
    res_sym = :back_tile_img
    png_resource =  File.join(@resource_path ,"images/baize.png")
    img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
    FXFileStream.open(png_resource, FXStreamLoad) { |stream| img.loadPixels(stream) }
    img.create
    @image_gfx_resource[res_sym] = img
    
    load_pieces
    load_backboard
  end
  
  def deactivate_game
    if @extra_frame
      @extra_frame.hide
    end
  end
  
  def start_new_game(players, options)
    @log.debug 'start new game'
    @state_game = :ongame
    @chess_core = ChessCore.new
    @chess_core.gui_new_match(players, options)
    
    @board_gfx = BoardChessGfx.new(@chess_core.board_core, 
                                   @image_gfx_resource, 20, 20)
    
    @cupera_gui.update_dsp
  end
  
  def load_pieces
    name_color = ['w', 'b']
    name_piecs = ['b', 'k', 'r', 'q', 'n', 'p']
    file_name = ""
    begin
      name_color.each do |col_name|
        name_piecs.each do |pie_name|
          name_piece = "#{col_name}#{pie_name}"
          file_name = File.join(@resource_path ,"images/scacchi/#{name_piece}.png")
          img = FXPNGIcon.new(getApp(), nil, 0, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP  )
          FXFileStream.open(file_name, FXStreamLoad) { |stream| img.loadPixels(stream) }
          img.create
          #p img.width 
          #p img.height
          @image_gfx_resource[name_piece.to_sym] = img
        end
      end
    rescue
      str = "Errore nel caricare l'immagine della scacchiera: #{$!}\n"
      str += "File: #{file_name}"
      @log.error str
      @cupera_gui.mycritical_error(str)
    end
  end
  
  def load_backboard
    file_name = File.join(@resource_path ,"images/scacchi/dark60.gif")
    img = FXGIFIcon.new(getApp(), nil, 0, IMAGE_KEEP )
    FXFileStream.open(file_name, FXStreamLoad) { |stream| img.loadPixels(stream) }
    img.create
    @image_gfx_resource[:board_black] = img
    file_name = File.join(@resource_path ,"images/scacchi/light60.gif")
    img = FXGIFIcon.new(getApp(), nil, 0, IMAGE_KEEP )
    FXFileStream.open(file_name, FXStreamLoad) { |stream| img.loadPixels(stream) }
    img.create
    @image_gfx_resource[:board_white] = img
  end
  
  def getApp
    return @cupera_gui.getApp
  end
  
  def draw_static_scene(dc, width, height)
    if @state_game == :ongame
      # draw the static scene
      draw_background(dc, width, height)
      #test_draw_pieces(dc)
      @board_gfx.draw(dc)
    end
  end
  
  
  def test_draw_pieces(dc)
    init_x = 50
    init_y = 50
    x = init_x
    y = init_y
    img_teil = nil
    board = [ [:br, :bn], [:wp, :bp] ]
    board.each do |row|
      row.each do |sym_piece|
        img_teil = @image_gfx_resource[sym_piece]
        #p img_teil.width
        #p img_teil.height
        dc.drawIcon(img_teil, x, y)
        #dc.drawImage(img_teil, x, y)
        x  += img_teil.width
      end
      y  += img_teil.height
      x = init_x
    end
  end
  
  def draw_background(dc, width, height)
    img_teil = @image_gfx_resource[:back_tile_img]
    x = 0
    y = 0
    while y <  height
      while x <  width
        dc.drawImage(img_teil, x, y)
        x  += img_teil.width
        #p x,y
      end
      y  += img_teil.height
      x = 0
      #p "y = #{y}"
    end
  end
  
  def onLMouseDown(event)
    #@log.debug 'onLMouseDown'
    if @state_game == :ongame
      if @board_gfx.start_drag_piece(event.win_x, event.win_y)
        @ondrag = true
        @cupera_gui.update_dsp
      end
    end
  end
  
  def onLMouseMotion(event)
    if @state_game == :ongame
      if @ondrag
        #p event.win_x
        #p event.win_y
        @board_gfx.drag_moved_on(event.win_x, event.win_y)
        @cupera_gui.update_dsp
      end
    end
  end
  
  def onLMouseUp(event)
    #@log.debug 'mouse up'
    if @state_game == :ongame
      if @ondrag
        @board_gfx.end_drag_piece(event.win_x, event.win_y)
        if could_be_valid_move?
          @board_gfx.dragpiece_move_validcandidate
          do_move_to_core
        else
          @board_gfx.dragpiece_move_invalid
        end
        @ondrag = false
        @cupera_gui.update_dsp
      end
    end
  end
  
  ##
  # Local validation before send request to the core.
  # Used because core could be remote and we make both validations.
  def could_be_valid_move?
    return @board_gfx.is_draggingpiece_valid?
  end
  
  def do_move_to_core
    col_start = @board_gfx.dragging_piece[:col_start]
    # TODO
    #@chess_core.alg_make_move(col_start, row_start, col_end, row_end)
  end
  
end


if $0 == __FILE__
  # test this gfx
  require '../../../test/test_canvas'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  theApp = FXApp.new("TestCanvas", "FXRuby")
  mainwindow = TestCanvas.new(theApp)
  mainwindow.set_position(0,0,800,600)
  
  
  theApp.create()
  players = []
  players << PlayerOnGame.new('me', nil, :human_local, 0)
  players << PlayerOnGame.new('me2', nil, :human_local, 1)
  
  mainwindow.init_gfx(ChessGfx, players)
  theApp.run
end

