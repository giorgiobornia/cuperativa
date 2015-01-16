#file: tablecards_gxc.rb

##
# Manage cards that are played on the table
class TablePlayedCardsGraph < ComponentBase
  
  def initialize(gui, gfx, num_cards)
    super(22)
    @state_resize = :resize_done
    @state_animation = {:card_played => :idle, :card_taken => :idle}
    @comp_name = "TablePlayedCardsGraph"
    @cupera_gui = gui
    @gfx_res = gfx
    @num_cards = num_cards
    @zord_next_card = 1
    @timeout_animation_cardplayed = 20
    @timeout_animation_cardtaken = 20
    @cards_taken_disp = []
    @cards_played_todisp = []
    # info to display cards on the table for games like scopa
    @table_cards_gfx = []
    @table_cards_lbl = []
    @widget_list_clickable = []
    # change velocity of card played: bigger value, slower animation
    @speed_card_played = 8
    @log = Log4r::Logger.new("coregame_log::TablePlayedCardsGraph") 
    # selection colors
    @colors_selection = []
    @colors_selection << Fox.FXRGB(10, 30, 220)
    @colors_selection << Fox.FXRGB(20, 60, 10)
    @colors_selection << Fox.FXRGB(250, 250, 250)
    @colors_selection << Fox.FXRGB(255, 255, 10)
    # crads taken
    @cards_taken_disp = []
  end
  
  # info_tag:
  #{:x => {:type => :center_anchor, :offset => 0},
  # :y => {:type => :center_anchor, :offset => 0},
  # :anchor_element => :canvas },
  # :max_num_cards => 10, :intra_card_off => 5, :img_coperto_sym => :coperto}
  def build_with_info(info_tag)
    @widget_list_clickable = []
    img_coperto_sym = info_tag[:img_coperto_sym]
    #p @image_gfx_resource
    img_coperto = @image_gfx_resource[img_coperto_sym]
    if img_coperto == nil
      str = "resource #{img_coperto_sym} not found. Resource set?"
      @log.error str
      raise str
    end
    max_num_cards = info_tag[:max_num_cards]
    @table_infotag = info_tag
    (0..max_num_cards-1).each do |ix|
      gfx_card_new =  CardGfx.new(@gfx_res, 0, 0, img_coperto, :coperto, 1 )
      gfx_card_new.visible = false
      gfx_card_new.type = :table
      @table_cards_gfx << gfx_card_new
      @widget_list_clickable << gfx_card_new
    end
    resize_with_info
  end
  
  def resize_with_info
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info = @table_infotag
    anchor_element = info[:anchor_element]
    res_sym = info[:img_coperto_sym]
    img_coperto = @image_gfx_resource[res_sym]
    xoffset = img_coperto.width + info[:intra_card_off]
    item_w = calculate_deckwidth(@table_cards_gfx, xoffset)
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
    if info[:type_distr] == :linear
      #@log.debug "Changing @table_cards_gfx position rswi"
      @table_cards_gfx.each do |single_gfx_card|
        x_fin = left_pl1_card + ix * xoffset
        single_gfx_card.pos_x = x_fin
        single_gfx_card.pos_y = top_pl1_card
        ix += 1
      end
      half_canvas_w = model_canvas_gfx.info[:canvas][:width] / 2
      tmp_arr = []
      tmp_arr_target = []
      @table_cards_gfx.each do |x|
        if x.visible 
          tmp_arr << x.lbl
        elsif  x.cd_data[:is_target] == true
          tmp_arr_target << x.lbl 
        end
        x.visible = false
        x.change_image(@gfx_res.get_card_image_of(:coperto), :coperto)
      end
      @table_cards_gfx = @table_cards_gfx.sort do |a,b|
          val_a = a.pos_x - half_canvas_w
          val_b = b.pos_x - half_canvas_w
          val_a.abs <=> val_b.abs
      end
      ix = 0
      tmp_arr.each do |lbl| 
        @table_cards_gfx[ix].change_image(@gfx_res.get_card_image_of(lbl), lbl)
        @table_cards_gfx[ix].visible = true
        ix += 1
      end
      tmp_arr_target.each do |lbl| 
        @table_cards_gfx[ix].change_image(@gfx_res.get_card_image_of(lbl), lbl)
        ix += 1
      end
      
    elsif info[:type_distr] == :circular
      arr_positions = info[:player_positions]
      ix = 0
      @table_cards_gfx.each do |single_gfx_card|
        single_gfx_card.pos_x = x_init
        single_gfx_card.pos_y = y_init
        correct_table_card_onposition(arr_positions[ix], single_gfx_card)
        ix += 1
      end
    end
    
  end
  
  def correct_table_card_onposition(position, single_gfx_card)
    case position
      when :nord
        single_gfx_card.pos_y -= 10
        single_gfx_card.pos_x -= 15
        single_gfx_card.cd_data[:position] = :nord
      when :sud
        single_gfx_card.pos_y += 10
        single_gfx_card.pos_x += 15
        single_gfx_card.cd_data[:position] = :sud 
    end
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
  
  def  calculate_left_pl1_card(model_canvas_gfx, num_cards, img_coperto)
    return 70 + (model_canvas_gfx.info[:canvas][:width] - (num_cards * img_coperto.width + 50))/ 2
  end
  
  ##
  # Animation is terminated
  # type: :card_played, :card_taken
  def animation_is_terminated(type)
    @state_animation[type] = :idle
    if type == :card_played
      @cards_played_todisp.each do |gfx_card|
        tb_gfx = find_cardgfx_on_table(gfx_card.lbl)
        if tb_gfx != nil
          gfx_card.visible = false
          gfx_card.cd_data[:is_target] = nil
          tb_gfx.visible = true
        end
      end
    end
  end
  
  def deactivate_border_sel
    @table_cards_gfx.each{|e| e.deactivate_border_sel}
  end
  
  
  def draw(dc)
    tablecards_sorted = @table_cards_gfx.sort{|x,y| x.z_order <=> y.z_order }
    
    tablecards_sorted.each do |v|
      v.draw_card(dc) if v 
    end
    @cards_played_todisp.each do |v|
      v.draw_card(dc) if v
    end
    @cards_taken_disp.each do |v|
      v.draw_card(dc) if v
    end
  end
  
  def reset_info_cards_on_table
    @table_cards_lbl = []
    @table_cards_gfx = []
  end
  
  def card_taken_ontable2(player_taker, cards_taken)
    @mano_end_player_taker = player_taker
    @mano_end_card_taken = cards_taken
    
    velocity_x = 0
    velocity_y = 10
    if @mano_end_player_taker.position == :nord
      velocity_y = -velocity_y
    end
    @table_cards_gfx.each{|e| e.deactivate_border_sel}
    
    @cards_taken_disp = []
    
    @mano_end_card_taken.each do |taked_lbl|
      gfx_card = find_cardgfx_on_table(taked_lbl)
      if gfx_card
        #p gfx_card.pos_x
        #p gfx_card.pos_y
        gfx_taken = CardGfx.new(@gfx_res, gfx_card.pos_x, gfx_card.pos_y, 
               @gfx_res.get_card_image_of(gfx_card.lbl), gfx_card.lbl, 1 )
        gfx_taken.set_vel_xy(velocity_x, velocity_y)
        gfx_taken.visible = true
        @cards_taken_disp << gfx_taken
        gfx_card.visible = false
        gfx_card.change_image(@gfx_res.get_card_image_of(:coperto), 
                                           :coperto)
      end
    end
    
    tmp_x = 0
    tmp_y = 0
    @cards_played_todisp.each do |gfx_card|
      gfx_taken = CardGfx.new(@gfx_res, gfx_card.pos_x, gfx_card.pos_y, 
               @gfx_res.get_card_image_of(gfx_card.lbl), gfx_card.lbl, 1 )
      
      gfx_taken.set_vel_xy(0, velocity_y)
       #align card onto the same deck
      if tmp_x == 0 
        tmp_x = gfx_taken.pos_x
        tmp_y = gfx_taken.pos_y
      else
        gfx_taken.pos_x = tmp_x + 5
        gfx_taken.pos_y = tmp_y + 5
      end
      @cards_taken_disp << gfx_taken
    end
    
    
    start_ani_cards_taken
  end
  
  
  ##
  # Provides gfx cards on table
  # lbl_card: card label (e.g :_Ab)
  def find_cardgfx_on_table(lbl_card)
    @table_cards_gfx.each do |single_gfx_card|
      return single_gfx_card if single_gfx_card.lbl == lbl_card 
    end
    return nil
  end
  
  def find_first_free_on_table()
    @table_cards_gfx.each do |single_gfx_card|
      return single_gfx_card if single_gfx_card.lbl == :coperto
      return single_gfx_card if single_gfx_card.visible == false 
    end
    return nil
  end
  
  # position: e.g. :nord, :sud
  def find_position_card_on_table(position)
    @table_cards_gfx.each do |single_gfx_card|
      return single_gfx_card if single_gfx_card.cd_data[:position] == position
    end
    return nil
  end
  
  
  ##
  # Change the border of activated cards
  def multiplechoice_colorize_selection(card, list_options, card_activated)
    @table_cards_gfx.each{|e| e.deactivate_border_sel}
    ix_color = 0
    list_options.each do |list_item_arr|
      curr_color = @colors_selection[ix_color]
      list_item_arr.each do |card_on_lst|
        @table_cards_gfx.each do |cd_table_gfx| 
          if card_activated and cd_table_gfx.lbl ==  card_activated.lbl
            # card selected on multiple choice
            cd_table_gfx.activate_border_sel(Fox.FXRGB(255, 255, 128))
          elsif cd_table_gfx.lbl ==  card_on_lst
            #p cd_table_gfx.lbl
            unless curr_color
              @log.error("Border color of card is invalid")
            end
            cd_table_gfx.activate_border_sel(curr_color)
            break
          end
        end
      end
      ix_color += 1 if ix_color < @colors_selection.size - 1
    end
  end
  
  ##
  # Mark as selected cards taken
  def multiplechoice_colorizetaken(mano_end_card_taken)
    curr_color = @colors_selection.last
    mano_end_card_taken.each do |card_on_lst|
      @table_cards_gfx.each do |cd_table_gfx|
        if cd_table_gfx.lbl ==  card_on_lst
          #p cd_table_gfx.lbl
          unless curr_color
            @log.error("Border color of card is invalid[2]")
          end
          cd_table_gfx.activate_border_sel(curr_color)
          break
        end
      end
    end
  end
  
  ##
  # return true if the card is on table, otherwise false
  def is_click_on_table_card?(card)
    @table_cards_gfx.each do |item|
      return true if item.lbl == card.lbl and item.visible = true
    end
    return false
  end
  
  def all_card_played_tocardtaken2(player_taker)
    @mano_end_player_taker = player_taker
    velocity_x = 0
    velocity_y = 7
    if @mano_end_player_taker.position == :nord
      velocity_y = -velocity_y
    end
    
    @cards_taken_disp = []
    
    @table_cards_gfx.each do |gfx_card|
      #p gfx_card.pos_x
      #p gfx_card.pos_y
      gfx_taken = CardGfx.new(@gfx_res, gfx_card.pos_x, gfx_card.pos_y, 
             @gfx_res.get_card_image_of(gfx_card.lbl), gfx_card.lbl, 1 )
      gfx_taken.set_vel_xy(velocity_x, velocity_y)
      gfx_taken.visible = true
      @cards_taken_disp << gfx_taken
      gfx_card.visible = false
      gfx_card.change_image(@gfx_res.get_card_image_of(:coperto), 
                                         :coperto)
    
    end
    
    start_ani_cards_taken
  end
  
  ##
  # Handle the left mouse click
  def on_mouse_lclick(event)
    #p "cards_players on_mouse_lclick"
    bres = false
    @widget_list_clickable.sort! {|x,y| x.z_order <=> y.z_order}
    @widget_list_clickable.each do |item|
      if item.visible
        bres = item.on_mouse_lclick(event.win_x, event.win_y)
        break if bres
      end
    end
    return bres
  end
  
  def initial_lbl_cards_on_table2(cards_lbl)
    @table_cards_gfx.each do |card_gfx| 
      card_gfx.visible = false
      card_gfx.change_image(@gfx_res.get_card_image_of(:coperto), 
                                           :coperto)
    end
    ix = 0
    cards_lbl.each do |card_single|
      gfx_card = @table_cards_gfx[ix]
      gfx_card.change_image( @gfx_res.get_card_image_of(card_single), 
                                           card_single)
      gfx_card.visible = true
      ix += 1 
    end
  end
  
  def assign_lbl_cards_on_table(cards_lbl)
    cards_lbl.each do |card_single|
      gfx_card = find_cardgfx_on_table(card_single)
      if(gfx_card) == nil
        gfx_card = find_cardgfx_on_table(:coperto)
        if gfx_card != nil
          gfx_card.change_image( @gfx_res.get_card_image_of(card_single), 
                                           card_single)
        else
          errstr = "Impossible to assign card #{card_single} on table"
          @log.error errstr
          raise errstr
        end
      end
    end
  end
 
  ##
  # Start animation cards taken
  def start_ani_cards_taken
    @log.debug "Start animation cards taken with #{@cards_taken_disp.size} cards"
    @cards_taken_disp.each{|gfx_card| gfx_card.visible = true}
    @cards_played_todisp.each{|gfx_card| gfx_card.visible = false}
    @state_animation[:card_taken] = :ongoing
    @cupera_gui.registerTimeout(@timeout_animation_cardtaken, :onTimeoutAniCardTaken1, self)
  end
  
  def card_is_played2_incirc(lbl_card, player_position, z_ord, init_x,  init_y)
    @log.debug "card is played #{lbl_card} from #{player_position}"
    gfx_played = CardGfx.new(@gfx_res, init_x, init_y, 
               @gfx_res.get_card_image_of(lbl_card), lbl_card, 1 )
    
    if gfx_played.pos_x == nil or gfx_played.pos_y == nil
      strerr = "Programming error: init position undefined #{gfx_played.pos_x} #{gfx_played.pos_y}"
      @log.error strerr 
      raise strerr
    end
    
    
    @cards_played_todisp = [gfx_played]
    
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    dest_gfx = find_position_card_on_table(player_position)
    #p dest_gfx.pos_x
    #p dest_gfx.pos_y
    if dest_gfx == nil
      @log.error "Programming error, not enought gfx card on table available. Why?"
      dest_gfx = @table_cards_gfx[0]
    end
    if dest_gfx.pos_x == nil or dest_gfx.pos_y == nil
      strerr = "Programming error: destination card no position #{dest_gfx.pos_x} #{dest_gfx.pos_y}"
      @log.error strerr 
      raise strerr
    end
    dest_gfx.z_order = z_ord
    dest_gfx.change_image(@gfx_res.get_card_image_of(lbl_card), lbl_card)
    model_canvas_gfx.info[:card_played_pos_end] = {}
    model_canvas_gfx.info[:card_played_pos_end][:x] = dest_gfx.pos_x
    model_canvas_gfx.info[:card_played_pos_end][:y] = dest_gfx.pos_y
    
    start_ani_played_card(0, init_x, init_y)
  end
  
  def card_is_played2(lbl_card, player, card_taken, init_x, init_y)
    @log.debug "card is played #{lbl_card} from #{player.name}"
    gfx_played = CardGfx.new(@gfx_res, init_x, init_y, 
               @gfx_res.get_card_image_of(lbl_card), lbl_card, 1 )
    @cards_played_todisp = [gfx_played]
    
    model_canvas_gfx = @gfx_res.model_canvas_gfx
      
    if card_taken.size == 0
      dest_gfx = find_first_free_on_table()
      dest_gfx.cd_data[:is_target] = true
      #p dest_gfx.lbl
      #p dest_gfx.pos_x
      if dest_gfx == nil
        @log.error "Programming error, not enought gfx card on table available. Why?"
        dest_gfx = @table_cards_gfx[0]
      end
      if dest_gfx.pos_x == nil or dest_gfx.pos_y == nil
        strerr = "Programming error: destination card no position"
        @log.error strerr 
        raise strerr
      end
      dest_gfx.change_image(@gfx_res.get_card_image_of(lbl_card), lbl_card)
      model_canvas_gfx.info[:card_played_pos_end] = {}
      model_canvas_gfx.info[:card_played_pos_end][:x] = dest_gfx.pos_x
      model_canvas_gfx.info[:card_played_pos_end][:y] = dest_gfx.pos_y
    else
      correct_end_position_cardtaken(model_canvas_gfx, player, card_taken)
    end

    start_ani_played_card(0, init_x, init_y)
  end
 
  ##
  # Fix the destination in case the card played take some cards
  def correct_end_position_cardtaken(model_canvas_gfx, player, cards_played_taken)
    # correct the end position using card taken
    x_mean = 0
    y_taken = 0
    cards_played_taken.each do |taked_lbl|
      #p taked_lbl
      gfx_card = find_cardgfx_on_table(taked_lbl)
      return if gfx_card == nil 
      x_mean += gfx_card.pos_x
      if y_taken == 0
        y_taken = gfx_card.pos_y - 40
        y_taken = gfx_card.pos_y + 40  if player.type == :human_local
      end
    end
    if x_mean > 0 and cards_played_taken.size > 0
      # we have card taken
      model_canvas_gfx.info[:card_played_pos_end][:x] = x_mean / cards_played_taken.size
      model_canvas_gfx.info[:card_played_pos_end][:y] = y_taken
    end
  end
  
  ##
  # Start the card played animation
  # ix : card played index
  # init_x: initial x position
  # init_y: initial y position
  def start_ani_played_card(ix, init_x, init_y)
    @state_animation[:card_played] = :ongoing
    @log.debug "tablecard: start ani played card: #{ix}, #{init_x}, #{init_y}"
    if ix >= @cards_played_todisp.size
      strerr =  "Unable to animate card with ix#{ix} because size is #{@cards_played_todisp.size}"
      @log.error strerr 
      raise strerr
    end
    @cards_played_todisp[ix].pos_x = init_x
    @cards_played_todisp[ix].pos_y = init_y
    @cards_played_todisp[ix].anistate = :animated
    
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    
    endpoint_y = model_canvas_gfx.info[:card_played_pos_end][:y]
    endpoint_x = model_canvas_gfx.info[:card_played_pos_end][:x]
    
    #animation stuff
    # line trajectory equation
    #p endpoint_y
    #p endpoint_x
    v_estimated = 1
    step_target = @speed_card_played#9#16
    im = 1
    #p @cards_played_todisp[ix]
    x0 = @cards_played_todisp[ix].pos_x
    y0 = @cards_played_todisp[ix].pos_y
    if (endpoint_x - x0).abs > (endpoint_y - y0).abs
      # we are moving onto x axis
      model_canvas_gfx.info[:card_played_pos_end][:m_type] = :x_axis
      #@canvas_gfx_info[:card_played_pos_end][:m_type] = :x_axis
      if (endpoint_x - x0 != 0)
        im = (endpoint_y - y0) * 1000 / (endpoint_x - x0)
        v_estimated = (endpoint_x - x0) / step_target
      end
      iq = y0 - im * x0 / 1000
    else
      # we are moving onto y axis
      model_canvas_gfx.info[:card_played_pos_end][:m_type] = :y_axis
      if (endpoint_y - y0 != 0)
        im = (endpoint_x - x0) * 1000 / (endpoint_y - y0)
        v_estimated = (endpoint_y - y0) / step_target
      end
      iq = x0 - im * y0 / 1000 
    end
    
    # velocity
    @cards_played_todisp[ix].set_vel_xy(v_estimated, v_estimated)
    
    model_canvas_gfx.info[:card_played_pos_end][:im] = im
    model_canvas_gfx.info[:card_played_pos_end][:iq] = iq
    
    #p model_canvas_gfx
    
    @ix_index_animated = ix
    @cupera_gui.registerTimeout(@timeout_animation_cardplayed, :onTimeoutAniCardPlayed1, self)
    
  end
  
  ##
  # Tick for animation card played
  def onTimeoutAniCardPlayed1
    #p "onTimeoutAniCardPlayed #{Time.now}"
    ix  = @ix_index_animated
    card_played = @cards_played_todisp[ix]
    
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    im = model_canvas_gfx.info[:card_played_pos_end][:im]
    iq = model_canvas_gfx.info[:card_played_pos_end][:iq]
    tt = 1
    bend_ani = false
    if model_canvas_gfx.info[:card_played_pos_end][:m_type] == :x_axis
      # moving on x ...
      #p " muove in x, curr(x,y): #{card_played.pos_x}, #{card_played.pos_y}"
      card_played.pos_x = card_played.update_pos_x(tt)
      card_played.pos_y = im * card_played.pos_x / 1000 + iq;
      if ( model_canvas_gfx.info[:card_played_pos_end][:x] >= card_played.pos_x and card_played.vel_x <= 0) or
         ( model_canvas_gfx.info[:card_played_pos_end][:x] <= card_played.pos_x and card_played.vel_x >= 0)  
        bend_ani = true
        #p " end ani, newpos(x,y): #{card_played.pos_x}, #{card_played.pos_y}, target(x,y): #{@canvas_gfx_info[:card_played_pos_end][:x]}, #{@canvas_gfx_info[:card_played_pos_end][:y]}"
      end  
    else
      # moving on y ...
      #p " muove in y, curr(x,y): #{card_played.pos_x}, #{card_played.pos_y}"
      card_played.pos_y = card_played.update_pos_y(tt)
      card_played.pos_x = im * card_played.pos_y / 1000 + iq;
      if ( model_canvas_gfx.info[:card_played_pos_end][:y] >= card_played.pos_y and card_played.vel_y <= 0) or
         ( model_canvas_gfx.info[:card_played_pos_end][:y] <= card_played.pos_y and card_played.vel_y >= 0)  
        bend_ani = true
        #p " end ani, newpos(x,y): #{card_played.pos_x}, #{card_played.pos_y}, target(x,y): #{@canvas_gfx_info[:card_played_pos_end][:x]}, #{@canvas_gfx_info[:card_played_pos_end][:y]}"
      end
    end
    # check if animation is terminated
    if bend_ani
      # animation card played is terminated
      card_played.pos_x =  model_canvas_gfx.info[:card_played_pos_end][:x]
      card_played.pos_y =  model_canvas_gfx.info[:card_played_pos_end][:y]
      card_played.anistate = :static
      @gfx_res.ani_card_played_end
      animation_is_terminated(:card_played)
    else
      @cupera_gui.registerTimeout(@timeout_animation_cardplayed, :onTimeoutAniCardPlayed1, self)
    end
    
    # refresh the display
    @cupera_gui.update_dsp
  end
  
  ##
  # Tick for animation card taken
  def onTimeoutAniCardTaken1
    # update card position conform to the direction
    # check only on y because we support only two players
    #p "onTimeoutAniCardTaken1"
    posy_min = 1000
    posy_max = 0
    #@log.debug "tblgfx: moving taken cards #{@cards_taken_disp.size}"
    @cards_taken_disp.each do |card| 
      card.update_pos_xy(4) #use an unit of time
   
      posy_max = card.pos_y if  card.pos_y > posy_max
      posy_min = card.pos_y if  card.pos_y < posy_min
    end
    
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    
    if (posy_max > model_canvas_gfx.info[:canvas][:height] - 30 and @mano_end_player_taker.position == :sud) or
       (posy_min < -10 and @mano_end_player_taker.position == :nord)
      # stop animation, end point reached
      #p posy_max, posy_min, takencard_gfx_created.pos_y
      
      @cards_taken_disp.each do |card|
        card.set_vel_xy(0, 0)
        card.visible = false
      end
      animation_is_terminated(:card_taken)
      @log.debug "Animation card taken terminated"
      @gfx_res.ani_card_taken_end
    else
      # continue animation
      @cupera_gui.registerTimeout(@timeout_animation_cardtaken, :onTimeoutAniCardTaken1, self)
    end
    # refresh the display
    @cupera_gui.update_dsp
  end


end#end TablePlayedCardsGraph

