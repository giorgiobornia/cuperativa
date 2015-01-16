#file: chat_table_view.rb
# visualize the chat panel when the network game is active

class ChatTableView
  
  def initialize(ctrlframe, gui_owner, net_controller, banned_words)
    @banned_words = banned_words
    @net_controller = net_controller
    @cup_gui = gui_owner
    @buttonFrame = FXVerticalFrame.new(ctrlframe, FRAME_SUNKEN|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT)
    
    sunkenFrame = FXHorizontalFrame.new(@buttonFrame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    group2 = FXVerticalFrame.new(sunkenFrame, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    @txtrender_tavolo_chat = FXText.new(group2, nil, 0, TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y) 
    @txtrender_tavolo_chat.backColor = Fox.FXRGB(238, 223, 204)
    @txtrender_tavolo_chat.textColor = Fox.FXRGB(0, 0, 0)
    
    matrix = FXMatrix.new(group2, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    
    @txtchat_tavolo_line = FXTextField.new(matrix, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
    @txtchat_tavolo_line.connect(SEL_COMMAND, method(:onBtSend_chat_tavolo_text))
    
    @log = Log4r::Logger["coregame_log"]
    
    #hide_panel
  end
  
  ##
  # Handler send chat text
  def onBtSend_chat_tavolo_text(sender, sel, ptr)
    msg = @txtchat_tavolo_line.text
    @banned_words.each do |word|
      msg.gsub!(word, "****")
    end
    @net_controller.send_chat_text(msg, :chat_tavolo)
    @txtchat_tavolo_line.text = ""
  end
  
  ##
  # Render text in the render tavolo chat control
  def render_chat_tavolo(msg)
    @txtrender_tavolo_chat.text += msg
    # ugly autoscrolling... 
    @txtrender_tavolo_chat.makePositionVisible(
              @txtrender_tavolo_chat.rowStart(@txtrender_tavolo_chat.getLength))
  
    
  end
 
end