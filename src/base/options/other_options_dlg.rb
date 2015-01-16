#file: other_options_dlg.rb

require 'basic_dlg_options_setter'

class OtherOptionsDlg < BasicDlgOptionsSetter
  def initialize(owner, settings, cupera_gui)
    @cupera_gui = cupera_gui
    super(owner, "Altre opzioni",settings,@cupera_gui, 30, 30, 500, 300)  
  end
  
  ##
  # Building the option dialogbox. Called during BasicDlgOptionsSetter.initialize
  # main_vertical: vertical frame where to build all child controls
  def on_build_vertframe(main_vertical)
    hf = FXHorizontalFrame.new(main_vertical, LAYOUT_RIGHT|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    checkButton = FXCheckButton.new(hf, "Suono durante la partita\tSuono durante la partita")
    @sound_on_game = @settings["sound"][:use_sound_ongame]
    checkButton.checkState = @sound_on_game
    checkButton.connect(SEL_COMMAND) do |sender, sel, checked|
      if checked
        @sound_on_game = true
      else
        @sound_on_game = false
      end
    end
  end
  
  def set_settings
    @settings["sound"][:use_sound_ongame] = @sound_on_game 
    @cupera_gui.refresh_settings
  end
  
end #end OtherOptionsDlg
