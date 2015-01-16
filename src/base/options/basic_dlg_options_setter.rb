#file: basic_dlg_options_setter.rb

##
# Basic options setter
class BasicDlgOptionsSetter < FXDialogBox
  def initialize(owner, title, settings, cup_gui, x,y,w,h)
    super(owner, title, DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE|DECOR_CLOSE,
      x, y, w, h, 0, 0, 0, 0, 4, 4)
    
    @settings = settings
    @cup_gui = cup_gui
    
    main_vertical = FXVerticalFrame.new(self, 
      LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # children vertical frame callback
    on_build_vertframe(main_vertical)
    
    # bottom part
    btframe = FXHorizontalFrame.new(main_vertical, 
      LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    FXHorizontalSeparator.new(main_vertical,  LAYOUT_BOTTOM|SEPARATOR_RIDGE|LAYOUT_FILL_X)
    
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # finish commnad
    fine_bt = FXButton.new(btframe, "Fine", @cup_gui.icons_app[:leave], self, 0,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    fine_bt.connect(SEL_COMMAND, method(:bt_fine))
    fine_bt.iconPosition = (fine_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # apply command
    apply_bt = FXButton.new(btframe, "Applica", @cup_gui.icons_app[:apply], nil, 0,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    apply_bt.connect(SEL_COMMAND, method(:bt_apply))
    apply_bt.iconPosition = (apply_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
  end
  
  ##
  # Apply current selection without termination
  def bt_apply(sender, sel, ptr)
    set_settings
    #@settings["deck_name"] = @curr_deck_key if @curr_deck_key
  end
  
  ##
  # Apply changes and terminate
  def bt_fine(sender, sel, ptr)
    #@settings["deck_name"] = @curr_deck_key if @curr_deck_key
    set_settings
    # send ID_CANCEL to this dialogbix instance
    self.handle(self, MKUINT(FXDialogBox::ID_CANCEL, SEL_COMMAND), nil)
  end
end