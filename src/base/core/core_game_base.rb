#file: core_game_base.rb
#Common card game basic handling

$:.unshift File.dirname(__FILE__)

require 'mod_core_queue'
require 'player_on_game'

##
#Manage the basic of core game
class CoreGameBase
  
  # array constant throw warnings. Use static variable to avoid warnings.
  @@NOMI_SEMI = ["basto", "coppe", "denar", "spade"]
  @@NOMI_SYMB = ["cope", "zero", "xxxx", "vuot"]
  # deck info, on inherited class we use @game_deckinfo
  @@deck_info = {
    # bastoni
    :_Ab => {:ix=> 0,  :nome => 'asso bastoni', :symb => :asso, :segno => :B, :seed_ix => 0, :pos => 1},
    :_2b => {:ix=> 1,  :nome => 'due bastoni', :symb => :due, :segno => :B, :seed_ix => 0, :pos => 2 }, 
    :_3b => {:ix=> 2,  :nome => 'tre bastoni', :symb => :tre, :segno => :B, :seed_ix => 0, :pos => 3},
    :_4b => {:ix=> 3,  :nome => 'quattro bastoni', :symb => :qua, :segno => :B, :seed_ix => 0, :pos => 4}, 
    :_5b => {:ix=> 4,  :nome => 'cinque bastoni', :symb => :cin, :segno => :B, :seed_ix => 0, :pos => 5},
    :_6b => {:ix=> 5 , :nome => 'sei bastoni', :symb => :sei, :segno => :B, :seed_ix => 0, :pos => 6}, 
    :_7b => {:ix=> 6,  :nome => 'sette bastoni', :symb => :set, :segno => :B, :seed_ix => 0, :pos => 7},
    :_Fb => {:ix=> 7,  :nome => 'fante bastoni' , :symb => :fan, :segno => :B, :seed_ix => 0, :pos => 8}, 
    :_Cb => {:ix=> 8 , :nome => 'cavallo bastoni', :symb => :cav, :segno => :B, :seed_ix => 0, :pos => 9},
    :_Rb => {:ix=> 9 , :nome => 're bastoni' , :symb => :re, :segno => :B, :seed_ix => 0, :pos => 10},
    # coppe
    :_Ac => {:ix=> 10, :nome => 'asso coppe', :symb => :asso, :segno => :C, :seed_ix => 1, :pos => 1},
    :_2c => {:ix=> 11, :nome => 'due coppe', :symb => :due, :segno => :C, :seed_ix => 1, :pos => 2}, 
    :_3c => {:ix=> 12, :nome => 'tre coppe', :symb => :tre, :segno => :C, :seed_ix => 1, :pos => 3},
    :_4c => {:ix=> 13, :nome => 'quattro coppe', :symb => :qua, :segno => :C, :seed_ix => 1, :pos => 4},
    :_5c => {:ix=> 14, :nome => 'cinque coppe', :symb => :cin, :segno => :C, :seed_ix => 1, :pos => 5},
    :_6c => {:ix=> 15 ,:nome => 'sei coppe', :symb => :sei, :segno => :C, :seed_ix => 1, :pos => 6},
    :_7c => {:ix=> 16, :nome => 'sette coppe', :symb => :set, :segno => :C, :seed_ix => 1, :pos => 7},
    :_Fc => {:ix=> 17, :nome => 'fante coppe' , :symb => :fan, :segno => :C, :seed_ix => 1, :pos => 8},
    :_Cc => {:ix=> 18 ,:nome => 'cavallo coppe', :symb => :cav, :segno => :C, :seed_ix => 1, :pos => 9},
    :_Rc => {:ix=> 19 ,:nome => 're coppe' , :symb => :re, :segno => :C, :seed_ix => 1, :pos => 10},
    # denari
    :_Ad => {:ix=> 20, :nome => 'asso denari', :symb => :asso, :segno => :D, :seed_ix => 2, :pos => 1},
    :_2d => {:ix=> 21, :nome => 'due denari', :symb => :due, :segno => :D, :seed_ix => 2, :pos => 2}, 
    :_3d => {:ix=> 22, :nome => 'tre denari', :symb => :tre, :segno => :D, :seed_ix => 2, :pos => 3},
    :_4d => {:ix=> 23, :nome => 'quattro denari', :symb => :qua, :segno => :D, :seed_ix => 2, :pos => 4},
    :_5d => {:ix=> 24, :nome => 'cinque denari', :symb => :cin, :segno => :D, :seed_ix => 2, :pos => 5},
    :_6d => {:ix=> 25 ,:nome => 'sei denari', :symb => :sei, :segno => :D, :seed_ix => 2, :pos => 6},
    :_7d => {:ix=> 26, :nome => 'sette denari', :symb => :set, :segno => :D, :seed_ix => 2, :pos => 7},
    :_Fd => {:ix=> 27, :nome => 'fante denari' , :symb => :fan, :segno => :D, :seed_ix => 2, :pos => 8},
    :_Cd => {:ix=> 28 ,:nome => 'cavallo denari', :symb => :cav, :segno => :D, :seed_ix => 2, :pos => 9},
    :_Rd => {:ix=> 29 ,:nome => 're denari' , :symb => :re, :segno => :D, :seed_ix => 2, :pos => 10},
    # spade
    :_As => {:ix=> 30, :nome => 'asso spade', :symb => :asso, :segno => :S, :seed_ix => 3, :pos => 1},
    :_2s => {:ix=> 31, :nome => 'due spade', :symb => :due, :segno => :S, :seed_ix => 3, :pos => 2}, 
    :_3s => {:ix=> 32, :nome => 'tre spade', :symb => :tre, :segno => :S, :seed_ix => 3, :pos => 3},
    :_4s => {:ix=> 33, :nome => 'quattro spade', :symb => :qua, :segno => :S, :seed_ix => 3, :pos => 4},
    :_5s => {:ix=> 34, :nome => 'cinque spade', :symb => :cin, :segno => :S, :seed_ix => 3, :pos => 5},
    :_6s => {:ix=> 35 ,:nome => 'sei spade', :symb => :sei, :segno => :S, :seed_ix => 3, :pos => 6},
    :_7s => {:ix=> 36, :nome => 'sette spade', :symb => :set, :segno => :S, :seed_ix => 3, :pos => 7},
    :_Fs => {:ix=> 37, :nome => 'fante spade' , :symb => :fan, :segno => :S, :seed_ix => 3, :pos => 8},
    :_Cs => {:ix=> 38 ,:nome => 'cavallo spade', :symb => :cav, :segno => :S, :seed_ix => 3, :pos => 9},
    :_Rs => {:ix=> 39 ,:nome => 're spade' , :symb => :re, :segno => :S, :seed_ix => 3, :pos => 10}
  }
  
  include CoreGameQueueHandler
  
  ##
  # constructor
  def initialize
    @game_deckinfo = {}
    # simple state machine processor, use it as stack, the last event
    # submitted is the first processed 
    @proc_queue = []
    # suspend queue event flags - used if gui have timeouts to delay the game
    @suspend_queue_proc = false
    # count number of suspend because they can stay overlapped
    @num_of_suspend = 0
    @mazzo_gioco = []
    # viewers
    @viewers = {}
    # logger
    @log = Log4r::Logger["coregame_log"]
  end
  
  def get_curr_stack_call
    str = "Stack trace:\n"
    begin
      crash__
    rescue => detail
      str = detail.backtrace.join("\n")
    end
    return str
  end
  
  def add_viewer(the_viewer)
    @viewers[the_viewer.name] = the_viewer
    info = on_viewer_get_state()
    the_viewer.game_state(info)
  end
  
  def on_viewer_get_state()
    return {}
  end
  
  def remove_viewer(name)
    @viewers.delete(name)
  end
  
  def inform_viewers(*args)
    @viewers.each{|k,viewer| viewer.game_action(args)}
  end
  
  def set_specific_options(options)
  end
  
  def num_cards_on_mazzo
    return @mazzo_gioco.size
  end

  
  def self.nomi_semi
    @@NOMI_SEMI
  end
  
  def self.nomi_simboli
    @@NOMI_SYMB
  end
  
  def is_matchsuitable_forscore?
    return true
  end
  
  ##
  # Provides the card logical symbol (e.g for _7c the result is :set)
  def get_card_logical_symb(card_lbl)
    return @@deck_info[card_lbl][:symb]
  end
  
  ##
  # Provides the player index before the provided
  def player_ix_beforethis(num_players, ix_player)
    ix_res = ix_player - 1
    if ix_res < 0
      ix_res = num_players - 1
    end
    return  ix_res
  end
  
  ##
  # Provides the player index after the provided
  def player_ix_afterthis(num_players, ix_player)
    ix_res = ix_player + 1
    if ix_res >=  num_players
      ix_res = 0
    end
    return  ix_res
  end
  
  ##
  # Calculate round players order
  # arr_players: array of players
  # first_ix: first player index
  def calc_round_players(arr_players, first_ix)
    ins_point = -1
    round_players = []
    onlast = true
    arr_players.each_index do |e|
      if e == first_ix
        ins_point = 0
        onlast = false
      end 
      round_players.insert(ins_point, arr_players[e])
      ins_point =  onlast ?  -1 : ins_point + 1         
    end
    return round_players
  end
  
  ##
  # Provides a complete card name
  def self.nome_carta_completo(lbl_card)
    #p lbl_card
    return @@deck_info[lbl_card][:nome]
  end
 
  def get_deck_info
    return @game_deckinfo
  end
  
  def self.mazzo_italiano
    return @@deck_info
  end
  
