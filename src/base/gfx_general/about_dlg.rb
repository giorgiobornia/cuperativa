# file: about_dlg.rb
# Dialogbox about


require 'rubygems'
require 'fox16'
require 'uri'
require 'base/core/cup_strings'
require 'web_launcher'

#######################################################################
#######################################################################
##################################################### DLGABOUT ########
##
# Info about dialogbox
class DlgAbout < FXDialogBox
  
  def initialize(owner, name, version)
    super(owner, "Informazioni sulla Cuperativa", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE,
      0, 0, 0, 0, 0, 0, 0, 0, 4, 4)
    
    @cup_gui = owner
    str_games_list = ""
    supported_game_map = @cup_gui.get_supported_games
    supported_game_map.each_value{|v| str_games_list += "  * #{v[:name]}\n"}
    str_text = u"Cuperativa U+00e8 un programma per giocare a carte da soli o in rete.\n"
    str_text +=     "Giochi diponibili:\n"
    str_text +=    "#{str_games_list}" 
    str_text +=    "\n"
    str_text +=  u"#{version}\nby Igor Sarzi Sartori U+00a9 2006-2010\n"        
    
    main_vertical = FXVerticalFrame.new(self, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    lbl_text = FXLabel.new(main_vertical, str_text, nil, JUSTIFY_LEFT|LAYOUT_FILL_X,
                            0, 0, 0, 0, 30, 30, 30, 30)
    
    # bottons for links
    
    btframe = FXVerticalFrame.new(main_vertical, 
                           LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    
    # home web
    home_bt = FXButton.new(btframe, "cuperativa.invido.it", @cup_gui.icons_app[:home], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    home_bt.connect(SEL_COMMAND, method(:go_home))
    home_bt.iconPosition = (home_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    # forum
    forum_bt = FXButton.new(btframe, "Forum", @cup_gui.icons_app[:forum], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    forum_bt.iconPosition = (forum_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    forum_bt.connect(SEL_COMMAND, method(:go_forum))
    
    # help
    help_bt = FXButton.new(btframe, "Guida", @cup_gui.icons_app[:help], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    help_bt.iconPosition = (forum_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    help_bt.connect(SEL_COMMAND, method(:go_help))
    
    # email
    email_bt = FXButton.new(btframe, "Email", @cup_gui.icons_app[:mail], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    email_bt.iconPosition = (email_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    email_bt.connect(SEL_COMMAND, method(:go_email)) 
    
    # ----------- bottom part --------------
    FXHorizontalSeparator.new(main_vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
    btframe = FXHorizontalFrame.new(main_vertical, 
                                    LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH )
    
    ok_bt = FXButton.new(btframe, "OK", @cup_gui.icons_app[:ok], self, FXDialogBox::ID_ACCEPT,
      LAYOUT_CENTER_X | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    ok_bt.iconPosition = (ok_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
  end
  
  ##
  # Workaround for windows
  def goto_generic_url(url)
    if $g_os_type == :win32_system
      Thread.new{
        system "start \"test\" \"#{url}\""
      }
    else
      LanciaApp::Browser.run(url)
    end
  end
  
  ##
  # Go to invido.it home page
  def go_home(sender, sel, ptr)
    goto_generic_url("http://cuperativa.invido.it")
  end
  
  ##
  # Go to forum home page
  def go_forum(sender, sel, ptr)
    # using forum on briscola rubyforge
    #LanciaApp::Browser.run("http://rubyforge.org/forum/forum.php?forum_id=17763")
    goto_generic_url("http://cuperativa.invido.it/forums")
  end
  
  ##
  # View help
  def go_help(sender, sel, ptr)
    # using forum on briscola rubyforge
    #helppath = @cup_gui.get_help_path
    #LanciaApp::Browser.run(helppath)
    @cup_gui.mnu_cuperativa_help(0,0,0)
  end
  
  ##
  # Write email
  def go_email(sender, sel, ptr)
    # using forum on briscola rubyforge
    # On ubuntu /usr/bin/xdg-open is used
    #LanciaApp::Browser.run("mailto:6colpiunbucosolo@gmx.net")
    goto_generic_url("mailto:6colpiunbucosolo@gmx.net")
  end
end

