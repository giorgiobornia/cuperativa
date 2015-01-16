# -*- coding: ISO-8859-1 -*-
#file: net_createpg_dlg.rb

$:.unshift File.dirname(__FILE__) + '/../..'

require 'rubygems'
require 'fox16'
require 'base/core/cup_strings'
require 'net_optionspg_dlg'

include Fox

##
# Shows a dialogbox to create a pending game
class DlgCreatePgGame < FXDialogBox
  
 
  ##
  # Init
  def initialize(owner, cupgui, supp_game)
    super(owner, "Crea un tavolo da gioco", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0, 0, 380, 290, 0, 0, 0, 0, 4, 4)
    
    #p supp_game
    
    @cup_gui = cupgui
    color_back = Fox.FXRGB(120, 120, 120)
    color_label = Fox.FXRGB(255, 255, 255)
    main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Popup menu
    pane = FXPopup.new(self)
    ix_game = 0
    @opt_frames = []
    # array of array that stores all textfield widget to retrive the value of
    # an option on a game
    @opt_widg_allgames = []
    @allgames_options = []
    # find current selector
    curr_game_key = @cup_gui.last_selected_gametype
    sel_curr = 0
    supp_game.each do |k, v|
      break if k == curr_game_key 
      sel_curr += 1
    end
    @private_pg = false 
    @pin_stored = "1234"
    
    
    supp_game.each do |k, v|
      opt = v.dup
      opt[:opt][:is_classifica] = {:type=>:checkbox, :name=>"Classifica", :val=>true}
      opt[:opt][:is_prive] = {:type=>:checkbox, :name=>"Gioco privato", :val=>false}
      @allgames_options << opt
    end
    
    @curr_game_opt = @allgames_options[sel_curr]
      
    
    # GAME LIST
    lbl_games = FXLabel.new(main_vertical, "Scegli un gioco dalla lista:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_games.backColor = color_back
    lbl_games.textColor = color_label
    
    # create the game list menu
    menu_list = FXOptionMenu.new(main_vertical, pane, (FRAME_RAISED|FRAME_THICK|
      JUSTIFY_HZ_APART|ICON_AFTER_TEXT|LAYOUT_CENTER_X|LAYOUT_CENTER_Y))
    
    # OPTIONS
    opt_vertical = FXVerticalFrame.new(main_vertical, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    opt_vertical.vSpacing = 15
    
    lbl_opz = FXLabel.new(opt_vertical, "Opzioni:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_opz.backColor = color_back
    lbl_opz.textColor = color_label
    
    @lbl_options_list = FXLabel.new(opt_vertical, "", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    
    # BUtton change options
    opzioni_bt = FXButton.new(opt_vertical, "Cambia Opzioni", @cup_gui.icons_app[:options], self, 0,
      LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    opzioni_bt.connect(SEL_COMMAND, method(:cmd_showoptionsdlg))
    opzioni_bt.iconPosition = (opzioni_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    
    # iterate for each supported game its options. Then create a panel for each game
    # On the single panel create a pair label and widget
    supp_game.values.each do |v|
      #p v
      opt = FXOption.new(pane, v[:name], nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
      opt.userData = ix_game
      opt.connect(SEL_COMMAND) do |sender, sel, ptr|
        #display_panel(sender.userData)
        @curr_game_opt = @allgames_options[sender.userData]
        display_curr_game_options()
      end
      ix_game += 1 
    end
    # select the current game
    menu_list.setCurrentNo(sel_curr)
     
    # bottom part
    FXHorizontalSeparator.new(main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    # create commnad
    create_bt = FXButton.new(btframe, "Crea", @cup_gui.icons_app[:gonext], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    create_bt.iconPosition = (create_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    #@curr_frame_selected = sel_curr
    #display_panel(@curr_frame_selected)
    display_curr_game_options()
  end
  
  def set_title(strtitle)
    self.title = strtitle
  end
  
  def cmd_showoptionsdlg (sender, sel, ptr)
    dlg = DlgNetGameOptions.new(self, @curr_game_opt, @cup_gui)
    if dlg.execute != 0
      @curr_game_opt[:opt] = dlg.get_curr_options
      display_curr_game_options()
    end
  end
  
  def display_curr_game_options()
    #@curr_game_opt = @allgames_options[sel_curr]
    @lbl_options_list.text = get_curr_options_string
  end
  
  ##
  # Provides the string with all options for display
  def get_curr_options_string
    res = []
    @curr_game_opt[:opt].each do |k,v|
      valore = v[:val]
      valore = "Si" if valore == true
      valore = "No" if valore == false
      res << " #{v[:name]} : #{valore}"
    end
    return res.join("\n")
  end
  
  ##
  # Provides the hash with options ready to be sent
  def get_create_options
    prive = @curr_game_opt[:opt][:is_prive]
    @private_pg = prive[:val]
    @pin_stored =  prive[:pin]
    is_class = @curr_game_opt[:opt][:is_classifica][:val]
    opt_game = {}
    @curr_game_opt[:opt].each do |k,v|
      if k != :is_prive and k !=  :is_classifica
        opt_game[k] = v
      end
    end
    res = {
      :game => @curr_game_opt[:name],
      :prive => {:val => prive[:val], :pin => prive[:pin] },
      :class => is_class,
      :opt_game => opt_game 
    }
    return res
  end
  
  def get_msg_details
    game_name = @curr_game_opt[:name]
    str_opt_arr = []
    @private_pg = false 
    @pin_stored = "1234"
    @curr_game_opt[:opt].each do |k,v|
      if k == :is_prive
        @private_pg = v[:val]
        @pin_stored = v[:pin]
        next
      end
      str_opt_arr << "#{k}=#{v[:val]}"
    end
    if @private_pg
      str_opt_arr << "gioco_private=true"
      # max 4 digit for the pin 
      str_opt_arr << "pin=#{@pin_stored}" 
    end
    str_opt_tosend = str_opt_arr.join(";")
    str_det = "#{game_name},#{str_opt_tosend}"
    return str_det  
  end
  
  # diagnostic function that depends on get_msg_details
  def is_private_game?
    return @private_pg
  end
  def get_pin
    return @pin_stored
  end

end #end DlgCreatePgGame

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
      @log =  Log4r::Logger["coregame_log"]
      app.runner = self
      @dlg_box = DlgCreatePgGame.new(app, {:spazzino_game=>{:enabled=>true, :name=>"Spazzino", :file_req=>"", :desc=>"Gioco dello spazzino a 2 giocatori", :class_name=>"SpazzinoGfx", :num_of_players=>2, :opt=>{:target_points=>{:type=>:textbox, :name=>"Punti vittoria", :val=>21}}}, :scopetta_game=>{:enabled=>true, :name=>"Scopetta", :file_req=>"/home/igor/Projects/ruby/cuperativa0508/src/network/client/../../network/client/../../base/../games/scopetta/scopetta_gfx.rb", :desc=>"Gioco dello scopa a 2 giocatori", :class_name=>"ScopettaGfx", :num_of_players=>2, :opt=>{:target_points=>{:type=>:textbox, :name=>"Punti vittoria", :val=>11}, :vale_napola=>{:type=>:checkbox, :name=>"Napoletana", :val=>true}}}, :briscola_game=>{:enabled=>true, :name=>"Briscola", :file_req=>"/home/igor/Projects/ruby/cuperativa0508/src/network/client/../../network/client/../../base/../games/briscola/briscola_gfx.rb", :desc=>"Gioco della briscola a 2 giocatori", :class_name=>"BriscolaGfx", :num_of_players=>2, :opt=>{:target_points_segno=>{:type=>:textbox, :name=>"Punti vittoria segno", :val=>61}, :num_segni_match=>{:type=>:textbox, :name=>"Segni in una partita", :val=>2}}}, :mariazza_game=>{:enabled=>true, :name=>"Mariazza", :file_req=>"/home/igor/Projects/ruby/cuperativa0508/src/network/client/../../network/client/../../base/../games/mariazza/mariazza_gfx.rb", :desc=>"Gioco della mariazza a 2 giocatori", :class_name=>"MariazzaGfx", :num_of_players=>2, :opt=>{:target_points_segno=>{:type=>:textbox, :name=>"Punti vittoria segno", :val=>41}, :num_segni_match=>{:type=>:textbox, :name=>"Segni in una partita", :val=>4}}}, :tombolon_game=>{:enabled=>true, :name=>"Tombolon", :file_req=>"/home/igor/Projects/ruby/cuperativa0508/src/network/client/../../network/client/../../base/../games/tombolon/tombolon_gfx.rb", :desc=>"Gioco del tombolon rovigiano a 2 giocatori", :class_name=>"TombolonGfx", :num_of_players=>2, :opt=>{:target_points=>{:type=>:textbox, :name=>"Punti vittoria", :val=>31}}}})
    end
    
    ##
    # Method called from TestRunnerDialogBox when go button is pressed
    def run
      if @dlg_box.execute != 0
         p msg_det = @dlg_box.get_msg_details
         @log.debug "pg_create: #{msg_det}"
         if @dlg_box.is_private_game?
            pin = @dlg_box.get_pin
            @log.debug "Private game with pin #{pin}" 
         end
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


