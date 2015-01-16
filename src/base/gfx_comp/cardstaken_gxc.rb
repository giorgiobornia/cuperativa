#file: cardstaken_gxc.rb


##
# Cards taken graphic component
class CardsTakenGraph < ComponentBase
  attr_accessor :offset_left
  
  def initialize(gui, gfx, font, max_num_card)
    super(27)
    
    @comp_name = "CardsTakenGraph"
    # widgets for last cards taken
    @cardslasttaken_todisp = []
    # info for user last card taken
    @taken_card_info_last = {} 
    @widget_list_clickable = []
    @player_gfx_info = {}
    # cards taken by players as small deck image with points
    @holddecks_todisp = {}
    @font = font
    @text_enabled = true
    @max_num_card = max_num_card
    @cupera_gui = gui
    @gfx_res = gfx
    @timeout_lastcardshow = 1200
    @offset_left = 0
    @taken_card_infotag = {}
  end
  
  def reset_points
    @holddecks_todisp.each_value do |ele|
      ele.visible = false
      ele.points = 0
    end
  end
  
  ##
  # Adjourn player points: add points to the current player points
  def adjourn_points(player, points)
    player_sym = player.name.to_sym
    return unless @holddecks_todisp[player_sym]
    @holddecks_todisp[player_sym].visible = true
    @holddecks_todisp[player_sym].points += points
  end
  
  ##
  # Replace points on the deck with the given value 
  # points: new points
  def set_player_points(player, points)
    # adjourn points
    pl_sym = player.name.to_sym
    @holddecks_todisp[pl_sym].visible = true
    @holddecks_todisp[pl_sym].points = points
  end
  
  def build_with_info(player_name, info_tag)
    player_sym = player_name.to_sym
    img = @image_gfx_resource[:points_deck_img]
    color = Fox.FXRGB(255, 255, 255)
    @taken_card_infotag[player_sym] = info_tag
    
    takencard_gfx_created = TakenCardsGfx.new(0,0, img, color,0,0, 0, false)
    # info for click on taken deck
    takencard_gfx_created.creator = self
    takencard_gfx_created.data_custom[:player_sym] = player_sym
    @widget_list_clickable << takencard_gfx_created
    
    takencard_gfx_created.visible = false
    @player_gfx_info[player_sym] = {}
    @holddecks_todisp[player_sym]  = takencard_gfx_created  
    @player_gfx_info[player_sym][:taken_card] = takencard_gfx_created
    
    # create also cardsgfx to be shown when show last hand is request
    img_coperto = @image_gfx_resource[:coperto]
    @player_gfx_info[player_sym][:card_lasttaken_arr] = [] # gfxcards array for showing last taken cards
    @max_num_card.times do |ix|
      card_gfx = CardGfx.new(self, 0, 0, img_coperto, :coperto, ix, false )
      @cardslasttaken_todisp << card_gfx  
      @player_gfx_info[player_sym][:card_lasttaken_arr] << card_gfx
    end
    
    case @max_num_card
      when 2
        @ix_list_disp = [0,1]
      when 6 
        @ix_list_disp = [2,3,1,4,0,5]
      else
        @ix_list_disp = []
        @ix_list_disp = @max_num_card.times{|ix| @ix_list_disp << ix }
      end
    # adjust size
    resize_with_info(player_name)
  end
  
  def resize_with_info(player_name)
    player_sym = player_name.to_sym
    return unless @holddecks_todisp[player_sym]
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info = @taken_card_infotag[player_sym]
    anchor_element = info[:anchor_element]
    img = @image_gfx_resource[:points_deck_img]
    img_coperto = @image_gfx_resource[:coperto]
    xoffset = img_coperto.width + info[:intra_card_off]
    item_w = calculate_maxdeckwidth(xoffset)
    item_h = img_coperto.height + img.height
    x_pos = 0
    y_pos = 0
    if anchor_element != nil and
       model_canvas_gfx.info[anchor_element] != nil
       anch_w = model_canvas_gfx.info[anchor_element][:width]
       anch_h = model_canvas_gfx.info[anchor_element][:height]
       anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
       anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
       pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       x_pos = pos_x
       y_pos = pos_y
    end
    
    
    x_txt = x_pos + img.width / 2 - 10
    y_txt = y_pos + img.height / 2 + 7
    
    #p player_sym
    takencard_gfx_created = @holddecks_todisp[player_sym]
    takencard_gfx_created.pos_x = x_pos
    takencard_gfx_created.pos_y = y_pos
    takencard_gfx_created.x_txt = x_txt
    takencard_gfx_created.y_txt = y_txt
    
    # cards for last hand taken
    count = 0
    x_swtaken_ini =  x_pos - (@ix_list_disp.size * img_coperto.width) / 2
    x_swtaken_ini += xoffset
    y_swtaken_ini =  y_pos + 30 
    @player_gfx_info[player_sym][:card_lasttaken_arr].each do |card_gfx|
      card_gfx.pos_y = y_swtaken_ini
      card_gfx.pos_x = x_swtaken_ini + xoffset * count
      count += 1 
    end
  end
  
  def calculate_maxdeckwidth(xoffset)
    x_fin = 0
    @max_num_card.times do |ix|
      x_fin = ix * xoffset
    end
    return x_fin
  end
  
  ##
  # Build card taken placeholder
  def build(player)
    player_sym = player.name.to_sym
    pl_type =  player.type
    img = @image_gfx_resource[:points_deck_img]
    color = Fox.FXRGB(255, 255, 255)
    
    takencard_gfx_created = TakenCardsGfx.new(0,0, img, color,0,0, 0, false)
    # info for click on taken deck
    takencard_gfx_created.creator = self
    takencard_gfx_created.data_custom[:player_sym] = player_sym
    @widget_list_clickable << takencard_gfx_created
    
    @player_gfx_info[player_sym] = {}
    @holddecks_todisp[player_sym]  = takencard_gfx_created  
    @player_gfx_info[player_sym][:taken_card] = takencard_gfx_created
    
    # create also cardsgfx to be shown when show last hand is request
    img_coperto = @image_gfx_resource[:coperto]
    @player_gfx_info[player_sym][:card_lasttaken_arr] = [] # gfxcards array for showing last taken cards
    @max_num_card.times do |ix|
      card_gfx = CardGfx.new(self, 0, 0, img_coperto, :coperto, ix, false )
      @cardslasttaken_todisp << card_gfx  
      @player_gfx_info[player_sym][:card_lasttaken_arr] << card_gfx
    end
    
    case @max_num_card
      when 2
        @ix_list_disp = [0,1]
      when 6 
        @ix_list_disp = [2,3,1,4,0,5]
      else
        @ix_list_disp = []
        @ix_list_disp = @max_num_card.times{|ix| @ix_list_disp << ix }
      end
    # adjust size
    resize(player)
  end #end build
  
  ##
  # Resize small symbol for taken cards
  def resize(player)
    player_sym = player.name.to_sym
    pl_type =  player.type
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info_lbl = model_canvas_gfx.info_label_player_get(player_sym)
    img = @image_gfx_resource[:points_deck_img]
    img_coperto = @image_gfx_resource[:coperto]
    
    y_pos = info_lbl[:y] + 20
    x_pos = info_lbl[:x]
    
    xoffset = img_coperto.width + 5
    y_swtaken_ini =  y_pos + 30
    x_swtaken_ini =  x_pos - (img_coperto.width + xoffset) - 30
    
    if pl_type == :human_local
      x_pos = info_lbl[:x]
      y_pos = info_lbl[:y] - (30 + img.height)
      y_swtaken_ini =  y_pos - (30 + img_coperto.height)
    end
    
    x_txt = x_pos + img.width / 2 - 10
    y_txt = y_pos + img.height / 2 + 7
    
    takencard_gfx_created = @holddecks_todisp[player_sym]
    takencard_gfx_created.pos_x = x_pos
    takencard_gfx_created.pos_y = y_pos
    takencard_gfx_created.x_txt = x_txt
    takencard_gfx_created.y_txt = y_txt
    
    # cards for last hand taken
    count = 0
    x_swtaken_ini =  x_pos - (@ix_list_disp.size * img_coperto.width) / 2
    x_swtaken_ini += @offset_left 
    @player_gfx_info[player_sym][:card_lasttaken_arr].each do |card_gfx|
      card_gfx.pos_y = y_swtaken_ini
      card_gfx.pos_x = x_swtaken_ini + xoffset * count
      count += 1 
    end
  end
  
  def on_mouse_lclick(event)
    bres = false
    @widget_list_clickable.each do |item|
      if item.visible
        bres = item.on_mouse_lclick(event.win_x, event.win_y)
        ele_clickable = true
        break if bres
      end
    end
    return bres
  end
  
  def draw(dc)
    # draws deck elements for card taken
    @holddecks_todisp.each_value do |ele|
      #p ele.visible
      if ele.visible
        #p ele
        dc.drawIcon(ele.image, ele.pos_x, ele.pos_y)
        if @text_enabled
          dc.font = @font
          dc.foreground = ele.font_color
          dc.drawText(ele.x_txt, ele.y_txt, ele.points.to_s )
        end
      end
    end
    
    # draw cards for last hand cards taken
    @cardslasttaken_todisp.each do |v|
      v.draw_card(dc) if v
    end
    
  end #end draw
  
  ###
  # User click on card taken
  def evgfx_click_on_takencard(sender)
    player_sym = sender.data_custom[:player_sym]
    return unless @taken_card_info_last[player_sym]
    @log.debug "Click on card taken with  #{@taken_card_info_last[player_sym][:taken_cards]}"
    
    unless @taken_card_info_last[player_sym][:taken_cards]
      # ignore click because we are already showing one
      @log.debug("Ignore click because no cards are taken")
      return
    end
      
    if @taken_card_info_last[:state] == :showing  
      # ignore click because we are already showing one
      @log.debug("Ignore click because already showing")
      return
    end
    
    #p "Click on deck for #{plsym}"
    count = 0
    ix_list = @ix_list_disp#[2,3,1,4,0,5] # use index list to show first card in the middle
    @taken_card_info_last[player_sym][:taken_cards].each do |cd_item|
      ix = ix_list[count]
      card_gfx = @player_gfx_info[player_sym][:card_lasttaken_arr][ix]
      card_gfx.change_image(@gfx_res.get_card_image_of(cd_item), cd_item)
      card_gfx.visible = true
      count += 1
      break if count >= ix_list.size or count >= @player_gfx_info[player_sym][:card_lasttaken_arr].size
    end
    @taken_card_info_last[:state] = :showing
    @taken_card_info_last[:curr_playersym_shown] = player_sym
    @cupera_gui.registerTimeout(@timeout_lastcardshow, :onTimeoutLastCardTakenShow1, self)
    # refresh the display
    @cupera_gui.update_dsp 
  end
  
  ##
  # Timeout for card taken show timeout expired
  def onTimeoutLastCardTakenShow1
    @log.debug("Timeout onTimeoutLastCardTakenShow")
    @taken_card_info_last[:state] = :idle
    player_sym = @taken_card_info_last[:curr_playersym_shown]
    @player_gfx_info[player_sym][:card_lasttaken_arr].each{|e_gfx| e_gfx.visible = false}
    # refresh the display
    @cupera_gui.update_dsp 
  end
  
  ##
  # Initialize information for last card taken
  def init_state(players)
    reset_points
    @taken_card_info_last[:state] = :idle
    players.each do |pl_match|
      player_label = pl_match.name.to_sym
      #each player needs last taken cards information
      @taken_card_info_last[player_label] = {} 
    end
  end
 
  ##
  # Set cards take for the given player
  def set_lastcardstaken(player, cards_taken)
    player_sym = player.name.to_sym
    @taken_card_info_last[player_sym][:taken_cards] = []
    cards_taken.each{|e| @taken_card_info_last[player_sym][:taken_cards] << e}
  end
  
  
end #end CardsTakenGraph

