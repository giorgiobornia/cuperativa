# file: listgames_dlg.rb
# Game list

require 'rubygems'
require 'fox16'

include Fox

##
# Class to display the game list
class DlgListGames < FXDialogBox
  
  def initialize(owner, supp_game, curr_game_key)
    super(owner, "Seleziona un gioco", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0, 0, 0, 0, 0, 0, 0, 0, 4, 4)
    @cup_gui = owner
    color_back = Fox.FXRGB(120, 120, 120)
    color_label = Fox.FXRGB(255, 255, 255)
    
    main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    lbl_games = FXLabel.new(main_vertical, "Lista giochi:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_games.backColor = color_back
    lbl_games.textColor = color_label
    
    
    # list of games as menu pane
    @activated_key = curr_game_key
    
    # simple pane
    pane = FXPopup.new(self)
    # find current selector
    sel_curr = 0
    supp_game.each do |k, v|
      break if k == curr_game_key 
      sel_curr += 1
    end
    
    supp_game.each do |k, v|
      # insert option into the pane
      opt = FXOption.new(pane, v[:name], nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
      opt.connect(SEL_COMMAND) do |sender, sel, ptr|
        @activated_key = k
        @lbl_game_desc.text = "#{v[:desc]}"
      end
    end #supp_game
    
    # create the list menu
    menu_list = FXOptionMenu.new(main_vertical, pane, (FRAME_RAISED|FRAME_THICK|
              JUSTIFY_HZ_APART|ICON_AFTER_TEXT|LAYOUT_CENTER_X|LAYOUT_CENTER_Y))
    # select the current game
    menu_list.setCurrentNo(sel_curr)
    
    # game description
    lbl_desctitle = FXLabel.new(main_vertical, "Descrizione:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_desctitle.backColor = color_back
    lbl_desctitle.textColor = color_label
    @lbl_game_desc = FXLabel.new(main_vertical, "#{supp_game[curr_game_key][:desc]}", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    
    
    # ----------- bottom part --------------
    FXHorizontalSeparator.new(main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    # Activate commnad
    create_bt = FXButton.new(btframe, "Attiva", @cup_gui.icons_app[:gonext], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    create_bt.iconPosition = (create_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # cancel command
    canc_bt = FXButton.new(btframe, "Cancella", @cup_gui.icons_app[:icon_close], self, FXDialogBox::ID_CANCEL,
      LAYOUT_RIGHT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    canc_bt.iconPosition = (canc_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
   
    
  end
  
  ##
  # Provides the selected game key
  def get_activatedgame_key
    return @activated_key
  end
  
end # DlgListGames
