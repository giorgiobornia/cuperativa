# -*- coding: ISO-8859-1 -*-
#file: net_joinprivate_dlg.rb

require 'rubygems'
require 'fox16'

include Fox

##
# Shows a dialogbox to join private game
class DlgJoinPrivate < FXDialogBox
  
  ##
  # owner: wnd owner
  def initialize(owner, comment)
    super(owner, comment, DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0, 0, 0, 0, 0, 0, 0, 0, 4, 4)
    
    @cup_gui = owner
    @log = Log4r::Logger["coregame_log"]
    @comment = comment
    
    @main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # user data section
    group2 = FXVerticalFrame.new(@main_vertical, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    matrix = FXMatrix.new(group2, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    FXLabel.new(matrix, "Pin:", nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    @pin_info = FXTextField.new(matrix, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
    
    # bottom part
    FXHorizontalSeparator.new(@main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(@main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    # connect commnad
    @conn_button = FXButton.new(btframe, "Partecipa", @cup_gui.icons_app[:gonext], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @conn_button.iconPosition = (@conn_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
  
    @conn_button.setDefault  
    @conn_button.setFocus
    
  end
  
  ##
  # Provides pin
  def get_pin
    @pin_info.text
  end
  
end #DlgJoinPrivate

if $0 == __FILE__
  # test this dialogbox
  require 'rubygems'
  require 'log4r'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  class DialogTester < FXMainWindow
    attr_accessor :icons_app
    
    def initialize(app)
      # Invoke base class initialize first
      super(app, "Dialog Test", :opts => DECOR_ALL, :width => 400, :height => 200)
      contents = FXHorizontalFrame.new(self,
        LAYOUT_SIDE_TOP|FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
      modalButton = FXButton.new(contents,
          "&Modal Dialog...\tDisplay modal dialog",
          :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X|LAYOUT_CENTER_Y)
      modalButton.connect(SEL_COMMAND, method(:onCmdShowDialogModal))
      @icons_app = {}
    end

    # Show a modal dialog
    def onCmdShowDialogModal(sender, sel, ptr)
      dlg = DlgJoinPrivate.new(self, "Test dialog")
      if dlg.execute != 0
        #p dlg.get_pin
      end
      return 1
    end

    # Start
    def create
      super
      show(PLACEMENT_SCREEN)
    end
  end# DialogTester
  
  theApp = FXApp.new("TestDlg", "FXRuby")
  DialogTester.new(theApp)
  theApp.create
  theApp.run
end