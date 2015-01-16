#file: cardsplayer_gfxc.rb

#########################################################
##################################### CardsPlayersGraph
#########################################################

##
# Manage graphic cards for each player
class CardsPlayersGraph < ComponentBase
  attr_reader :last_cardset_info
  attr_accessor :offset_left
  
  def initialize(gui, gfx, num_cards)
    super(25)
    @comp_name = "CardsPlayersGraph" 
    @cards_player_todisp = {}
    @cards_distr_animated = {}
    @widget_list_clickable = []
    @last_cardset_info = {}
    # gfx engine that hosted this cards component
    @gfx_res = gfx
    @numcards = num_cards
    @app_owner = gui
    @distr_card_stack = []
    @timeout_animation_carddistr = 20
    @log = Log4r::Logger.new("coregame_log::CardsPlayersGraph") 
    @offset_left = 0
    @sound_manager = @app_owner.sound_manager
    @jump_animation_distr = false
    @animation_state_distr = :init
    @cards_player_infotag = {}
  end
  
  
  ##
  # Change the number of cards
  def set_new_number_ofcards(num_cards)
    @numcards = num_cards
  end
  
  # if val is true, distr animation is jumped
  def set_jump_animation_distr(val)
     @jump_animation_distr = val
  end
  
  ##
  # Set card images to the player cards
  # carte_player: label cards array
  def set_cards_player(player_sym, carte_player)
    @log.debug("set_cards_player: #{player_sym}, #{carte_player}")
    cards_player_images = @cards_player_todisp[player_sym]
    z_ord_off = 0
    cards_player_images.each_index do |ix|
      cards_player_images[ix].change_image( @gfx_res.get_card_image_of(carte_player[ix]), 
                                           carte_player[ix])
      cards_player_images[ix].visible = true
      cards_player_images[ix].z_order = cards_player_images[ix].z_order +  z_ord_off
      z_ord_off += 1
    end
  end
  
  def get_cards_player(player_sym)
    cards_player_images = @cards_player_todisp[player_sym]
    cards = []
    cards_player_images.each do |card_gfx|
      if card_gfx.visible == true
        cards << card_gfx.lbl
      end
    end
    return cards
  end
  
  ##
  # Set all player cards as decked. As deck  resource_sym is used
  def set_allcards_player_decked(player_sym, resource_sym)
    cards_opponent_images = @cards_player_todisp[player_sym]
    cards_opponent_images.each do |card_gfx| 
      card_gfx.change_image(@image_gfx_resource[resource_sym], resource_sym)
      card_gfx.visible = false
    end
  end
  
  ##
  # Set an empty card as decked. As decked the resource_sym is used
  def set_card_empty_player_decked(player_sym, resource_sym)
    cards_opponent_images = @cards_player_todisp[player_sym]
    cards_opponent_images.each do |card_gfx|
      if card_gfx.lbl == :vuoto 
        card_gfx.change_image(@image_gfx_resource[resource_sym], resource_sym)
        break
      end
      # card played is not visible
      unless card_gfx.visible
        card_gfx.visible = true
        break
      end 
    end
  end
  
  ##
  # Look for lblcard_onhand on card of player_sym and swap it with lblcard_new
  def swap_card_player(player_sym, lblcard_onhand, lblcard_new)
    @cards_player_todisp[player_sym].each do |cardgfx|
      #find card to be changed
      if cardgfx.lbl == lblcard_onhand
        # card found in the hand of player (e.g. 7 of briscola), change it with the lblcard_new
        cardgfx.change_image( @gfx_res.get_card_image_of(lblcard_new), lblcard_new )
        break
      end
    end
  end
  
  ##
  # Set an empty card with an image. Image is defined from cardlbl label
  def set_card_empty_player(player_sym, cardlbl)
    set_card_empty_player_visible(player_sym, cardlbl, true)
  end
  
  def set_card_empty_player_visible(player_sym, cardlbl, visible)
    cards_player_images = @cards_player_todisp[player_sym]
    cards_player_images.each do |card_img|
      if card_img.lbl == :vuoto
        card_img.change_image( @gfx_res.get_card_image_of(cardlbl), cardlbl)
        card_img.visible = visible
        break
      end
    end
  end
  
  ##
  # Set a card in player hand as invisible
  def card_invisible(player_sym, lbl_card)
    @log.debug "cardsplayer_gfxc: card invisible #{lbl_card} on player #{player_sym}"
    bfound = false
    @cards_player_todisp[player_sym].each do |cardgfx|
      #p cardgfx.lbl
      if lbl_card == cardgfx.lbl
        # card found in the hand of player, mark it as played
        cardgfx.change_image( @gfx_res.get_cardsymbolimage_of(:vuoto), :vuoto)
        cardgfx.visible = false
        @last_cardset_info[:pos_x] = cardgfx.pos_x
        @last_cardset_info[:pos_y] = cardgfx.pos_y
        #@log.debug "cardsplayer_gfxc: card found #{cardgfx.lbl}"
        bfound = true
        break
      end
    end
    if !bfound
      @log.warn "cardsplayer_gfxc: card #{lbl_card} not found "
    end
  end
  
  ##
  # Set a card as invisible from the cards belong the player player_sym
  def card_invisible_rnd_decked(player_sym)
    pos_cop_to_play = 0
    count_cop = 0
    @cards_player_todisp[player_sym].each do |cfx|
      #count_cop += 1  if cfx.lbl == :coperto and cfx.visible
      count_cop += 1  if cfx.visible
    end
    if count_cop > 0
      # use a random number for the position
      pos_cop_to_play = rand(count_cop)
    end
    curr_pos_cop = 0
    card_found = false
    @cards_player_todisp[player_sym].each do |cardgfx|
      #p cardgfx.lbl
      #if cardgfx.lbl == :coperto and cardgfx.visible
      if cardgfx.visible
        if pos_cop_to_play == curr_pos_cop
          # coperto to be played
          cardgfx.visible = false
          @last_cardset_info[:pos_x] = cardgfx.pos_x
          @last_cardset_info[:pos_y] = cardgfx.pos_y
          card_found = true
          break
        end
        curr_pos_cop += 1
      end
    end
    unless card_found
      @log.error "card_invisible_rnd_decked: no card played"
    end 
  end
  
  def resize_get_xoffset(img_coperto)
    return img_coperto.width + 5
  end
  
  ##
  # Component resize. This is called usually when the canvas is resized.
  def resize(player)
    #@log.debug "Resize CardsPlayersGraph component pos = #{player.position}"
    player_sym = player.name.to_sym
    img_coperto = @image_gfx_resource[:coperto]
    #xoffset = img_coperto.width + 5  
    xoffset = resize_get_xoffset(img_coperto)
    
    canvas_gfx = @gfx_res.model_canvas_gfx
    left_pl1_card = (canvas_gfx.info[:canvas][:width] - (@numcards * img_coperto.width + 50))/ 2
    top_pl1_card = 10
    if player.position == :sud
      # local human player, correct the top position
      top_pl1_card = canvas_gfx.info[:canvas][:height] - 
                 (img_coperto.height + canvas_gfx.info[:info_gfx_coord][:y_off_plg_card])
    elsif player.position == :nord
      # on nord player, we have overlapped cards
      xoffset = 20
      left_pl1_card = (canvas_gfx.info[:canvas][:width] - (@numcards * img_coperto.width - @numcards * 40))/ 2
    end
    left_pl1_card = 0 if left_pl1_card < 0
    left_pl1_card += @offset_left
    
    x_init = left_pl1_card
    x_fin = x_init 
    y_init = top_pl1_card
    ix = 0
    @cards_player_todisp[player_sym].each do |single_gfx_card|
      x_fin = left_pl1_card + ix * xoffset
      single_gfx_card.pos_x = x_fin
      single_gfx_card.pos_y = top_pl1_card
      ix += 1
    end
    # store information about cards on player hands
    if player.position == :sud
      x_fin += img_coperto.width
      
      canvas_gfx.info[:deck_gui_pl] = {:x => x_init, :y => y_init, 
                          :w => x_fin - x_init, :h => img_coperto.height}
      #p "set deck_gui_pl #{canvas_gfx.info[:deck_gui_pl]}"
    end
    
  end
  
  # Le funzioni build_with_info e resize_with_info sono una miglioria alle build e resize
  # Queste nuove usano l'hash info_tag per ancorare la posizione ad un elemento
  # già creato. Così si ottiene un posizionamento relativo senza avere numeri
  # magici in questo file e assunzioni che possono variare da gioco a gioco
  
  def build_with_info(player_name, img_coperto_sym, are_clickable, info_tag)
    player_sym = player_name.to_sym
    img_coperto = nil
    img_coperto = @image_gfx_resource[img_coperto_sym]
    @cards_distr_animated[player_sym] = []
    @cards_player_todisp[player_sym] = []
    @cards_player_infotag[player_sym] = {:infotag => info_tag, :img_coperto_sym => img_coperto_sym}
    (0..@numcards-1).each do |ix|
      gfx_card_new = CardGfx.new(@gfx_res, 0, 0, img_coperto, :coperto, 1 )
      gfx_card_new.visible = false
      gfx_card_new.type = :player
      @cards_player_todisp[player_sym] << gfx_card_new
      gfx_deck_small = CardGfx.new(@gfx_res, 0, 0, @image_gfx_resource[:card_opp_img], :card_opp_img, 1 )
      @cards_distr_animated[player_sym] << gfx_deck_small
      if are_clickable
        @widget_list_clickable << gfx_card_new
      end
    end
    resize_with_info(player_name)
  end
  
  def resize_with_info(player_name)
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    player_sym = player_name.to_sym
    info = @cards_player_infotag[player_sym][:infotag]
    # info una struttura del tipo: 
    #:img_coperto_sym => :coperto,
    #:infotag =>{:x => {:type => :center_anchor_horiz, :offset => 0},
    #           :y => {:type => :bottom_anchor, :offset => -40},
    #           :anchor_element => :canvas, :intra_card_off => -10 }
    anchor_element = info[:anchor_element]
    res_sym = @cards_player_infotag[player_sym][:img_coperto_sym]
    img_coperto = @image_gfx_resource[res_sym]
    xoffset = img_coperto.width + info[:intra_card_off]
    item_w = calculate_deckwidth(@cards_player_todisp[player_sym], xoffset)
    item_h = img_coperto.height
    left_pl1_card = 0
    top_pl1_card = 0
    if anchor_element != nil and
       model_canvas_gfx.info[anchor_element] != nil
       #p model_canvas_gfx.info[anchor_element]
       anch_w = model_canvas_gfx.info[anchor_element][:width]
       anch_h = model_canvas_gfx.info[anchor_element][:height]
       anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
       anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
       pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       left_pl1_card = pos_x
       top_pl1_card = pos_y
    end
    x_init = left_pl1_card
    x_fin = x_init 
    y_init = top_pl1_card
    ix = 0
    @cards_player_todisp[player_sym].each do |single_gfx_card|
      x_fin = left_pl1_card + ix * xoffset
      single_gfx_card.pos_x = x_fin
      single_gfx_card.pos_y = top_pl1_card
      ix += 1
    end
    
    canvas_key = "deck_#{player_name}".to_sym
    model_canvas_gfx.info[canvas_key] =  {:x => x_init, :y => y_init, 
                          :w => x_fin - x_init, :h => item_h}
    
  end
  
  def calculate_deckwidth(card_gfx_arr, xoffset)
    x_fin = 0
    ix = 0
    card_gfx_arr.each do |single_gfx_card|
      x_fin = ix * xoffset
      ix += 1
    end
    return x_fin
  end
  
  
  ##
  # Build the player card hand
  def build(player)
    @log.debug "Build cards of player #{player.name}, num: #{@numcards}"
    player_sym = player.name.to_sym
    img_coperto = nil
    if player.position == :sud
      # gui player
      img_coperto = @image_gfx_resource[:coperto]
    else
      # opponent
      img_coperto = @image_gfx_resource[:card_opp_img]
    end
    @cards_distr_animated[player_sym] = []
    @cards_player_todisp[player_sym] = []
    (0..@numcards-1).each do |ix|
      gfx_card_new = CardGfx.new(@gfx_res, 0, 0, img_coperto, :coperto, 1 )
      gfx_card_new.visible = false
      gfx_card_new.type = :player
      gfx_card_new.data_info = player.position
      @cards_player_todisp[player_sym] << gfx_card_new
      # animation distr
      gfx_deck_small = CardGfx.new(@gfx_res, 0, 0, @image_gfx_resource[:card_opp_img], :card_opp_img, 1 )
      @cards_distr_animated[player_sym] << gfx_deck_small
      if player.position == :sud
        # we have only GUI player clickable cards
        @widget_list_clickable << gfx_card_new
      end 
    end
    
    # adjouts position based on the current canvas size
    resize(player)
  end
  
  ##
  # Remove player cards from clickable list
  def remove_cards_fromclickable
    @log.debug "Remove player cards from clickable list"
    # store as clickable cards on the table
    new_widg_list = [] 
    @widget_list_clickable.each do |clickable|
      if clickable.class != CardGfx
        # add to the new list elements that aren't CardGfx
        new_widg_list << clickable
      end
    end
    #@table_cards_gfx.each do |cardgfx|
    #  new_widg_list << cardgfx
    #end
    # now are human player cards removed from clickable list
    @widget_list_clickable = new_widg_list
    #p @widget_list_clickable
  end
  
  ##
  # Handle the left mouse click
  def on_mouse_lclick(event)
    #p "cards_players on_mouse_lclick"
    bres = false
    @widget_list_clickable.sort! {|x,y| y.z_order <=> x.z_order}
    @widget_list_clickable.each do |item|
      if item.visible
        #p item
        bres = item.on_mouse_lclick(event.win_x, event.win_y)
        ele_clickable = true
        break if bres
      end
    end
    return bres
  end
  
  ##
  # Draw the component
  def draw(dc)
    @cards_player_todisp.each_value do |cards_player|
      # process cards on player hand
      # sord gfxcard for z order
      cards_sorted = cards_player.sort{|x,y| x.z_order <=> y.z_order }
      cards_sorted.each do |v|
        v.draw_card(dc) if v.visible
      end
    end
    
    # card animation distribution
    @distr_card_stack.each do |v|
      v.draw_card(dc) if v
    end
  end
  
  ##
  # Define initial position of animated cards. It depends on deck information
  def init_position_ani_distrcards
    # animation of deck
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    x_deck_start = model_canvas_gfx.info[:deck_info][:x_deck_start]
    y_deck_start = model_canvas_gfx.info[:deck_info][:y_deck_start]
    return if x_deck_start == nil or y_deck_start == nil
    
    rest_x = model_canvas_gfx.info[:deck_info][:rest_x]
    rest_y = model_canvas_gfx.info[:deck_info][:rest_y]
    @cards_distr_animated.each_value do |arr_card_player|
      arr_card_player.each do |card_item|
        card_item.cd_data[:x_init] = x_deck_start + rest_x - 1
        card_item.cd_data[:y_init] = y_deck_start + rest_y - 1
      end
    end
  end
  
  ##
  # Start animation card distribution
  def start_animadistr
    animation_card_distr_is_started
    if @jump_animation_distr
      @cards_player_todisp.each do |player_sym, cards_player_images|
        cards_player_images.each do |card|
          card.visible = true
        end
      end
      animation_card_distr_is_terminated
      return 
    end
    @play_sound_distr = true
    @distr_card_stack = []
    @cards_player_todisp.each do |player_sym, cards_player_images|
      ix = 0
      cards_player_images.each do |card|
        #p card
        card.visible = false
        distr_card = @cards_distr_animated[player_sym][ix]
        distr_card.cd_data[:player_sym] = player_sym
        distr_card.cd_data[:cardix_disp] = ix
        
        info_for_animationdistr(distr_card, card.pos_x, card.pos_y)
        distr_card.pos_x =  distr_card.cd_data[:x_init]
        distr_card.pos_y =  distr_card.cd_data[:y_init]
        @distr_card_stack  << distr_card
        ix += 1
      end
    end
   
    #p @distr_card_stack.last
    @distr_card_stack.last.visible = true
    # start a timer for card played animation
    @app_owner.registerTimeout(@timeout_animation_carddistr, :onTimeoutAniDistrCards1, self)
  end
  
  ##
  # Using linear equation to set velocity and direction of the card
  # to be animated
  def info_for_animationdistr(cardgfx, endpoint_x, endpoint_y)
    v_estimated = 1
    step_target = 11#16
    im = 1
    x0 = cardgfx.cd_data[:x_init]
    y0 = cardgfx.cd_data[:y_init]
    cardgfx.cd_data[:x_fin] = endpoint_x
    cardgfx.cd_data[:y_fin] = endpoint_y
    if (endpoint_x - x0).abs > (endpoint_y - y0).abs
      # we are moving onto x axis
      cardgfx.cd_data[:m_type] = :x_axis
      if (endpoint_x - x0 != 0)
        im = (endpoint_y - y0) * 1000 / (endpoint_x - x0)
        v_estimated = (endpoint_x - x0) / step_target
      end
      iq = y0 - im * x0 / 1000
    else
      # we are moving onto y axis
      cardgfx.cd_data[:m_type] = :y_axis
      if (endpoint_y - y0 != 0)
        im = (endpoint_x - x0) * 1000 / (endpoint_y - y0)
        v_estimated = (endpoint_y - y0) / step_target
      end
      iq = x0 - im * y0 / 1000 
    end
    
    # velocity
    cardgfx.set_vel_xy(v_estimated, v_estimated)
    
    cardgfx.cd_data[:im] = im
    cardgfx.cd_data[:iq] = iq
  end
  
  ##
  # Update animation cards distribuited
  def onTimeoutAniDistrCards1
    if @play_sound_distr
      # after register the timeout we could have a delay.
      # the sound should be started here
      @sound_manager.set_duration(:play_mescola, :loop)
      @sound_manager.play_sound(:play_mescola)
      @play_sound_distr = false
    end
    #p 'onTimeoutAniDistrCards'
    # equazione della retta y = mx + q
    # q punto inters. in y con x = 0
    card_played = @distr_card_stack.last
    im = card_played.cd_data[:im]
    iq = card_played.cd_data[:iq]
    tt = 1
    bend_ani = false
    #p card_played.cd_data
    if card_played.cd_data[:m_type] == :x_axis
      # moving on x ...
      #p " muove in x, curr(x,y): #{card_played.pos_x}, #{card_played.pos_y}"
      card_played.pos_x = card_played.update_pos_x(tt)
      card_played.pos_y = im * card_played.pos_x / 1000 + iq;
      if ( card_played.cd_data[:x_fin] >= card_played.pos_x and card_played.vel_x <= 0) or
         ( card_played.cd_data[:x_fin] <= card_played.pos_x and card_played.vel_x >= 0)  
        bend_ani = true
        #p "End ani, newpos(x,y): #{card_played.pos_x}, #{card_played.pos_y}, target(x,y): #{card_played.cd_data[:x_fin]}, #{card_played.cd_data[:y_fin]}"
      end  
    else
      # moving on y ...
      #p " muove in y, curr(x,y): #{card_played.pos_x}, #{card_played.pos_y}, finale: #{card_played.cd_data[:x_fin]}, #{card_played.cd_data[:y_fin]}"
      card_played.pos_y = card_played.update_pos_y(tt)
      card_played.pos_x = im * card_played.pos_y / 1000 + iq;
      if ( card_played.cd_data[:y_fin] >= card_played.pos_y and card_played.vel_y <= 0) or
         ( card_played.cd_data[:y_fin] <= card_played.pos_y and card_played.vel_y >= 0)  
        bend_ani = true
        #p " end ani, newpos(x,y): #{card_played.pos_x}, #{card_played.pos_y}, target(x,y): #{@canvas_gfx_info[:card_played_pos_end][:x]}, #{@canvas_gfx_info[:card_played_pos_end][:y]}"
      end
    end
    # check if animation is terminated
    if bend_ani
      # animation card played is terminated
      card_played.pos_y = card_played.cd_data[:y_fin]
      card_played.pos_x = card_played.cd_data[:x_fin]
      @distr_card_stack.pop
      if @distr_card_stack.size == 0
        # all cards are distribuited, continue the game
        #p 'All cards distribuited'
        # make cards player visible
        player_card_sym_dis = card_played.cd_data[:player_sym]
        card_ix_dis = card_played.cd_data[:cardix_disp]
        @cards_player_todisp[player_card_sym_dis][card_ix_dis].visible = true
        
        animation_card_distr_is_terminated
        
      else
        #p 'Next distribuited card'
        player_card_sym_dis = card_played.cd_data[:player_sym]
        card_ix_dis = card_played.cd_data[:cardix_disp]
        @cards_player_todisp[player_card_sym_dis][card_ix_dis].visible = true
        @distr_card_stack.last.visible = true
        @app_owner.registerTimeout(@timeout_animation_carddistr, :onTimeoutAniDistrCards1, self)
      end
    else
      # continue animation
      #p 'continue animation'
      @app_owner.registerTimeout(@timeout_animation_carddistr, :onTimeoutAniDistrCards1, self)
    end
    # refresh the display
    @app_owner.update_dsp 
  end #end onTimeoutAniDistrCards1
  
  def is_animation_terminated?
    return @animation_state_distr == :terminated ? true : false
  end
  
  def animation_card_distr_is_started
    @animation_state_distr = :started
  end
  
  def animation_card_distr_is_terminated
    @animation_state_distr = :terminated
    @sound_manager.stop_sound(:play_mescola)
    @gfx_res.animation_cards_distr_end
  end
  
end#end CardsPlayersGraph

##############################################################
##############################################################
