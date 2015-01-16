#file: nal_client_spazzino_gfx.rb

require 'nal_client_gfx'

#####################################################################
#####################################################################
#####################################################################
#########################################       NalClientSpazzinoGfx
  
##
# Network abstraction layer for Spazzino and similar client Gfx
# Abstract callbacks from remote game core and gfx class
# There small changes in protocol for NalClientGfx
# socket S ------> Gfx
class NalClientSpazzinoGfx < NalClientGfx
  
  def initialize(net_controller, game_gfx, app_options)
    super(net_controller, game_gfx, app_options)
    @log = Log4r::Logger.new("coregame_log::NalClientSpazzinoGfx") 
  end
  
  def onalg_newmano(msg_details)
    @log.debug "NalClientSpazzinoGfx new mano"
    tmp = msg_details.split(",")
    # remember: first item is the player name, then follow the cards list
    info_cards = []
    tmp[1..-1].each{|c| info_cards << c.to_sym}
    # use the player object instead of the name
    player_name = tmp[0]
    player = @players_gfx[player_name]
    newmano_det = [player, info_cards]
    @game_gfx.onalg_newmano( newmano_det )
  end
  
  def onalg_player_has_played(msg_details) 
    arr_info =  YAML::load(msg_details)
    unless arr_info.size == 2
      @log.error("Network onalg_player_has_played format error")
      return
    end
    player_name = arr_info[0]
    player = @players_gfx[player_name] 
    card = arr_info[1]
    @game_gfx.onalg_player_has_played(player, card)
  end
  
end #NalClientSpazzinoGfx

