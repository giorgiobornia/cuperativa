#file labels_gxc.rb


class LabelsGxc < ComponentBase
  
  def initialize(gui, gfx,  color_font, font_big, font_small)
    super(49)
    @comp_name = "LabelsGxc" 
    @app_owner = gui
    @labels_to_disp = {}
    @color_text_label = color_font
    @font_text_big = font_big
    @font_text_small = font_small
    @log = Log4r::Logger.new("coregame_log::LabelsGxc") 
    @gfx_res = gfx
  end
  
  def draw(dc)
    #draw name of players and all other labels
    dc.foreground = @color_text_label 
    @labels_to_disp.each_value do |label|
      label.draw_label(dc)
    end
  end
  
  
  ##
  # Set label text
  # info is an has with description of label position
  def set_label_text(lbl_key, text, info, font_type = :big_font )
    if @labels_to_disp[lbl_key] == nil
      font = font_type == :big_font ? @font_text_big : @font_text_small
      @labels_to_disp[lbl_key] =  LabelGfx.new(0,0, "", font, @color_text_label,  false)
    end
    
    @labels_to_disp[lbl_key].text = text
    @labels_to_disp[lbl_key].visible = true
    @labels_to_disp[lbl_key].info_tag = info
  end
  
  def change_text_label(lbl_key,  text)
    if @labels_to_disp[lbl_key] == nil
      @log.error("Unable to change text on label with key: #{lbl_key}")
      return
    end
    @labels_to_disp[lbl_key].text = text
  end
  
  def build()
    resize()
  end
 
  def resize()
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    @labels_to_disp.each_value do |lbl_comp|
      info = lbl_comp.info_tag
      # e.g.: {:x => {:type => :left_anchor, :offset => 10},
      #         :y => {:type => :bottom_anchor, :offset => -40},
      #         :anchor_element => :canvas }
      next if info == nil
      anchor_element = info[:anchor_element]
      if anchor_element != nil and
         model_canvas_gfx.info[anchor_element] != nil
         anch_w = model_canvas_gfx.info[anchor_element][:width]
         anch_h = model_canvas_gfx.info[anchor_element][:height]
         anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
         anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
         item_w = @font_text_big.getTextWidth(lbl_comp.text)
         item_h = @font_text_big.getTextHeight(lbl_comp.text) 
         pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
         pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
         lbl_comp.pos_x = pos_x
         lbl_comp.pos_y = pos_y
      end
    end
    
  end#end resize 
 
end

