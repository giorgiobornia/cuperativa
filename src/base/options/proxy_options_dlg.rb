#file: proxy_options_dlg.rb

require 'basic_dlg_options_setter'

##
# Players names setter
class ProxyOptionsDlg < BasicDlgOptionsSetter
  
  def initialize(owner, settings, cupera_gui)
    @cupera_gui = cupera_gui
    super(owner, "Proxy",settings,@cupera_gui, 30, 30, 500, 300)  
  end
  
  ##
  # Building the option dialogbox. Called during BasicDlgOptionsSetter.initialize
  # main_vertical: vertical frame where to build all child controls
  def on_build_vertframe(main_vertical)
    #@widg_players_names = []
    #ix = 1
    #@settings["players"].each do |vv|
    #hf = FXHorizontalFrame.new(main_vertical, LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
    #FXLabel.new(hf, "Giocatore #{ix}:", nil, JUSTIFY_RIGHT|LAYOUT_FILL_X|LAYOUT_CENTER_Y)
    #txt_f =  FXTextField.new(hf, 2, nil, 0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
    #txt_f.text = vv[:name].to_s
    #@widg_players_names << txt_f
    #ix += 1 
    #end
  end
  
  def set_settings
    ## update players on table
    #@widg_players_names.each_index do |ix|
    #@settings["players"][ix][:name] = @widg_players_names[ix].text
    #end
    #@cupera_gui.set_players_ontable
  end
  
end#end ProxyOptionsDlg