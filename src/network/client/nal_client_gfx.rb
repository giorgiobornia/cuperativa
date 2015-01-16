#file: nal_client_gfx.rb

$:.unshift File.dirname(__FILE__)
$:.unshift File.dirname(__FILE__) + '/../..'

require 'base/core/core_game_base'
require 'nal_client_core.rb'


#####################################################################
#####################################################################
#####################################################################
#############################################       NalClientGfx
  
##
# Network abstarction layer for client Gfx
# Abstract callbacks from remote game core and gfx class
# socket S ------> Gfx
class NalClientGfx
  
  def initialize(net_controller, game_gfx, app_options)
    @net_controller = net_controller
    @game_gfx = game_gfx
    # hash of players with key network user_name to instance of PlayerOnGame
    @players_gfx = {}
    @options = app_options
    @log = Log4r::Logger.new("coregame_log::NalClientGfx") 
  end
  
  ###### Methods called from socket S ---> Gfx
  # This methods are usually called from core_game to game_gfx
  # In network case they core methods are coming from remote server, 
  # but because we are
  # using a socket interface, some works is needed to rebuild variable and objects
  # sent over the network. If an object is complex, like array of hash, yaml
  # format is used
  
  ##
  # Begin a new match notification
  # gui_user_name: gui user name as string
  # all_players: list of all players as user_name string array
  # nal_core: instance of NalClientCore
  # options_remote: remote game options like points and segni target
  def onalg_new_match(gui_user_name, all_players, nal_core, options_remote)
    # this stuff happens because we start a new match, on a local game this is
    # implemented behind start_newgame on gui button. For network game 
    # it is implemented together with algorithm callback
    @players_gfx = {}
    # this option overwrite the @core_game on gfx class
    # so @core_game calls are redirect here
    @options[:netowk_core_game] = nal_core
    # adjust nal core options with a remote options
    # core options are used in the gfx directly
    nal_core.game_opt.merge!(options_remote)
    # prepare players array
    pos = 0
    all_players.each do |pl_name|
      tipo = :human_remote
      tipo = :human_local if pl_name == gui_user_name
      @players_gfx[pl_name] = PlayerOnGame.new(pl_name, nil, tipo, pos)
      pos += 1 
    end
    
    # call gfx base class for a new game for starting a new game
    # the call end on ongui_start_new_game of inherited class
    @game_gfx.start_new_game(@players_gfx.values, @options)
    
    # call core algorithm callback 
    @game_gfx.onalg_new_match(@players_gfx.values)
  end
  
  ##
  # carte_player: Array of cards in string format
  def onalg_new_giocata(carte_player)
    arr_cd = []
    carte_player.each{|card| arr_cd << card.to_sym }
    @game_gfx.onalg_new_giocata(arr_cd)
  end
  
  ##
  #
  def onalg_newmano(msg_details)
    player = @players_gfx[msg_details]
    @game_gfx.onalg_newmano(player)
  end
  
  ##
  # msg_detail: yaml dump of player name and commands
  def onalg_have_to_play(msg_details)
    info = YAML::load(msg_details)
    player_name = info[0]
    commands = info[1]
    @game_gfx.onalg_have_to_play(@players_gfx[player_name], commands)
  end
  
  def onalg_player_pickcards(msg_details)
    info = YAML::load(msg_details)
    player_name = info[0]
    cards_arr =  info[1]
    @game_gfx.onalg_player_pickcards(@players_gfx[player_name], cards_arr)
  end
  
  ##
  #
  def onalg_player_has_played(msg_details) 
    tmp = msg_details.split(",")
    unless tmp.size == 2
      @log.error("Network onalg_player_has_played format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    card = tmp[1].to_sym
    @game_gfx.onalg_player_has_played(player, card)
  end
  
  ##
  #
  def onalg_player_has_declared(msg_details)
    tmp = msg_details.split(",")
    unless tmp.size == 3
      @log.error("Network onalg_player_has_declared format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    name_decl = tmp[1].to_sym
    points = tmp[2].to_i
    @game_gfx.onalg_player_has_declared(player, name_decl, points)
  end
  
  ##
  #
  def onalg_pesca_carta(msg_details)
    tmp = msg_details.split(",")
    cards = []
    tmp.each{|c| cards << c.to_sym}
    @game_gfx.onalg_pesca_carta(cards)
  end
  
  ##
  #
  def onalg_manoend(msg_details)
    info = YAML::load(msg_details)
    unless info.size == 3
      @log.error("Network onalg_player_has_declared format error")
      return
    end
    user_name = info[0]
    carte_prese_mano = info[1]
    punti_presi = info[2]
    player = @players_gfx[user_name]
    
    @game_gfx.onalg_manoend(player, carte_prese_mano, punti_presi)
  end
  
  ##
  # 
  def onalg_giocataend(msg_details)
    best_pl_points = YAML::load(msg_details)
    @game_gfx.onalg_giocataend(best_pl_points)
  end
  
  ##
  #
  def onalg_game_end(msg_details)
    best_pl_segni = YAML::load(msg_details)
    @game_gfx.onalg_game_end(best_pl_segni)
  end
  
  ##
  #
  def onalg_player_has_changed_brisc(msg_details)
    tmp = msg_details.split(",")
    unless tmp.size == 3
      @log.error("Network onalg_player_has_changed_brisc format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    card_briscola = tmp[1].to_sym
    card_on_hand = tmp[2].to_sym
    @game_gfx.onalg_player_has_changed_brisc(player, card_briscola,card_on_hand )
  end
  
  def onalg_player_has_getpoints(msg_details)
    tmp = msg_details.split(",")
    unless tmp.size == 2
      @log.error("Network onalg_player_has_getpoints format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    points = tmp[1].to_i
    @game_gfx.onalg_player_has_getpoints(player, points)
  end
  
  def onalg_player_cardsnot_allowed(msg_details)
    tmp = msg_details.split(",")
    unless tmp.size >= 2
      @log.error("Network onalg_player_cardsnot_allowed format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    arr_cd = []
    # remove the player as first item, rest are all cards
    tmp.slice!(0) 
    tmp.each{|card| arr_cd << card.to_sym }
    @game_gfx.onalg_player_cardsnot_allowed(player, arr_cd)
  end
  
  ##
  # Expect comma separated string, first item is the player, then cards
  def onalg_player_has_taken(msg_details)
    tmp = msg_details.split(",")
    unless tmp.size >= 2
      @log.error("Network onalg_player_has_taken format error")
      return
    end
    user_name = tmp[0]
    player = @players_gfx[user_name]
    arr_cd = []
    # remove the player as first item, rest are all cards
    tmp.slice!(0) 
    tmp.each{|card| arr_cd << card.to_sym }
    @game_gfx.onalg_player_has_taken(player, arr_cd)
  end
  
  ##
  # Expect the name of the player
  def onalg_new_mazziere(msg_details)
    user_name = msg_details
    player = @players_gfx[user_name]
    if player
      @game_gfx.onalg_new_mazziere(player)
    else
      @log.error("Network onalg_new_mazziere player not found")
    end
  end
  
  ##
  # Generic game information message. Parsing of the message is done into the gfx part
  def onalg_gameinfo(msg_details)
    info = YAML::load(msg_details)
    @game_gfx.onalg_gameinfo(info)
  end
  
end#


if $0 == __FILE__
  aa = NalClientSpazzinoGfx.new(0,0,0)
  aa.onalg_newmano([1,2])
end
