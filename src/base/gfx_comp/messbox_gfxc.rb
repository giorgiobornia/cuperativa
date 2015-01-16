#file: messbox_gfxc.rb

##
# Messagebox component. This is to substitute functions defined in the
# BaseEngineGfx
class MsgBoxComponent < ComponentBase
  attr_accessor :autoremove, :box_pos_x, :box_pos_y
  
  def initialize(gui, core, timeout, font)
    super(15)
    @comp_name = "MsgBoxComponent"
    @msg_box_info = nil
    @cupera_gui = gui
    @core_game = core
    @timeout_msgbox = timeout
    @font = font
    @autoremove = false
    @box_pos_x = 200
    @box_pos_y = 50

  end
  
  def build(player)
    @log.debug "Build messagebox"
    @msg_box_info = MessageBoxGfx.new("Titolo", "La partita comincia\nPartita finita 2 a 1\n Accusa qualcosa",
                   @box_pos_x,@box_pos_y, 200,200, @font)
    @msg_box_info.visible = false
    @msg_box_info.creator = self 
  end
  
  def on_mouse_lclick(event)
    #@log.debug "messagebox click..."
    return false unless @msg_box_info
    return false unless @msg_box_info.visible
    bres = @msg_box_info.on_mouse_lclick(event.win_x, event.win_y)
    return bres 
  end
  
  def draw(dc)
    if @msg_box_info
      if @msg_box_info.visible
        @msg_box_info.draw(dc)
      end
    end
  end
  
  def set_visible(val)
    @msg_box_info.set_visible(val)
  end
  
  def visible
    return @msg_box_info.visible
  end
  
  ##
  # Shows the message dialogbox
  # suspend: if true suspend all core event processing
  #          use it with caution because if the game is not restored
  #          all communication with the core are blocked
  def show_message_box(caption, text, suspend=true)
    if @msg_box_info.blocking == true
      @log.warn "Messagebox overlapping because already blocked"
      @msg_box_info.caption += " e #{caption}"
      @msg_box_info.text += "\n #{text}"
      suspend = false # don't block another time
    else
      @msg_box_info.caption = caption
      @msg_box_info.text = text
      @msg_box_info.blocking = false
    end
    
    @msg_box_info.visible = true
    @msg_box_info.z_order = 0 #focus
    
    if suspend
      @log.debug "msgbox blocking and wait for timeout"
      if @autoremove
        @cupera_gui.registerTimeout(@timeout_msgbox, :onTimeoutMsgBox2, self)
      else
        @cupera_gui.registerTimeout(@timeout_msgbox, :onTimeoutMsgBox1, self)
      end
      # suspend core event process untill timout
      @msg_box_info.blocking = true
      @core_game.suspend_proc_gevents
    end
    @cupera_gui.update_dsp
  end
  
  ##
  # Timeout on messagebox
  def onTimeoutMsgBox1
    @log.debug "onTimeoutMsgBox1 blocking: #{@msg_box_info.blocking}"
    if @msg_box_info.blocking == true
      @msg_box_info.blocking = false
      @core_game.continue_process_events if @core_game
    end
  end
  
  ##
  # Timeout on messagebox
  def onTimeoutMsgBox2
    @log.debug "onTimeoutMsgBox2 remove dialogbox automatically"
    onTimeoutMsgBox1
    #remove messagebox automatically
    if @msg_box_info
      @msg_box_info.set_visible(false)
      # refresh the display
      @cupera_gui.update_dsp
    end 
  end
  
  ##
  # user click on ok inside the message boxy
  def evgfx_click_on_msgbox_ok(dlgmsg)
    @log.debug "MSGBOX: user click on OK, blocking: #{@msg_box_info.blocking}"
    if @msg_box_info.blocking == true
      @msg_box_info.blocking = false
      @core_game.continue_process_events if @core_game
    end
  end
  
end #end MsgBoxComponent


