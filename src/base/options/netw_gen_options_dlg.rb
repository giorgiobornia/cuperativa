#file: netw_gen_options_dlg.rb

require 'basic_dlg_options_setter'

##
# Generic network options
class NetwGenOptionsDlg < BasicDlgOptionsSetter
  
  def initialize(owner, settings, cupera_gui)
    @cupera_gui = cupera_gui
    super(owner, "Opzioni gioco in rete",settings,@cupera_gui, 30, 30, 500, 300)  
  end
  
  ##
  # Building the option dialogbox. Called during BasicDlgOptionsSetter.initialize
  # main_vertical: vertical frame where to build all child controls
  def on_build_vertframe(main_vertical)
    #hf = FXHorizontalFrame.new(main_vertical, LAYOUT_RIGHT|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    hf = FXVerticalFrame.new(main_vertical,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    checkButton = FXCheckButton.new(hf, "Suono inizio partita\tSuono inizio partita in rete")
    @sound_initial_game = @settings["sound"][:play_intro_netwgamestart]
    checkButton.checkState = @sound_initial_game
    checkButton.connect(SEL_COMMAND) do |sender, sel, checked|
      if checked
        @sound_initial_game = true
      else
        @sound_initial_game = false
      end
    end
    # auto create default game
    checkButton = FXCheckButton.new(hf, "Crea gioco preferito al login\tCrea gioco preferito al login")
    @create_def_game = @settings["session"][:auto_create_game]
    checkButton.checkState = @create_def_game
    checkButton.connect(SEL_COMMAND) do |sender, sel, checked|
      if checked
        @create_def_game = true
      else
        @create_def_game = false
      end
    end
  end
  
  def set_settings
    @settings["sound"][:play_intro_netwgamestart] = @sound_initial_game
    @settings["session"][:auto_create_game] = @create_def_game 
  end
  
end #end NetwGenOptionsDlg