# file: deckmain_gxc.rb


##
# Class used to manage the deck graphical component
class DeckMainGraph < ComponentBase
  attr_accessor :briscola, :realgame_num_cards
  
  def initialize(gui, gfx, font, num_card, factor)
    super(20)
    @comp_name = "DeckMainGraph"
    # deck is using the briscola
    @briscola = true
    @cupera_gui = gui
    @gfx_res = gfx
    @deck_todisp = []
    # briscola card
    @card_briscola_todisp = nil
    # number of gfx element on deck
    @num_cards_deck = num_card
    # number of cards on the deck in the core
    @realgame_num_cards = 0
    @factor = factor
    @posnumcards_x = 0
    @posnumcards_y = 0
    @text_col = Fox.FXRGB(255, 255, 255)
    @font_text = font
    @log =  Log4r::Logger.new("coregame_log::DeckMainGraph") 
    # ifo about the last card on the deck (scaled image and lbl)
    @last_deck_card = {}
  end
  
  ##
  # Component build
  # player: not used
  def build(player)
    @log.debug "gxc: Build deck_main"
    img_coperto = @gfx_res.get_cardsymbolimage_of(:coperto)
    z_ord = 1
    @deck_todisp = []
    num_cards_on_deck = @num_cards_deck
    (0..num_cards_on_deck - 1).each do |index|
      @deck_todisp << CardGfx.new(self, 0, 0, @image_gfx_resource[:card_opp_img], :card_opp_img, z_ord )
      z_ord += 1
    end
    if @briscola
      brisc_img = @gfx_res.get_card_imagerotated_of(:bA)
      @card_briscola_todisp = CardGfx.new(self, 0, 0, brisc_img, :bA, 0 )
    end
    
    resize(player)
  end
  
  def build_with_info(info_tag, img_coperto_sym)
    @log.debug "Build deck with info"
    z_ord = 1
    @deck_todisp_infotag = {:infotag => info_tag, :img_coperto_sym => img_coperto_sym}
    @deck_todisp = []
    num_cards_on_deck = @num_cards_deck
    (0..num_cards_on_deck - 1).each do |index|
      @deck_todisp << CardGfx.new(self, 0, 0, @image_gfx_resource[img_coperto_sym], img_coperto_sym, z_ord )
      z_ord += 1
    end
    if @briscola
      brisc_img = @gfx_res.get_card_imagerotated_of(:bA)
      @card_briscola_todisp = CardGfx.new(self, 0, 0, brisc_img, :bA, 0 )
    end
    resize_with_info()
  end
  
  def resize_with_info
    if @deck_todisp_infotag == nil
      @log.warn "resize withou build, avoid it"
      return
    end
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info = @deck_todisp_infotag[:infotag]
    anchor_element = info[:anchor_element]
    res_sym = @deck_todisp_infotag[:img_coperto_sym]
    img_coperto = @image_gfx_resource[res_sym]
    item_w = img_coperto.width 
    item_h = img_coperto.height
    x_deck_start = 0
    y_deck_start = 0
    if anchor_element != nil and
       model_canvas_gfx.info[anchor_element] != nil
       anch_w = model_canvas_gfx.info[anchor_element][:width]
       anch_h = model_canvas_gfx.info[anchor_element][:height]
       anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
       anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
       pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       x_deck_start = pos_x
       y_deck_start = pos_y
    end
    rest_x = 0
    rest_y = 0
    @deck_todisp.each do |card_deck|
      card_deck.pos_x = x_deck_start + rest_x
      card_deck.pos_y = y_deck_start + rest_y
      rest_y += 1
      rest_x += 1 
    end
    
    model_canvas_gfx.info[:deck_info][:x_deck_start] = x_deck_start
    model_canvas_gfx.info[:deck_info][:y_deck_start] = y_deck_start
    model_canvas_gfx.info[:deck_info][:rest_x] = rest_x
    model_canvas_gfx.info[:deck_info][:rest_y] = rest_y
    
    if @briscola and @card_briscola_todisp
      # briscola
      # it is a rotated card
      y_brisc = y_deck_start + (img_coperto.height / 2 - img_coperto.width / 2 - 12)
      x_brisc = x_deck_start - (img_coperto.height -  img_coperto.height / 3  + 20) 
      @card_briscola_todisp.pos_x = x_brisc
      @card_briscola_todisp.pos_y = y_brisc
    end
    
  end
  
  ##
  # Resize component
  # player: not used
  def resize(player)
    #@log.debug "gxc: resize deck_main"
    img_opponent_deck = @image_gfx_resource[:card_opp_img]
    
    # deck
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    x_deck_start = 50
    y_deck_start = 50
    
    if model_canvas_gfx.info[:deck_info][:position] == nil
      x_deck_start = model_canvas_gfx.info[:canvas][:width] - (img_opponent_deck.width + 30)
      y_deck_start = (model_canvas_gfx.info[:canvas][:height] - (img_opponent_deck.height + 30))/ 2
    else
      x_deck_start = model_canvas_gfx.info[:deck_info][:position][:x_deck_start]
      y_deck_start = model_canvas_gfx.info[:deck_info][:position][:y_deck_start]
    end
    
    rest_x = 0
    rest_y = 0
    @deck_todisp.each do |card_deck|
      card_deck.pos_x = x_deck_start + rest_x
      card_deck.pos_y = y_deck_start + rest_y
      rest_y += 1
      rest_x += 1 
    end
    model_canvas_gfx.info[:deck_info][:x_deck_start] = x_deck_start
    model_canvas_gfx.info[:deck_info][:y_deck_start] = y_deck_start
    model_canvas_gfx.info[:deck_info][:rest_x] = rest_x
    model_canvas_gfx.info[:deck_info][:rest_y] = rest_y
    
    if @briscola and @card_briscola_todisp
      # briscola
      # it is a rotated card
      y_brisc = y_deck_start + (img_opponent_deck.height / 2 - img_opponent_deck.width / 2 - 12)
      x_brisc = x_deck_start - (img_opponent_deck.height -  img_opponent_deck.height / 3  + 20) 
      @card_briscola_todisp.pos_x = x_brisc
      @card_briscola_todisp.pos_y = y_brisc
    end
    
  end
  
  ##
  # Shows the last card on the deck
  def deck_display_lastcard(img, lbl_card)
    @log.debug "Last card on deck is: #{lbl_card}"
    @last_deck_card[:img] = img
    @last_deck_card[:lbl] = lbl_card
    deck_display_lastcard_alreadyset
  end
  
  def deck_display_lastcard_alreadyset
    card_gfx = @deck_todisp.last
    if card_gfx
      card_gfx.change_image(@last_deck_card[:img], @last_deck_card[:lbl]  )
      card_gfx.visible = true
    end
  end
  
  ##
  # draw component
  def draw(dc)
    # draw briscola
    if @card_briscola_todisp
      @card_briscola_todisp.draw_card(dc)
    end
    # draw deck
    @deck_todisp.each do |v|
      v.draw_card(dc) if v 
    end
    # write how many cards are remaining
    if @deck_todisp.size > 0
      @posnumcards_x = @deck_todisp.last.pos_x + @deck_todisp.last.image.width - 20
      @posnumcards_y = @deck_todisp.last.pos_y + 12
      dc.font = @font_text
      dc.foreground = @text_col
      dc.drawText(@posnumcards_x, @posnumcards_y, @realgame_num_cards.to_s)
    end
  end
  
  ##
  # set the briscola image of the deck
  # brisc_carte_pl: briscola card label
  def set_briscola(brisc_carte_pl)
    @card_briscola_todisp.change_image( @gfx_res.get_card_imagerotated_of(brisc_carte_pl), brisc_carte_pl)
  end
  
  ##
  # pop cards from deck
  def pop_cards(num_pops)
    #p  @deck_todisp.size
    num_pops.times{|ix| @deck_todisp.pop}
    if @briscola and @card_briscola_todisp and @deck_todisp.size == 0
    #if @card_briscola_todisp and @realgame_num_cards == 0
      # no more cards on deck, pick the briscola
      @card_briscola_todisp.visible = false
    end
    #p  @deck_todisp.size
  end
  
  ##
  # direction: :sud or :nord
  def movedeck_to(direction)
    @log.debug "gfx: Move deck to #{direction}"
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    
    img_coperto = @gfx_res.get_cardsymbolimage_of(:coperto)
    #img_opponent_deck = @image_gfx_resource[:card_opp_img]
    
    x_deck_start = model_canvas_gfx.info[:canvas][:width] - (img_coperto.width + 30)
    y_deck_start = 10
    if direction == :sud
      y_deck_start = (model_canvas_gfx.info[:canvas][:height] - (img_coperto.height))  
    end
    
    model_canvas_gfx.info[:deck_info][:position] = {:x_deck_start => x_deck_start, :y_deck_start => y_deck_start }
   
    
  end
  
end#end DeckMainGraph