#file: crash_reporter.rb

if $0 == __FILE__
  require 'rubygems'
  require 'fox16'
  
  include Fox
end

$:.unshift File.dirname(__FILE__) + '/..'

require 'base/core/web_launcher'

#clipboard stuff
begin
  require 'win32/clipboard' 
  include Win32
rescue LoadError
  $g_os_type = :linux
end
#end clipboard


class CupCrashReporter < FXMainWindow
  def initialize(owner)
    super(owner, "Il programma Cuperativa ha un problema", nil, nil, DECOR_ALL, 50,50, 700, 500)
    self.connect(SEL_CLOSE, method(:onCmdQuit))
    
    @soggetto = "Errore%20nel%20programma%20Cuperativa"
    @body = "Questo l'errore trovato:%0AErrore in%0ASaluti!"
    
    #@body = "ciao"
    
    FXHorizontalSeparator.new(self, SEPARATOR_GROOVE|LAYOUT_FILL_X)
    vv_main = self
    toolbarShell = FXToolBarShell.new(self)
    toolbar = FXToolBar.new(vv_main, toolbarShell,LAYOUT_SIDE_TOP|LAYOUT_FILL_X, 0, 0, 0, 0, 3, 3, 0, 0)
    
    @icons_app = {}
    @icons_app[:icon_app] = loadIcon("icona_asso_trasp.png")
    @icons_app[:mail] = loadIcon("mail.png")
    @icons_app[:forum] = loadIcon("forum.png")
    
    #email 
    email_bt = FXButton.new(toolbar, "Invia errore per Email", @icons_app[:mail], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 30, 30, 4, 4)
    email_bt.iconPosition = (email_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    email_bt.connect(SEL_COMMAND, method(:go_email)) 
    
    
     # forum
    forum_bt = FXButton.new(toolbar, "Forum", @icons_app[:forum], self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    forum_bt.iconPosition = (forum_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    forum_bt.connect(SEL_COMMAND, method(:go_forum))
    #copy clipboard
    copy_bt = FXButton.new(toolbar, "Copia testo errore", nil, self, 0,
              LAYOUT_LEFT | FRAME_RAISED|FRAME_THICK , 0, 0, 0, 0, 30, 30, 4, 4)
    #copy_bt.iconPosition = (copy_bt.iconPosition|ICON_BEFORE_TEXT) & ~ICON_AFTER_TEXT
    
    copy_bt.connect(SEL_COMMAND, method(:copy_text))
    
    
    #text area
    @logText = FXText.new(vv_main, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @logText.editable = false
    
    
    setIcon(@icons_app[:icon_app])
    
  end
  
  def set_error_text(text)
    @logText.text = text
  end
  
  # Load the named icon from a file
  def loadIcon(filename)
    begin
      dirname = File.join(get_resource_path, "icons")
      filename = File.join(dirname, filename)
      icon = nil
      File.open(filename, "rb") { |f|
        if File.extname(filename) == ".png"
          icon = FXPNGIcon.new(getApp(), f.read)
        elsif File.extname(filename) == ".gif"
          icon = FXGIFIcon.new(getApp(), f.read)
        end
      }
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end
  
  # Provides the resource path
  def get_resource_path
    res_path = File.dirname(__FILE__) + "/../../res"
    return File.expand_path(res_path)
  end
 
  
  def onCmdQuit(sender, sel, ptr)
    getApp().exit(0)
  end
  
  def prepare_soggetto
    #@body = "Questo l'errore trovato:%0AErrore in%0ASaluti!"
    preamb = "Carissimo supporto della Cuperativa,%0A%0A"
    preamb += "vorrei segnalare il seguente errore: %0A"
    body = @logText.text.gsub("\n", "%0A")
    fine = "%0A%0ATanti saluti"
    @body = preamb + body + fine
  end
  
  def copy_text(sender, sel, ptr)
    if $g_os_type == :win32_system
      aString =  @logText.text
      Clipboard.set_data(aString) 
    end
  end
  
  ##
  # Write email
  def go_email(sender, sel, ptr)
    # using forum on briscola rubyforge
    # On ubuntu /usr/bin/xdg-open is used
    prepare_soggetto
    url = "mailto:6colpiunbucosolo@gmx.net?body=#{@body}&subject=#{@soggetto}"
    goto_generic_url(url)
  end
  
   def go_forum(sender, sel, ptr)
    # using forum on briscola rubyforge
    goto_generic_url("http://http://cuperativa.invido.it/forums/2")
  end
  
  ##
  # Workaround for windows
  def goto_generic_url(url)
    if $g_os_type == :win32_system
      cmd = "start \"test\" \"#{url}\""
      Thread.new{
        
        system cmd
      }
    else
      LanciaApp::Browser.run(url)
    end
  end
  
end

if $0 == __FILE__
  $g_os_type = :win32_system
  
  theApp = FXApp.new("TestReporter", "FXRuby")
  crash_rep = CupCrashReporter.new(theApp)
  
  crash_rep.set_error_text("Orrore in \n Cup mod 12\n34 errori")
  theApp.create()
  
  crash_rep.create
  crash_rep.show  
    
  theApp.run
end