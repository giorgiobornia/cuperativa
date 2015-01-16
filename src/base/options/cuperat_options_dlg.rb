#file: cuperat_options_dlg.rb

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'fox16'

require 'cards_options_dlg'
require 'names_options_dlg'
require 'netw_gen_options_dlg'
require 'other_options_dlg'


##
# Cuperativa options. Manage all sub options dialogbox
class CuperatOptionsDlg < FXDialogBox
  
  def initialize(owner, settings)
    super(owner, "Opzioni Cuperativa", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE|DECOR_CLOSE,
      0, 0, 400, 200, 0, 0, 0, 0, 4, 4)
    
    @log = Log4r::Logger["coregame_log"]
    @curr_settings = settings
    @cupera_gui = owner
    
    bckcolor_lbls = Fox.FXRGB(120, 120, 120)
    color_label = Fox.FXRGB(255, 255, 255)
    
    main_vertical = FXVerticalFrame.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    # general options
    lbl_gen = FXLabel.new(main_vertical, "Generali:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_gen.backColor = bckcolor_lbls
    lbl_gen.textColor = color_label
    
    toolbarShell = FXToolBarShell.new(self)
    toolbar = FXToolBar.new(main_vertical, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
    #card options
    icon_carte = owner.icons_app[:card_ass]
    bt_carte_deck = FXButton.new(toolbar, "Mazzi\nCarte\tMazzi Carte\tMazzi Carte", icon_carte,nil, 0,ICON_BEFORE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    bt_carte_deck.connect(SEL_COMMAND, method(:bt_card_options))
    
    # name options
    icon_nomi = owner.icons_app[:nomi]
    bt_name_opt = FXButton.new(toolbar, "Nomi\nGiocatori\tNomi Giocatori\tNomi Giocatori", icon_nomi,nil, 0,ICON_BEFORE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    bt_name_opt.connect(SEL_COMMAND, method(:bt_playernames_options))
    
    # other options
    icon_others = owner.icons_app[:options]
    bt_other_opt = FXButton.new(toolbar, "Altre\nopzioni\tAltre opzioni\tAltre opzioni", icon_others,nil, 0,ICON_BEFORE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    bt_other_opt.connect(SEL_COMMAND, method(:bt_other_options))
    
    # network options
    lbl_net = FXLabel.new(main_vertical, "Rete:", nil, JUSTIFY_LEFT|LAYOUT_FILL_X)
    lbl_net.backColor = bckcolor_lbls
    lbl_net.textColor = color_label
    
    toolbnet = FXToolBar.new(main_vertical, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
    icon_proxy = nil#owner.icons_app[:card_ass]
    
    # proxy
    #bt_proxy = FXButton.new(toolbnet, "Proxy\tProxy\tProxy", icon_proxy,nil, 0,ICON_BEFORE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    #bt_proxy.connect(SEL_COMMAND, method(:bt_proxy_options))
    
    # generic network
    icon_netwgeneric = owner.icons_app[:icon_network]
    bt_netwgeneric = FXButton.new(toolbnet, "Opzioni\nRete\ttOpzioni Rete\tOpzioni Rete", icon_netwgeneric,nil, 0,ICON_BEFORE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED,0, 0, 0, 0, 10, 10, 5, 5)
    bt_netwgeneric.connect(SEL_COMMAND, method(:bt_retegeneric_options))
    
  end
  
  ##
  # Card options menu
  def bt_card_options(sender, sel, ptr)
    dlg = CardsOptionsDlg.new(self, @curr_settings, @cupera_gui )
    dlg.execute
  end
  
  ##
  # Other options dialogbox
  def bt_other_options(sender, sel, ptr)
    dlg = OtherOptionsDlg.new(self, @curr_settings, @cupera_gui )
    dlg.execute
  end
  
  ##
  # Players name options
  def bt_playernames_options(sender, sel, ptr)
    dlg = NamesOptionsDlg.new(self, @curr_settings, @cupera_gui )
    dlg.execute
  end
  
  ##
  # Proxy options
  def bt_proxy_options(sender, sel, ptr)
    dlg = ProxyOptionsDlg.new(self, @curr_settings, @cupera_gui )
    dlg.execute
  end
  
  ##
  # Network options
  def bt_retegeneric_options(sender, sel, ptr)
    dlg = NetwGenOptionsDlg.new(self, @curr_settings, @cupera_gui )
    dlg.execute
  end
  
end#end