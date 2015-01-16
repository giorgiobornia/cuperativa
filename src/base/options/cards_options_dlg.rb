#file: cards_options_dlg.rb

require 'basic_dlg_options_setter'

##
# Card deck option setter
class CardsOptionsDlg < BasicDlgOptionsSetter
  
  def initialize(owner, settings, cup_gui)
    @cupera_gui = cup_gui
    @resource_path = @cupera_gui.get_resource_path
    super(owner, "Mazzi di carte Cuperativa",settings,@cupera_gui, 30, 30, 500, 300)  
  end
  
  ##
  # Overwrite deck information using cutom information on each deck
  def load_deck_infos
    # p @deck_infos
    dirname = File.join(@resource_path, 'carte')
    Dir.foreach(dirname) do |filename|
      path_cand = File.join(dirname , filename)
      if File.directory?(path_cand)
        #exams directories
        if (filename != "." && filename != "..")
          # potential deck folder
          deck_info_yaml = File.join(path_cand, 'mazzo_info.yaml')
          if File.exist?(deck_info_yaml)
            opt = YAML::load_file( deck_info_yaml )
            if opt and opt.class == Hash
              key = opt[:key].to_sym # key is a symbol, path is a string
              @deck_infos[key] = {:name => opt[:name], :path => opt[:key], :color_trasp => opt[:color_trasp]}
            end
          end
        end
      end
    end
    #p @deck_infos
  end
  
  ##
  # Building the option dialogbox. Called during BasicDlgOptionsSetter.initialize
  # main_vertical: vertical frame where to build all child controls
  def on_build_vertframe(main_vertical)
    @curr_deck_key = @settings["deck_name"]
    
    @deck_infos =  {}
    # overwrite @deck_infos using custom mazzo_info.yaml
    load_deck_infos
    
    # option popup
    pane = FXPopup.new(self)
    ix_pane = 0
    @deck_infos.each do |k, v|
      opt = FXOption.new(pane, v[:name], nil, nil, 0, JUSTIFY_HZ_APART|ICON_AFTER_TEXT)
      opt.userData = k
      @deck_infos[k][:pane_ix] = ix_pane
      opt.connect(SEL_COMMAND) do |sender, sel, ptr|
        display_card_deck(sender.userData)
      end
      ix_pane += 1
    end
    @menu_deck_name = FXOptionMenu.new(main_vertical, pane, (FRAME_RAISED|FRAME_THICK|
        JUSTIFY_HZ_APART|ICON_AFTER_TEXT|LAYOUT_TOP|LAYOUT_LEFT))
    deck_info = @deck_infos[ @settings["deck_name"] ]
    # set pane to the current select deck name
    @menu_deck_name.setCurrentNo(deck_info[:pane_ix]) if deck_info
    
    #canvas to display demo cards
    @canvas_disp = FXCanvas.new(main_vertical, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT )
    @canvas_disp.connect(SEL_PAINT, method(:onCanvasPaint))
    @color_backround = Fox.FXRGB(50, 170, 10)
    #@color_backround = Fox.FXRGB(255, 255, 255)
    @canvas_disp.backColor =  @color_backround 
    
    @log = Log4r::Logger["coregame_log"] 
    
    init_deck(@settings["deck_name"])
  end
  
  ##
  # Apply the current settings
  def set_settings
    @settings["deck_name"] = @curr_deck_key if @curr_deck_key
  end
  
  ##
  # Init stuff in order to display a muster of the deck
  #lbl_deck: deck to be selected as key of @deck_infos (e.g. :piac)
  def init_deck(lbl_deck)
    # card gfx to display on the canvas
    @cards_todisp = []
    # deck images
    @cards_img = []
    color_trasp = FXRGB(0, 128, 0) #default transparent color
    if @deck_infos[lbl_deck]
      curr_deck_info = @deck_infos[lbl_deck]
      # yaml define trasparent color
      if curr_deck_info[:color_trasp] and curr_deck_info[:color_trasp].class == Array and curr_deck_info[:color_trasp].size == 3
        color_trasp = FXRGB(curr_deck_info[:color_trasp][0], curr_deck_info[:color_trasp][1], curr_deck_info[:color_trasp][2])
      end
    end
    load_cards_deck(lbl_deck.to_s, color_trasp)
    place_cards_to_display
  end
  
  ##
  # Load some cards from the given card folder
  def load_cards_deck(folder, color_trasp)
    @cards_img = []
    nomi_semi =  CoreGameBase.nomi_semi
    #folder_fullpath = File.dirname(__FILE__) + "/../../res/carte/#{folder}"
    folder_fullpath = File.join(@resource_path, "carte/#{folder}")
    folder = folder_fullpath.strip
    # card name are e.g.: 03_coppe.png
    index_list = [1, 3, 8, 10] # load only a small subset of cards
    index_list.each do |card_ix|
      card_fname = File.join(folder, "%02d_#{nomi_semi[0]}.png" % card_ix)
      #img = FXPNGIcon.new(getApp(), nil, Fox.FXRGB(0, 128, 0), IMAGE_KEEP|IMAGE_ALPHACOLOR )
      #img = FXPNGIcon.new(getApp(), nil, color_trasp, IMAGE_KEEP|IMAGE_ALPHACOLOR )
      img = FXPNGIcon.new(getApp, nil,
        IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
      FXFileStream.open(card_fname, FXStreamLoad) { |stream| img.loadPixels(stream) }
      img.blend(@color_backround)
      @cards_img << img
    end
    @cards_img.each{|e| e.create}
  rescue
    str = "Errore nel caricare l'immagine delle carte: #{$!}\n"
    str += "Mazzo subdir utilizzato: #{folder}\n"
    str += "Controllare l'opzione \"deck_name\" e che la subdir del mazzo siano corrette\n"
    @curr_deck_key = :piac #default card
    @log.error str
  end
  
  ##
  # Place cards on the canvas
  def place_cards_to_display
    @cards_todisp = []
    left_pl1_card = 20 
    #top_pl1_card = @canvas_disp.height - (img_card.height + 5)
    top_pl1_card = 30
    num_img = @cards_img.size - 1
    (0..num_img).each do |ix|
      img_card = @cards_img[ix]
      xoffset = img_card.width + 5
      x_fin = left_pl1_card + ix * xoffset
      cd = CardGfx.new(self, x_fin, top_pl1_card, img_card, :not_def, 1 )
      @cards_todisp << cd
    end
  end
  
  ##
  # Display a small set of the given deck
  # deck_key: deck key name on @deck_infos
  def display_card_deck(deck_key)
    if @deck_infos[deck_key]
      @curr_deck_key = deck_key
      deck_info = @deck_infos[deck_key]
      @menu_deck_name.setCurrentNo(deck_info[:pane_ix])
      init_deck(deck_key)
      @canvas_disp.update
    end
  end
  
  ##
  # display some cards of the selected deck
  def onCanvasPaint(sender, sel, event)
    dc = FXDCWindow.new(@canvas_disp, event)
    dc.foreground = @canvas_disp.backColor
    dc.fillRectangle(0, 0, @canvas_disp.width, @canvas_disp.height)
    @cards_todisp.each do |v|
      dc.drawImage(v.image, v.pos_x, v.pos_y)
    end
  end
  
end#end CardsOptionsDlg