#file: nal_client_core.rb


##
# This is a NAl Core game used to translate Gfx calls to core interface
# into remote server calls. This class is used for communication:
# server socket S <----- Gfx
#class NalClientCore < CoreGameBase
class NalClientCore
  
  attr_accessor :game_opt 
  attr_reader :custom_core
  
  def initialize(net_controller)
    @net_controller = net_controller
    @log = Log4r::Logger.new("coregame_log::NalClientCore")   
    @game_opt = {}
    @num_of_suspend = 0
    @custom_core = nil
    @proc_queue = []
  end 
  
  include CoreGameQueueHandler
  
  ##
  # 
  def process_next_gevent
  end
  
  ##
  # Set a custom core
  def set_custom_core(core)
    @log.debug "Setting custom core"
    @custom_core = core
  end
  
  ##
  # It is possible that a coregame has methods to be used from gfx
  # That are not need to be sent to the server. Then try to send
  # it to the custom core. So we don't need changes into gfx for 
  # network game
  def method_missing(m, *args)
    # *args wraps all the method parameters (arguments) in an array  
    @log.debug "NalClientCore: missed metod #{m}, use custom core."
    if @custom_core
      #p args
      #p args.size
      case args.size
        when 0
          return @custom_core.send(m)
        when 1
          return @custom_core.send(m, args[0])
        when 2
          return @custom_core.send(m, args[0],args[1])
        when 3
          return @custom_core.send(m, args[0],args[1], args[2] )
        when 4
          return @custom_core.send(m, args[0],args[1], args[2], args[3])
        else
          @log.warn "NalClientCore: method #{m} still unsupported"
          return nil
      end
    else
      @log.warn "Custom core ot set"
    end  
  end 
  
  ##
  # Suspend server information handling
  def suspend_proc_gevents(str="")
    @log.debug("Suspend handling events #{str}")
    @net_controller.suspend_srv_msg_handler
    @num_of_suspend += 1
    @log.debug("suspend_proc_gevents add lock #{@num_of_suspend}")
  end
  
  ##
  # Continue after suspend
  def continue_process_events(str="")
    @log.debug("Continue after suspend handling events #{str}")
    @num_of_suspend -= 1
    if @num_of_suspend <= 0
      @num_of_suspend = 0
      @net_controller.restore_srv_msg_handler
    else
      @log.debug("Suspend yet locked #{@num_of_suspend}")
    end
  end
  
  ##
  # Main app inform about starting a new match
  # players: array of PlayerOnGame
  def gui_new_match(players)
  end
  
  ##
  # Send a confirm to the server that the client can start a new segno
  def gui_new_segno
    @net_controller.send_data_to_server( @net_controller.build_cmd(:gui_new_segno, "") )
  end
    
  ###### Methods sent to socket S <----- Gfx
  # This methods are implemented in the core class of the game (e.g. core_game_mariazza.rb)
  # They are redirected to the server using the socket
  
  ##
  # Notification player has played a card
  # lbl_card: card played label (e.g. :_Ab)
  def alg_player_cardplayed(player, lbl_card)
    str = "#{player.name},#{lbl_card}"
    @net_controller.send_data_to_server( @net_controller.build_cmd(:alg_player_cardplayed, str) )
    @log.debug("<client>alg_player_cardplayed: #{str}")
    return :allowed # avoid dumb comment
  end
  
  ##
  # Notification player has played an array of  cards
  # lbl_card: card played label (e.g. :[_Ab])
  def alg_player_cardplayed_arr(player, arr_lbl_card)
    #str = "#{player.name},#{lbl_card}"
    tmp = [player.name, arr_lbl_card ].flatten
    str = tmp.join(",") 
    @net_controller.send_data_to_server( @net_controller.build_cmd(:alg_player_cardplayed_arr, str) )
    @log.debug("<client>alg_player_cardplayed_arr: #{str}")
    return :allowed # avoid dumb comment
  end
  
  ##
  # Notification player has make a declaration
  # name_decl: name of mariazza declaration defined in @mariazze_def (e.g. :mar_den)
  def alg_player_declare(player, name_decl)
    str = "#{player.name},#{name_decl}"
    @net_controller.send_data_to_server( @net_controller.build_cmd(:alg_player_declare, str) )
    @log.debug("<client>alg_player_declare: #{str}")
  end
  
  ##
  # Notification player change his card with the card on table that define briscola
  # Only the 7 of briscola is allowed to make this change
  def alg_player_change_briscola(player, card_briscola, card_on_hand )
    str = "#{player.name},#{card_briscola},#{card_on_hand}"
    @net_controller.send_data_to_server( @net_controller.build_cmd(:alg_player_change_briscola, str) )
    @log.debug("<client>alg_player_change_briscola: #{str}")
    return :allowed #the core can't response immediatly, we consider the changed allowed until response
  end

  #
  # Not needed because the game is stored on the server core
  def save_curr_game(fname)
    @log.debug "Don't save the network game"
  end
  
end  

