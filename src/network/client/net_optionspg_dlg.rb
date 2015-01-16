#file net_optionspg_dlg.rb
# shows a simple dialogbox to select options for the current pending game

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'fox16'
require 'base/core/cup_strings'

include Fox


##
# Dialogbox to set options of single networked game
class DlgNetGameOptions < FXDialogBox
  
  def initialize(owner, game_opt, cup_gui)
    super(owner, "Opzioni #{game_opt[:name]}", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0)
    
    color_back = Fox.FXRGB(120, 120, 120)
    color_label = Fox.FXRGB(255, 255, 255)
    @cup_gui = cup_gui
    
    main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # options list
    lbl_opz = FXLabel.new(main_vertical, "Opzioni:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_opz.backColor = color_back
    lbl_opz.textColor = color_label
    
    opt_list = game_opt[:opt]
    @opt_initial = opt_list 
    panel_frm = main_vertical
    opt_widg_values = {}
    opt_list.each do |kk, vv|
        hf = FXMatrix.new(panel_frm, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        hf.numColumns = 4
        widget_type = vv[:type]
        # widget
        case widget_type
          when :textbox
            # label of the property
            FXLabel.new(hf, vv[:name], nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
            # textbox
            txt_f =  FXTextField.new(hf, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
            txt_f.text = vv[:val].to_s
            opt_widg_values[kk] = txt_f   
          when :checkbox
            # checkbox
            FXLabel.new(hf, vv[:name], nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
            chk_f = FXCheckButton.new(hf, "", nil, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
            chk_f.checkState = vv[:val]
            opt_widg_values[kk] = chk_f
            if kk == :is_prive
              chk_f.connect(SEL_COMMAND) do |sender, sel, checked|
                if checked
                  @private_pg = true
                  @txt_pin.enable
                else
                  @private_pg = false
                  @txt_pin.disable
                end
              end
              FXLabel.new(hf, 'Pin', nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
              @txt_pin =  FXTextField.new(hf, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
              @txt_pin.text = get_random_pin
              @txt_pin.disable
            end#end if is prive
            #p opt_widg_values[kk].class
        end #end case
    end
    @opt_widg_values = opt_widg_values
    
    
    # bottom part
    FXHorizontalSeparator.new(main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH| PACK_UNIFORM_HEIGHT )
    
    # create commnad
    create_bt = FXButton.new(btframe, "OK", @cup_gui.icons_app[:ok], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    create_bt.iconPosition = (create_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
  end
  
  ##
  # Provides a random pin
  def  get_random_pin
    ss = ''
    4.times do
      ss.concat rand(10).to_s
    end
    return ss
  end
  
  def get_curr_options
    res = {}
    @opt_initial.each do |k,vv|
      widg = @opt_widg_values[k]
      if widg.class == Fox::FXCheckButton
        val =  widg.checkState == 1 ? true : false
      elsif widg.class == Fox::FXTextField
        val = widg.text.to_i
      end
      res[k] = vv
      res[k][:val] = val
      if k == :is_prive 
        res[k][:pin] = @txt_pin.text 
      end
    end
    return res
  end
  
  
end

if $0 == __FILE__
  require 'log4r'
  require '../../../test/gfx/test_dialogbox' 
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout 
  
  ##
  # Launcher of the dialogbox
  class TestMyDialogGfx

    def initialize(app)
      app.runner = self
      @dlg_box = DlgNetGameOptions.new(app,{:enabled=>true, :file_req=>"/home/igor/Projects/ruby/cuperativa0508/src/network/client/../../network/client/../../base/../games/spazzino/spazzino_gfx.rb", 
          :opt=>{:is_classifica=>{:type=>:checkbox, :name=>"Classifica", :val=>true}, :is_prive=>{:type=>:checkbox, :name=>"Gioco privato", :val=>false}, :target_points=>{:type=>:textbox, :name=>"Punti vittoria", :val=>21}}, :name=>"Spazzino", :desc=>"Gioco dello spazzino a 2 giocatori", :class_name=>"SpazzinoGfx", :num_of_players=>2},
                                       app )
    end
    
    ##
    # Method called from TestRunnerDialogBox when go button is pressed
    def run
      if @dlg_box.execute != 0
        p @dlg_box.get_curr_options
      end
    end
    
  end
  
  # create the runner: a window with one button that call runner.run
  theApp = FXApp.new("TestRunnerDialogBox", "FXRuby")
  mainwindow = TestRunnerDialogBox.new(theApp)
  mainwindow.set_position(0,0,300,300)
  # add a custom method present in @cup_gui
  def mainwindow.last_selected_gametype
    return :spazzino_game
  end
  tester = TestMyDialogGfx.new(mainwindow)
  theApp.create
  
  theApp.run
end



