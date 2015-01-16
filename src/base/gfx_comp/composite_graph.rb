# file: composite_graph.rb

$:.unshift File.dirname(__FILE__)

require 'model_canvas_gfx'
require 'component_base'


###################################################### List of all component supported

# require component?: PLEASE insert below

require 'messbox_gfxc'
require 'cardsplayer_gfxc'
require 'cardstaken_gxc'
require 'deckmain_gxc'
require 'tablecards_gxc'
require 'labels_gxc'
require 'cardsdisapp_gfxc'
require 'turnplayer_gfcx'

######################################################################################


##
# Collect  graphical component
class GraphicalComposite
  
  def initialize(gui)
    @list_gfx_component = {}
    @sorted_list = []
    @cupera_gui = gui
    @component_on_front = nil
    @log = Log4r::Logger["coregame_log"] 
  end
  
  def on_mouse_lclick(event)
    ele_clickable = false
    @sorted_list.reverse.each do |component|
      bres = component.on_mouse_lclick(event)
      ele_clickable = true
      break if bres
    end
    @cupera_gui.update_dsp if ele_clickable
  end
   
  def get_component(sym_name)
    return @list_gfx_component[sym_name]
  end
  
  def remove_component(sym_name)
    @list_gfx_component[sym_name] = nil
    update_z_order
  end
  
  ##
  # Remove all components
  def remove_all_components()
    @list_gfx_component = {}
    @sorted_list = []
  end
  
  def bring_component_on_front(sym_name)
    if sym_name == nil
      @component_on_front = nil
    else 
      @component_on_front = @list_gfx_component[sym_name]
    end 
  end
  
  def add_component(sym_name, component)
    @list_gfx_component[sym_name] = component
    update_z_order
  end
  
  def update_z_order
    list = []
    @list_gfx_component.each do |k,v|
      list << v
    end
    @sorted_list = list.sort{|x,y| y.z_order <=> x.z_order }
    #p "-----------"
    #@sorted_list.each{|x| p "#{x.comp_name}, #{x.z_order}"}
  end
  
  
  def draw(dc)
    @sorted_list.each do |component|
      component.draw(dc) if @component_on_front != component 
    end
    @component_on_front.draw(dc) if @component_on_front
  end
  
  #def build(player)
    #@sorted_list.each do |component|
      #component.build(player)
    #end
  #end
  
  #def resize(player)
    #@sorted_list.each do |component|
      #component.resize(player)
    #end
  #end
  
end #end GraphicalComposite




