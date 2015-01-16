#file: chiamata_mgr.rb

require 'rubygems'

##
# Handle the calli stage state machine
class ChiamataManager
  
  def initialize()
    @log = Log4r::Logger["coregame_log"]
    state_init   
  end
  
  def intit_players(players)
    @candidate_caller_info = {:index => -1, :player_name => "", 
         :current_piece => :nothing, :target_points => 61,
         :briscola_card => nil 
    }
    @player_info = []
    
    players.each do |player|
      @player_info << {:player_name => player.name, :state_call => :waiting}
    end
    @player_index = 0
    @last_player_called = {}
    @num_players = @player_info.size
    set_player_action(:on_turn_to_call)
    event_callbris_raised(:ev_intit_players)
  end
  
  def event_callbris_raised(event)
    #@log.debug "event_callbris_raised in state #{@state_call_mgr}, event: #{event}"
    case @state_call_mgr
    # STATE: INIT
      when :state_init
        case event
          when :ev_check_next_state
            check_state_player_init  
          when :ev_hast_to_call
            state_has_to_call
          when :ev_has_to_declare
            state_has_to_declare
          when :ev_intit_players
            state_has_to_call
        end
    # STATE: HAS_TO_CALL   
      when :state_has_to_call
        case event 
          when :ev_player_called
            state_player_called
          when :ev_has_to_declare
            state_has_to_declare
          when :ev_check_next_state
            check_state_has_to_call
        end
    # STATE: PLAYER_CALLED   
      when :state_player_called
        case event 
          when :ev_init
            state_init
        end
    # STATE: HAS_TO_DECLARE   
      when :state_has_to_declare
        case event 
          when :ev_has_declared
            state_has_declared
        end
    # STATE: HAS_DECLARED   
      when :state_has_declared
        case event 
          when :ev_check_next_state
            state_terminated
          when :terminated
            state_terminated
        end
    end
  end
  
  def check_state_player_init
    count_fold = count_player_in_state(:has_fold)
    @log.debug("current folding players: #{count_fold}")
    if count_fold >= @num_players - 1
      @log.debug "Now we have only one player that has called, wait for declaration"
      event_callbris_raised(:ev_has_to_declare)
    else
      next_player_on_turn
      event_callbris_raised(:ev_hast_to_call)
    end
  end
  
  def check_state_has_to_call
    count_fold = count_player_in_state(:has_fold)
    @log.debug("current folding players: #{count_fold}")
    if count_fold >= @num_players
      @log.debug "Now we have only one player that has called, wait for declaration"
      event_callbris_raised(:ev_has_to_declare)
    end
  end
  
  def do_next_step
    event_callbris_raised(:ev_check_next_state)
  end
  
  def state_init
    @state_call_mgr  = :state_init
    @only_one_time_repeat = false
  end
  
  def state_has_to_call
    @state_call_mgr  = :state_has_to_call
    @only_one_time_repeat = false
  end
  
  def state_player_called
    @state_call_mgr = :state_player_called
    @only_one_time_repeat = false
  end
  
  def state_has_to_declare
    @state_call_mgr = :state_has_to_declare
    @only_one_time_repeat = false
  end
  
  def state_has_declared
    @state_call_mgr = :state_has_declared
    @only_one_time_repeat = false
  end
  
  def state_terminated
    @state_call_mgr = :state_terminated
    @only_one_time_repeat = false
  end
  
  # arg: :has_called, :has_fold, :on_turn_to_call
  def set_player_action(action) 
    @player_info[@player_index][:state_call] = action
  end
  
  def player_gameinfo(arg)
    #p arg
    det_arg = arg[:det]
    case arg[:action]
      when :called
        player_has_called(det_arg[:player_name], det_arg[:type], det_arg[:card_rank], det_arg[:points] )
      when :declaration
        player_has_declared(det_arg[:player_name], det_arg[:card])
    end 
  end
  
  # action: :has_called, :has_fold
  def player_has_called(player_name, action, card_rank, points)
    if @state_call_mgr != :state_has_to_call
      @log.error "[CM] Ignore call because state is #{@state_call_mgr}"
      return
    end
    if @player_info[@player_index][:player_name] != player_name
      @log.warn "[CM] Ignore call from #{player_name} because on turn is #{@player_info[@player_index][:player_name]}"
      return 
    end
    
    if @candidate_caller_info[:player_name] == player_name
      @log.warn "[CM] Ignore call from #{player_name} because he is already the candidate"
      return 
    end
    
    if action == :has_called
      @candidate_caller_info[:index] = @player_index
      @candidate_caller_info[:player_name] = @player_info[@player_index][:player_name]
      @candidate_caller_info[:current_piece] = card_rank
      @candidate_caller_info[:target_points] = points
      @log.debug("Player #{player_name} has called #{card_rank} (#{points})")
    else
      @log.debug("Player #{player_name} fold")
    end
    
    @last_player_called = {:player_name => player_name, :action => action, 
                :card_rank => card_rank, :points =>  points}
    
    set_player_action(action)
    
    event_callbris_raised(:ev_player_called)
  end
  
  def player_has_declared(player_name, card)
    if @state_call_mgr != :state_has_to_declare
      @log.error "[CM] Ignore declaration because state is #{@state_call_mgr}"
      return
    end
    if @candidate_caller_info[:player_name]!= player_name
      @log.warn "[CM] Ignore declaration from #{player_name} because on turn is #{@candidate_caller_info[:player_name]}"
      return 
    end
    @log.debug "[CM] Player #{player_name} has declared #{card}"
    @candidate_caller_info[:briscola_card] = card
    event_callbris_raised(:ev_has_declared)
  end
  
  def get_calling_info
    return @candidate_caller_info
  end
  
  def next_player_on_turn
    @player_index = @player_index + 1
    @player_index = 0 if @player_index >=  @num_players
    while @player_info[@player_index][:state_call] == :has_fold   
      @player_index = @player_index + 1
      @player_index = 0 if @player_index >=  @num_players
      #p @player_info[@player_index][:state_call]
    end
  end
  
  def count_player_in_state(state)
    count = @player_info.select{|x| x[:state_call] == state}.size 
    return count
  end
  
  def get_action_msg
    @action_detail = {}
    action = nil
    case @state_call_mgr 
      when :state_has_to_call
        action = :have_to_call
        @action_detail = {:player =>  @player_info[@player_index],
           :card_rank => @candidate_caller_info[:current_piece], 
           :points => @candidate_caller_info[:target_points],
           :player_owner_call =>  @candidate_caller_info[:player_name]}
      when :state_player_called
        action = :has_called
        @action_detail = { :player =>  @last_player_called[:player_name],
        :card_rank => @last_player_called[:card_rank], :action => @last_player_called[:action],
        :points => @last_player_called[:points]}
        event_callbris_raised(:ev_init)
      when :state_has_to_declare
        action = :declaration_needed
        @action_detail = { :player =>  @candidate_caller_info[:player_name],
        :card_rank => @candidate_caller_info[:current_piece], 
        :points => @candidate_caller_info[:target_points]}
      when :state_has_declared
        action = :has_declared
        @action_detail = { :player =>  @candidate_caller_info[:player_name],
        :card_rank => @candidate_caller_info[:current_piece], 
        :points => @candidate_caller_info[:target_points],
        :called_card => @candidate_caller_info[:briscola_card]}
      when :state_terminated
        action = :call_terminated
        @action_detail = { :player =>  @candidate_caller_info[:player_name],
        :briscola => @candidate_caller_info[:briscola_card], 
        :points => @candidate_caller_info[:target_points]}
      else
        @log.warn "[CM] action message -> Unknown state in ChiamataManager: #{@state_call_mgr}"
    end
    return action
  end
  
  def get_detail_msg
    return @action_detail
  end
  
  def is_calling_terminate?
    return @state_call_mgr == :state_terminated ? true : false
  end
  
  def repeat_proc?
    res =  (@state_call_mgr == :state_has_to_declare or
            @state_call_mgr == :state_has_declared or
            @state_call_mgr == :state_has_to_call) ? true : false
    if res
      res = @only_one_time_repeat == true ? false : res 
      @only_one_time_repeat = true
    end
    return res  
  end
  
end