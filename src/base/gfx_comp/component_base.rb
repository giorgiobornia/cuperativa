# file: component_base.rb

##
# Interface for graph component
class ComponentBase
  attr_accessor :z_order, :comp_name 
  
  def initialize(z_ord)
    @z_order = z_ord
    @log = Log4r::Logger["coregame_log"] 
    @image_gfx_resource = {}
    @comp_name = "comp_base"
  end
  
  def draw(dc) end
  def build(player) end
  def resize(player)end
  def on_mouse_lclick(event)
    return false 
  end
  
  def set_resource(key, image)
    @image_gfx_resource[key] = image
  end
  
  # info_pos:  {:type => :left_anchor, :offset => 10}
  def calc_off_pos(info_pos,  anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h)
    calc_pos = 0
    case info_pos[:type]
      when  :left_anchor
        calc_pos = anch_pos_x + info_pos[:offset]
      when  :right_anchor
        calc_pos = anch_pos_x + anch_w - item_w + info_pos[:offset]
      when :bottom_anchor
        calc_pos = anch_pos_y + anch_h - item_h + info_pos[:offset]
      when :top_anchor
        calc_pos = anch_pos_y + info_pos[:offset]
      when :center_anchor_horiz
        calc_pos = anch_pos_x +  anch_w / 2 - item_w / 2 + info_pos[:offset]
      when :center_anchor_vert
        calc_pos = anch_pos_y +  anch_h / 2 - item_h / 2 + info_pos[:offset]
      else
        @log.warn "Not recognized type #{info_pos[:type]}"
    end
    return calc_pos
  end
  
  
end