end

##
# Algorithm cpu base. Used to define algorithm notifications
# Please consider that a change done here has an impact with:
# Add a new message in ParserCmdDef
# *** prot_parsmsg
#  ==> On the server:
# *** NAL_Srv_Algorithm
#  ==> On the client:
# *** ControlNetConnection
# *** NalClientGfx
# *** every class that inherit BaseEngineGfx if necessary
# *** GameBasebot

# To check  if all interfaces are right use the test case on Test_Botbase
# Note: if you change the meaning of members of this interface,
# i.e carte_player becomes an hash instead of an array, you have
# to redifine NAL_Srv_Algorithm, so better is to implement a new function
class AlgCpuPlayerBase
  def onalg_new_giocata(carte_player) end
  def onalg_new_match(players) end
  def onalg_newmano(player) end
  def onalg_have_to_play(player,command_decl_avail) end
  def onalg_player_has_played(player, card) end
  def onalg_player_has_declared(player, name_decl, points) end
  def onalg_pesca_carta(carte_player) end
  def onalg_player_pickcards(player, cards_arr) end
  def onalg_manoend(player_best, carte_prese_mano, punti_presi) end
  def onalg_giocataend(best_pl_points) end
  def onalg_game_end(best_pl_segni) end
  def onalg_player_has_changed_brisc(player, card_briscola, card_on_hand) end
  def onalg_player_has_getpoints(player, points) end
  def onalg_player_cardsnot_allowed(player, cards) end
  def onalg_player_has_taken(player, cards) end
  def onalg_new_mazziere(player) end
  def onalg_gameinfo(info) end
end

class ViewerGameBase
  def alg_changed(info) end
  def current_state(info) end
end


