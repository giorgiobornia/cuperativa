#file: smazzata_mbox_gfx.rb
# control that show the smazzata end points information
$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/..'

require 'rubygems'

if $0 == __FILE__
  $:.unshift File.dirname(__FILE__) + '/../../../test'
  require 'gfx/test_basecontrol_gfx'
end

require 'gfx_general/gfx_elements'
require 'component_base'

##
# Message box control for the canvas
class SmazzataInfoMbox < ComponentBase
  attr_accessor :pos_x, :pos_y, :width, :height, :visible, :color
  attr_accessor :caption, :creator, :blocking, :points, :name_p1, :name_p2
  
  def initialize(caption = "",  x=0, y=0, w=0, h=0, font = 0, color=0, hvisb=true)
    super(5)
    @comp_name = "SmazzataInfoMbox"
    @pos_x = x       # x position
    @pos_y = y       # y position
    @width = w
    @height = h   
    @visible = hvisb  # visible flag
    @color = color
    @caption = caption
    @font_text = font
    @bt_ok = ButtonGfx.new("OK", x + w/2, y+h-30)
    @bt_ok.font = font
    @bckcolor = Fox.FXRGB(34, 20, 90)
    @border_col = Fox.FXRGB(250, 250, 240)
    @caption_col = Fox.FXRGB(250, 42, 23)
    @text_col = Fox.FXRGB(255, 255, 255)
    @creator = nil
    @blocking = false
    @name_p1 = "Player"
    @name_p2 = "Avversario"
    
    @str_puntegg_smazzata = "Punteggio smazzata"
    @points = { 
      :p1 => {:tot => 15, :carte => 2, :spade => 1, :duedispade => 1,
        :settedidenari => 1, :fantedispade => 1, :raddoppio => 6, :napoli => 0, 
        :tombolon => 0,  :scope => 3 , :colore => 0, :denari => 2, :primiera => 1,
        :spazzino => 1, :picula => 2, :bager => 3, :pezze => 4, :assi => 1
       }, 
      :p2 => {:tot => 4, :carte => 0, :spade => 0, :duedispade => 0,
        :settedidenari => 0, :fantedispade => 0, :raddoppio => 0, :napoli => 3, 
        :tombolon => 0,  :scope => 0 , :colore => 4, :denari => 0, :primiera => 0,
        :spazzino => 0, :picula => 0, :bager => 0, :pezze => 3, :assi => 3
      }
    }
    
    @shortcuts_onori = {}
    @extra_points_enabled = {}
    @shortcuts_scope = {}
    
  end
  
  def set_visible(val)
    @visible = val
  end
  
  def set_shortcuts_tressette
    @shortcuts_onori = [{:symb => :pezze, :str => "Pezze"},
                 {:symb => :assi, :str => "Assi"},
                 ]
    @extra_points_enabled = {}
    @shortcuts_scope = {}
  end
  
  ###
  # Set infos for tombolon
  def SetShortcutsTombolon
    @shortcuts_onori = [{:symb => :carte, :str => "Carte"},
                 {:symb => :spade, :str => "Spade"},
                 {:symb => :duedispade, :str => "Due di Spade"},
                 {:symb => :settedidenari, :str => "Sette di Denari"},
                 {:symb => :fantedispade, :str => "Fante di Spade"},
                 ]
    @extra_points_enabled = {:raddoppio => true, :napoli => true, :tombolon => true}
    
    @shortcuts_scope = [{:symb => :scope, :str => "Scope"},
                 {:symb => :colore, :str => "Colore"},
                 ]
  end
  
  ###
  # Set infos for spazzino
  def SetShortcutsSpazzino
    @shortcuts_onori = [{:symb => :carte, :str => "Carte"},
                 {:symb => :spade, :str => "Spade"},
                 {:symb => :duedispade, :str => "Due di Spade"},
                 {:symb => :settedidenari, :str => "Sette di Denari"},
                 {:symb => :fantedispade, :str => "Fante di Spade"},
                 ]
    @extra_points_enabled = {:raddoppio => false, :napoli => true, :tombolon => false}
    
    @shortcuts_scope = [{:symb => :spazzino, :str => "Spazzini"},
                 {:symb => :bager, :str => "Bager"},
                 {:symb => :picula, :str => "Picula"},
                 ]
  end
  
  ###
  # Set infos for scopetta
  def SetShortcutsScopettta
    @shortcuts_onori = [{:symb => :carte, :str => "Carte"},
                 {:symb => :denari, :str => "Denari"},
                 {:symb => :primiera, :str => "Primiera"},
                 {:symb => :settedidenari, :str => "Sette di Denari"},
                 ]
    @extra_points_enabled = {:raddoppio => false, :napoli => true, :tombolon => false}
    
    @shortcuts_scope = [
                        {:symb => :scope, :str => "Scope"},
                 ]
  end
  
  ##
  # Draw the control
  def draw(dc)
    return unless @visible
    #check the text
    intra_line_y = 5
    cap_h = 30
    
    hh_line = @font_text.getTextHeight(@str_puntegg_smazzata)
    max = @font_text.getTextWidth(@str_puntegg_smazzata)
    
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
    # points detail
   
    col2_x = @width / 2
    col1_x = col2_x / 2 - 30
    col3_x = col2_x + col1_x + 60
    
    # total
    dc.drawText(posx_line, posy_line, @str_puntegg_smazzata)
    posy_line += intra_line_y + hh_line
    str = "#{@name_p1}   #{@points[:p1][:tot]}"
    dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
    str = "#{@name_p2}   #{@points[:p2][:tot]}"
    dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
    posy_line += intra_line_y + hh_line
    
    @shortcuts_onori.each do |ele|
      str = "#{@points[:p1][ele[:symb]]}"
      dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
      str = ele[:str]
      dc.drawText(@pos_x + calc_offset_x(str, col2_x), posy_line, str)
      str = "#{@points[:p2][ele[:symb]]}"
      dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
      posy_line += intra_line_y + hh_line
    end
    
    # raddoppio
    if @extra_points_enabled[:raddoppio]
      if @points[:p1][:raddoppio] > 0
        str = "+#{@points[:p1][:raddoppio]}"
        dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
      end
      str = "RADDOPPIO"
      dc.drawText(@pos_x + calc_offset_x(str, col2_x), posy_line, str)
       if @points[:p2][:raddoppio] > 0
        str = "+#{@points[:p2][:raddoppio]}"
        dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
      end
      posy_line += intra_line_y + hh_line
    end
    # napoli
    if @extra_points_enabled[:napoli]
      if @points[:p1][:napoli] > 0
        str = "#{@points[:p1][:napoli]}"
        dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
      end
      str = "Napoli"
      dc.drawText(@pos_x + calc_offset_x(str, col2_x), posy_line, str)
       if @points[:p2][:napoli] > 0
        str = "#{@points[:p2][:napoli]}"
        dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
      end
      posy_line += intra_line_y + hh_line
    end
    # tombolon
    if @extra_points_enabled[:tombolon]
      if @points[:p1][:tombolon] > 0
        str = "#{@points[:p1][:tombolon]}"
        dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
      end
      str = "TOMBOLON"
      dc.drawText(@pos_x + calc_offset_x(str, col2_x), posy_line, str)
       if @points[:p2][:tombolon] > 0
        str = "#{@points[:p2][:tombolon]}"
        dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
      end
      posy_line += intra_line_y + hh_line
    end
    
    @shortcuts_scope.each do |ele|
      str = "#{@points[:p1][ele[:symb]]}"
      dc.drawText(@pos_x + calc_offset_x(str, col1_x), posy_line, str)
      str = ele[:str]
      dc.drawText(@pos_x + calc_offset_x(str, col2_x), posy_line, str)
      str = "#{@points[:p2][ele[:symb]]}"
      dc.drawText(@pos_x + calc_offset_x(str, col3_x), posy_line, str)
      posy_line += intra_line_y + hh_line
    end
    
    
    #draw ok button
    @bt_ok.pos_x = @pos_x + @width / 2
    @bt_ok.pos_y = @pos_y + @height - 40
    @bt_ok.draw(dc)
  end
  
  
  def calc_offset_x(str, center_x)
    res = center_x - (@font_text.getTextWidth(str) / 2)
    return res 
  end
  
  def on_mouse_lclick_up
  end
  
  ##
  # User click with left button
  def on_mouse_lclick(event)
    return false unless @visible
    x = event.win_x
    y = event.win_y
    if @bt_ok.point_is_inside?(x,y)
      @visible = false
      return true
    elsif x > @pos_x && x < (@pos_x + @width) &&
       y > @pos_y && y < (@pos_y + @height)
      return true
    end
  end
end





if $0 == __FILE__
  require 'log4r'
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  class TestMsgboxGfx < GameGfxSkeleton
    def initialize(app)
      @mainwindow = app
      super()
      @border_col = Fox.FXRGB(243, 240, 100)
      @image_gfx_resource = {}
      @font = FXFont.new(getApp(), "comic", 10)
      @font.create
      build_msg
    end
    
    def build_msg
      @msg_box_info = SmazzataInfoMbox.new("Titolo", 
                   200,50, 400,400, @font)
      #@msg_box_info.SetShortcutsTombolon
      #@msg_box_info.SetShortcutsScopettta
      #@msg_box_info.SetShortcutsSpazzino
      @msg_box_info.set_shortcuts_tressette
    end
  
    def getApp
      return @mainwindow.getApp
    end
  
    def draw_static_scene(dc, width, height)
      @msg_box_info.draw(dc)
    end
   
  end

  
  theApp = FXApp.new("TestMyCanvasGfx", "FXRuby")
  mainwindow = TestCanvasGfx.new(theApp)
  mainwindow.set_position(0,0,800,600)
  tester = TestMsgboxGfx.new(mainwindow)
  mainwindow.current_game_gfx = tester
  theApp.create
  
  theApp.run
end 