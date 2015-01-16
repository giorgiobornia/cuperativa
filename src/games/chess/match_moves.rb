#file: match_moves.rb

class SingleMatchMoves
  def initialize
    @arr_moves = []
    @arr_pgn_moves = []
    @curr_pos = 0
    @result = ""
    @attributes = {}
  end
  
  def move_to_first
    @curr_pos = 0
  end
  
  def move_to_last
    @curr_pos = @arr_moves.size - 1
    @curr_pos = 0 if @curr_pos < 0
  end
  
  def move_to_next
    @curr_pos += 1
    @curr_pos = move_to_last if @curr_pos >= @arr_moves.size
  end
  
  def move_to_previous
    @curr_pos -= 1
    @curr_pos = move_to_first if @curr_pos < 0
  end
  
  def get_next_move
    return nil if @arr_moves.size == 0
    move = @arr_moves[@curr_pos]
    move_to_next
    return move
  end
  
  def peek_move
    return nil if @arr_moves.size == 0
    move = @arr_moves[@curr_pos]
    return move
  end
  
  def add_move(argument)
    @arr_moves  << argument
  end
  
  def add_pgn_move(pgn_str)
    @arr_pgn_moves << pgn_str
  end
  
  def set_attributes(attr)
    @attributes = attr.dup
  end
  
  def set_result(res)
    @result = res
  end
  
end


#########################################

class CollectionOfMatches
  
  def initialize
    @arr_matches = []
  end
  
  def create_new_match
    sm = SingleMatchMoves.new
    @arr_matches << sm
    return sm
  end
  
  def get_match_num(num)
    return @arr_matches[num] if num >= 0 and num < @arr_matches.size
    return nil
  end
    
end