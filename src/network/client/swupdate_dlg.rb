# -*- coding: ISO-8859-1 -*-
#file: swupdate_dlg.rb

require 'rubygems'
require 'fox16'

include Fox

##
# Shows a dialogbox to join private game
class DlgSwUpdate < FXDialogBox
  attr_accessor :clientup
  ##
  # owner: wnd owner
  def initialize(owner, comment, text_msg)
    super(owner, comment, DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      200, 300, 0, 300, 0, 0, 0, 0, 4, 4)
    
    @job_to_start = nil
    @cup_gui = owner
    @log = Log4r::Logger["coregame_log"]
    @comment = comment
    
    @main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # user text section
    group2 = FXVerticalFrame.new(@main_vertical, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    matrix = FXMatrix.new(group2, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    # icon update
    FXButton.new(matrix, "\tInizia update\tInizia update", @cup_gui.icons_app[:icon_update],nil, 0,ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0,0,0,0,10,10,3,3)
    # user text
    @lbl_text = FXLabel.new(matrix, text_msg, nil, JUSTIFY_LEFT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    
    # progressbar
    @pbar = FXProgressBar.new(group2, nil, 0,
      LAYOUT_FILL_X|LAYOUT_SIDE_TOP|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_PERCENTAGE)
    @pbar.progress = 0
    @pbar.total = 100
    
    # bottom part
    FXHorizontalSeparator.new(@main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(@main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH| PACK_UNIFORM_HEIGHT )
    
    # start commnad
    @start_button = FXButton.new(btframe, "Aggiorna", @cup_gui.icons_app[:gonext], self, 0,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @start_button.iconPosition = (@start_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    @start_button.connect(SEL_COMMAND, method(:bt_start))
    
    # ok button
    @ok_button = FXButton.new(btframe, "Fine", @cup_gui.icons_app[:ok], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    @ok_button.iconPosition = (@ok_button.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    @ok_button.disable
    #@ok_button.hide
    
    # cancel command
    @canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, 0,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    @canc_bt.iconPosition = (@canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    @canc_bt.connect(SEL_COMMAND, method(:bt_cancel))
    
    @start_button.setDefault  
    @start_button.setFocus
    @clientup = nil
    button_state_initial
  end
  
  ##
  # update progressbar
  def update_progress(val)
    if val >= 0 and val <= 100
      @pbar.progress = val
    end
  end
  
  def end_update_proccess
    @ok_button.enable
  end
  
  ##
  # Set the job to start in the worker thread
  # job_to_start: method called when the update process is started in the worker thread
  def set_job_install(*args)
    @job_to_start = args   
  end
  
  def button_state_initial
    @start_button.show
    @canc_bt.show
    @ok_button.disable
    @pbar.progress = 0
    @pbar.total = 100
  end
  
  ##
  # set dialogbox text
  def set_text(str_text)
    @lbl_text.text = str_text
  end
  
  ##
  # Start update procedure
  def bt_start(sender, sel, ptr)
    #@ok_button.show
    #@ok_button.enable
    @start_button.hide
    @canc_bt.hide
    if @clientup
      @clientup.start_update_sequence(@job_to_start)
    end
  end
  
  ##
  # Cancel button
  def bt_cancel(sender, sel, ptr)
    if @clientup
      @clientup.cancel_update_sequence
    end
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
      str_text = "E' disponibile una nuova versione del programma Cuperativa.\nEssa e' necessaria per giocare in rete.\nVuoi aggiornare il programma cuperativa?\n"
      str_title = "Aggiorna il programma?"
      
      dlg = DlgSwUpdate.new(self, str_title, str_text)
      dlg.set_text str_text
      if dlg.execute != 0
        
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