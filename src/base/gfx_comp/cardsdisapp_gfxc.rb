#file: cardsdisapp_gfxc.rb

class CardsDisappGraph < ComponentBase
  def initialize(gui, gfx, time_show)
    super(25)
    @comp_name = "CardsDisappGraph" 
    @gfx_res = gfx
    @app_owner = gui
    @timeout_animation = 20
    @log = Log4r::Logger.new("coregame_log::CardsDisappGraph")
    @cards_todisp = {} 
    @cards_infotag = {}
    @animation_state = :init
    @timeout_show = time_show
  end
  
  def build(key_card, img_coperto_sym, info_tag)
    @cards_infotag[key_card] = {:infotag => info_tag, :img_coperto_sym => img_coperto_sym}
    img_coperto = @image_gfx_resource[img_coperto_sym]
    gfx_card_new = CardGfx.new(@gfx_res, 0, 0, img_coperto, :coperto, 1 )
    gfx_card_new.visible = false
    @cards_todisp[key_card] = gfx_card_new
    resize_single(key_card)
  end
  
  def draw(dc)
    @cards_todisp.each_value do |cards_app|
      cards_app.draw_card(dc) if cards_app.visible
    end
  end
  
  def resize
    @cards_todisp.each_key{|k| resize_single(k)}
  end
  
  def resize_single(key_card)
    card_ctrl = @cards_todisp[key_card]
    return if card_ctrl == nil
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info = @cards_infotag[key_card][:infotag]
    # info una struttura del tipo: 
    #:img_coperto_sym => :coperto,
    #:infotag =>{:x => {:type => :center_anchor_horiz, :offset => 0},
    #           :y => {:type => :bottom_anchor, :offset => -40},
    #           :anchor_element => :canvas }
    anchor_element = info[:anchor_element]
    res_sym = @cards_infotag[key_card][:img_coperto_sym]
    img_coperto = @image_gfx_resource[res_sym]
    xoffset = img_coperto.width
    item_w = img_coperto.width
    item_h = img_coperto.height
    left_card = 0
    top_card = 0
    if anchor_element != nil and
         model_canvas_gfx.info[anchor_element] != nil
       anch_w = model_canvas_gfx.info[anchor_element][:width]
       anch_h = model_canvas_gfx.info[anchor_element][:height]
       anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
       anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
       pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       card_ctrl.pos_x = pos_x
       card_ctrl.pos_y = pos_y
    end
    
  end
  
  def set_card_image(key_card, lblcard)
    card_ctrl = @cards_todisp[key_card]
    if card_ctrl == nil
      @log.warn "card control for #{key_card} not found"
      return
    end
    card_ctrl.change_image( @gfx_res.get_card_image_of(lblcard), lblcard)
  end
  
  def start_showing
    @cards_todisp.each do |k, card_ctrl|
      card_ctrl.visible = true
    end
    @animation_state = :started
    @app_owner.registerTimeout(@timeout_show, :onTimeoutShowing, self)
  end
  
  def is_animation_terminated?
    return @animation_state == :terminated ? true : false
  end
  
  def onTimeoutShowing
    @cards_todisp.each do |k, card_ctrl|
      card_ctrl.visible = false
    end
    animation_is_terminated
  end
  
  def animation_is_terminated
    @animation_state = :terminated
    @gfx_res.animation_pickcards_end
  end
  
end