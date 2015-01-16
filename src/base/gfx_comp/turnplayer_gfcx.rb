#file: turnplayer_gfcx.rb

class TurnPlayerSignalGxc < ComponentBase
  
  def initialize(gui, gfx,  color_on, color_off)
    super(55)
    @comp_name = "TurnPlayerSignalGxc" 
    @app_owner = gui
    @turn_mark_to_disp = {}
    @color_on = color_on
    @color_off = color_off
    @log = Log4r::Logger.new("coregame_log::TurnPlayerSignalGxc") 
    @gfx_res = gfx
  end
  
  def draw(dc)
    @turn_mark_to_disp.each_value do |marker_info|
      marker = marker_info[:ctrl]
      if marker_info[:state] == :is_on
        marker.color = @color_on
        marker.visible = true
      elsif marker_info[:state] == :is_off
        marker.color = @color_off
        marker.visible = true
      else
        marker.visible = false
      end
      marker.draw_marker(dc)
    end
  end
  
  def add_marker(marker_key, state, info)
    if @turn_mark_to_disp[marker_key] == nil
      marker_gfx = TurnMarkerGfx.new(0,0,info[:marker_width],info[:marker_height],@color_on,false)
      @turn_mark_to_disp[marker_key] = {:state => state, 
                 :ctrl => marker_gfx, :info_tag => info}
    end
    resize_item(marker_key)
  end

  def set_marker_state(marker_key, state)
    @turn_mark_to_disp[marker_key][:state] = state
  end
  
  def set_all_marker_invisible
    @turn_mark_to_disp.each_value{|v| v[:state] = :is_invisible}
  end
  
  def set_marker_state_invisible_allother(marker_key, state)
    @turn_mark_to_disp.each do |k, v|
      if k == marker_key
        v[:state] = state
      else
        v[:state] = :is_invisible
      end
    end
  end
  
  def resize
    @turn_mark_to_disp.each_key{|k| resize_item(k) }
  end
  
  def resize_item(marker_key)
    mark_item = @turn_mark_to_disp[marker_key]
    return if mark_item == nil
    model_canvas_gfx = @gfx_res.model_canvas_gfx
    info = mark_item[:info_tag]
    return if info == nil
    anchor_element = info[:anchor_element]
    if anchor_element != nil and
       model_canvas_gfx.info[anchor_element] != nil
       anch_w = model_canvas_gfx.info[anchor_element][:width]
       anch_h = model_canvas_gfx.info[anchor_element][:height]
       anch_pos_x = model_canvas_gfx.info[anchor_element][:pos_x]
       anch_pos_y = model_canvas_gfx.info[anchor_element][:pos_y]
       item_w = info[:marker_width]
       item_h = info[:marker_height] 
       pos_x = calc_off_pos(info[:x], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       pos_y = calc_off_pos(info[:y], anch_pos_x, anch_pos_y, anch_w, anch_h, item_w, item_h )
       mark_item[:ctrl].pos_x = pos_x
       mark_item[:ctrl].pos_y = pos_y
     end
  end#end resize_item
  
end
