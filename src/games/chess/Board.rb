# -*- coding: ISO-8859-1 -*-
#file: Board.rb

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'BoardInfoItem'
require 'match_moves'

##
# Holds information about squared
class Board
  attr_reader :pieces, :color_on_turn
  
  def initialize
    @infosquare = []
    8.times do |ix|
      row = []
      8.times {|yx| row << BoardInfoItem.new(ix, yx)}  
      @infosquare << row
    end
    @pieces = {} 
    @last_moved_item = nil
    @last_move_pgn = ''
    # possible: :white, :black
    @color_on_turn = nil 
    @log = Log4r::Logger["coregame_log"]
    @matches_db = CollectionOfMatches.new
    # instance of SingleMatchMoves
    @current_match = nil
    #p @infosquare
  end
  
  def create_new_match
    @current_match = @matches_db.create_new_match
    init_pos
  end
  
  def set_curr_match_attributes(attr)
    @current_match.set_attributes(attr)
  end
  
  ##
  # Set the current board using fen string
  def board_with_fen(fen_str)
    @log.debug "Set board using fen: #{fen_str}"
    reset_board_variables
    arr_cmd = fen_str.split(' ')
    if arr_cmd.size != 6
      @log.error("invalid fen string format")
      return
    end
    arr_row = arr_cmd[0].split('/')
    row_num = 0
    arr_row.each do |row_info|
      #p row_info
      col_pos = 0
      row_info.each_byte do |row_byte|
        #p row_byte
        piece_type = :none
        piece_color = :none
        case row_byte
          when  'P'[0]
            piece_type = :ped
            piece_color = :white
          when  'N'[0]
            piece_type = :cav
            piece_color = :white
          when  'B'[0]
            piece_type = :alf
            piece_color = :white
          when  'R'[0]
            piece_type = :torr
            piece_color = :white
          when  'Q'[0]
            piece_type = :reg
            piece_color = :white
          when  'K'[0]
            piece_type = :re
            piece_color = :white
          when  'p'[0]
            piece_type = :ped
            piece_color = :black
          when  'n'[0]
            piece_type = :cav
            piece_color = :black
          when  'b'[0]
            piece_type = :alf
            piece_color = :black
          when  'r'[0]
            piece_type = :torr
            piece_color = :black
          when  'q'[0]
            piece_type = :reg
            piece_color = :black
          when  'k'[0]
            piece_type = :re
            piece_color = :black
          else
            if row_byte >= 49 and row_byte <= 56
              blank_num = row_byte - 48 
              col_pos += blank_num
            end 
        end#end case
        if piece_type != :none
          if col_pos > 7
            @log.error "fen format error column"
          end
          @infosquare[row_num][col_pos].setinfo(piece_type, piece_color)
          @pieces[piece_color] << @infosquare[row_num][col_pos]
          col_pos += 1
        end
        
      end
      row_num += 1
    end# end arr_row each
    @color_on_turn = :black if arr_cmd[1] == 'b'
    p @color_on_turn
  end #end board_with_fen
  
  ##
  # Prepare an empty board
  def reset_board_variables
    @color_on_turn = :white
    @pieces = {:white => [], :black => []} 
    @last_moved_item = BoardInfoItem.new(0,0)
    @infosquare.each do |row_square|
      row_square.each do |cell|
         cell.clear
      end
    end
    #p @infosquare
  end
  
  def get_piece_on_rowcol(col, row)
    return @infosquare[row][col]
  end
  
  ##
  # Set initial position on board
  def init_pos
    reset_board_variables
    colors = {:white => 0, :black => 7}
    pieces = {:torr => [0,7], :cav => [1,6], :alf => [2,5], :reg => [3], :re => [4]}
    key_pieces = {:white => [:w1, :w2, :w3, :w4, :w5, :w6, :w7, :w8, :w9, :w10, :w11, :w12, :w13, :w14, :w15, :w16],
                  :black => [:b1, :b2, :b3, :b4, :b5, :b6, :b7, :b8, :b9, :b10, :b11, :b12, :b13, :b14, :b15, :b16]}
    # set pieces 
    colors.each do |k_col, v_col|
      # iterate each color
      key_color_array = key_pieces[k_col]
      pieces.each do |k_pie, v_pie|
        # iterate each piece
        v_pie.each do |ix_piece|
          #p v_col, ix_piece, k_pie, k_col
          @infosquare[v_col][ix_piece].setinfo(k_pie, k_col)
          #kk_p = key_color_array.pop
          @pieces[k_col] << @infosquare[v_col][ix_piece] 
        end
      end#end pieces
      
      # now set pawn for this color
      ix_col = 1
      ix_col = 6 if k_col == :black
      [0,1,2,3,4,5,6,7].each do |ix_piece|
        #p ix_col, ix_piece
        @infosquare[ix_col][ix_piece].setinfo(:ped, k_col)
        #kk_p = key_color_array.pop
        @pieces[k_col] << @infosquare[ix_col][ix_piece] 
      end
    end 
    #p @pieces
    #p @infosquare
    #p @pieces.size
    #p @pieces[:white].first
  end
  
  def is_move_inside_the_board?(start_x, start_y, end_x, end_y)
    if (start_x < 0 or start_x > 7) or
       (start_y < 0 or start_y > 7) or
       (end_x < 0 or end_x > 7) or
       (end_y < 0 or end_y > 7)
       @log.debug "Move out of board: #{start_x},#{start_y},#{end_x},#{end_y}"
       return false
     end
     return true
  end
  
  def is_player_on_turn?(color)
    if color == @color_on_turn
      return true
    end
    @log.debug "Color is not on turn: #{color} instead of #{@color_on_turn}"
    return false
  end
  
  ##
  # provides movetype: for the move_igorchess, or :invalid if the move is invalid
  def get_move_igorchess_type(color, start_x, start_y, end_x, end_y)
    return :invalid unless is_move_inside_the_board?(start_x, start_y, end_x, end_y)
    return :invalid unless is_player_on_turn?(color)
    
    # TODO recognize move
    @log.debug("Check type of move => #{color}: #{BoardInfoItem.column_to_s(start_x)}#{BoardInfoItem.row_to_s(start_y)} - #{BoardInfoItem.column_to_s(end_x)}#{BoardInfoItem.row_to_s(end_y)}")
    return :move
  end
  
  # - check se la mossa è valida: 
  #           - tocca al colore
  #           - pezzi sono nella scacchiera
  #           - non si va in scacco, 
  #           - valida per il pezzo in linea teorica
  #           - intralci altri pezzi
  #           - destinazione non è occupata da pezzi del proprio colore
  #           - se arroco valido
  #           - se promozione è valida
  #           - se enpassant è valida
  #           - se la presa è valida
  def check_if_moveisvalid(argument)
    color, start_x, start_y, end_x, end_y = strip_pos_argument(argument)
    move_invalid = get_move_igorchess_type(color, start_x, start_y, end_x, end_y)
    return move_invalid if move_invalid == :invalid
  end
  
  def strip_pos_argument(argument)
    return argument[:color], argument[:start_x],argument[:start_y],argument[:end_x],argument[:end_y]
  end
  
  # movetype: :move, :enpassant, :promotion, :shortcastle, :longcastle, :move_eat
  def do_the_move(argument)
    color, row_s, col_s, row_e, col_e = strip_pos_argument(argument)
    start_item = @infosquare[row_s][col_s]
    end_item =  @infosquare[row_e][col_e]
    if  movetype == :shortcastle or movetype ==:longcastle
      move_castle(start_item, end_item)
    elsif movetype == :enpassant
      col_enp = end_item.col
      row_enp = start_item.row
      eated_item = @infosquare[row_enp][col_enp]
      eated_item.clear
    else
      BoardInfoItem.exchange(start_item, end_item)
    end
    @last_moved_item = end_item
    
  end
  
  ##
  # Move on igor chess
  # argument: map with all arguments of the move
  # color: color on turn (:white,:black)
  # movetype: :move, :enpassant, :promotion, :shortcastle, :longcastle, :move_eat
  # start_x:, start_y:, end_x:, end_y:, integer start/end position on the board (0..7)
  # promoted_piece: promoted piece
  def start_move_igorchess(argument)
    if check_if_moveisvalid(argument) != :invalid
      do_the_move(argument)
    else
      @log.warn "invalid move, ignore it #{argument}"
    end
    # - check se la mossa è valida: 
    #           - non si va in scacco, 
    #           - valida per il pezzo in linea teorica
    #           - intralci altri pezzi
    #           - destinazione non è occupata da pezzi del proprio colore
    #           - se arroco valido
    #           - se promozione è valida
    #           - se enpassant è valida
    #           - se la presa è valida
    # - esegue la mossa
    # - salva come ultima mossa
    # - salva come parte delle ultime tre mosse
    # - salva mossa in formato pgn
    # - notifica in caso di promozione
    # - vedi se la partita è finita:
    #       - patta
    #            - pezzi sufficienti per terminare partita
    #            - ripetizione della stessa posizione per tre volte
    #       - scacco matto
    #           - se la mossa da scacco, controlla tutte le risposte possibili
    #              per vedere se si può evitare lo scacco
  end
  
  
  ### NOTA: questa funzione e' qui solo per riferimento ma e' da eliminare
  ##
  # Make a move using ludopoli format and store the move in pgn format
  # Function return the pgn format of the move
  # mv_tsr: move string i.e. 'e2-e4' or 'Cg1-f3'
  # color: move color i.e. :white
  def move_ludfm(mv_tsr, color)
    #p mv_tsr
    if mv_tsr.length <= 0
      return
    end
    mv_tsr.gsub!('O-O', '')
    mv_tsr.gsub!('-O', '') #long catsle
    if mv_tsr.length == 0
      raise 'Problem with recognizing castle..., please change the code'
    end
    @last_move_pgn = ''
    # recognize piece
    tmp = mv_tsr.split('-')
    start = tmp.first 
    dest = tmp.last
    type =  BoardInfoItem.TypeLud(start[0,1])
    # start position
    start_pos = LudoFrmHelper.eatpiecepos(type, start)
    # end position
    end_pos = dest[0..1]
    # check if the piece is ok
    arr_ix_start = LudoFrmHelper.coord_to_arrpos(start_pos)
    row_s = arr_ix_start[0]
    col_s = arr_ix_start[1]
    if @infosquare[row_s][col_s].check_unequal(type, color)
      # inconsistent format
      print_board
      raise "Start position on #{mv_tsr}(#{color}) is not compatible with piece: #{@infosquare[row_s][col_s].to_ascii_board_piece}"
    end
    arr_ix_end = LudoFrmHelper.coord_to_arrpos(end_pos)
    row_e = arr_ix_end[0]
    col_e = arr_ix_end[1]
    start_item = @infosquare[row_s][col_s]
    end_item =  @infosquare[row_e][col_e]
    # check for castle
    castle_pgn = LudoFrmHelper.check_castle(mv_tsr)
    if castle_pgn
      # castle
      @last_move_pgn = castle_pgn
      move_castle(start_item, end_item)
      return @last_move_pgn
    end
    
    # check if piece take
    rest_move_pgn = '' 
    if dest.length > 2
      # we have more info, like + or x
      rest_move_pgn = dest[2..-1].gsub('x', '')
    end
    eat_pgn = ''
    destplace_pgn = ''
    piece_pgn = start_item.to_string_piece
    # check conflict for horse or rook and set moreinfo_pgn
    moreinfo_pgn = check_conflict_move(type, start_item, end_item)
    
    take_en_passant = false
    if end_item.type_piece !=  :vuoto
      # some pice is taken
      unless LudoFrmHelper.check_taken_onmove(mv_tsr)
        raise "Move not compatible with board, no take piece on #{mv_tsr}, expect take #{end_item.to_ascii_board_piece}"
      end
      # in case of pawn there is no information about piece
      if piece_pgn == ''
        piece_pgn = start_item.colix_tostr
      end
      eat_pgn = 'x'
    else
      # en passant has an empty destination
      take_en_passant = check_taken_enpassant(start_item, end_item)
    end
    
    #if moreinfo_pgn.length > 0
    #  p "Move with conflict #{mv_tsr}"
    #end
    
    # 5 check promotion
    # promotion is simple a pawn that belong to line 1 for black or 8 for white
    # I have to add extra info if the promotion is not the queen, e.g a2-a1=C
    # for promition to horse
    if (start_item.type_piece == :ped and start_item.color_piece == :black and end_item.row == 0 ) or
      # promotion of black
      (start_item.type_piece == :ped and start_item.color_piece == :white and end_item.row == 7)
      #promotion of white
      
      #p "promotion black #{start_item}"
      if rest_move_pgn =~ /=/
        # promoted piece is given
        rest_move_pgn = rest_move_pgn
        #
      else
        # promotion to queen
        rest_move_pgn = '=D' 
      end
      # for the move we set the start piece to the promoted
      char_piece_lud = rest_move_pgn.gsub('=', '')[0..1]
      start_item.setinfo( BoardInfoItem.TypeLud(char_piece_lud), start_item.color_piece)
      # adjoust rest removing ludopoli part and insert the pgn part
      rest_move_pgn = "=#{start_item.to_string_piece}" 
      
    end
    
    if take_en_passant
      #p 'enpassant move'
      col_enp = end_item.col
      row_enp = start_item.row
      # clear the piece taken en passant
      eated_item = @infosquare[row_enp][col_enp]
      eated_item.clear
      piece_pgn = start_item.colix_tostr
      eat_pgn = 'x'
      #print_board
    end
    
    destplace_pgn = end_item.to_dest_pgn
    # build pgn
    @last_move_pgn = piece_pgn + moreinfo_pgn + eat_pgn + destplace_pgn + rest_move_pgn
    # make the move
    @last_moved_item = end_item
    BoardInfoItem.exchange(start_item, end_item)
    #if take_en_passant
    # after en passant
    #  print_board
    #end
    return @last_move_pgn 
  end
  
  ##
  # Check if the move is enpassat 
  def check_taken_enpassant(start_item, end_item)
    
    if start_item.type_piece != :ped or @last_moved_item.type_piece != :ped
      # en passant only for pawn
      #p 'not a pawn'
      return false
    end
   
    if (start_item.color_piece == :white and start_item.row == 4 and end_item.row == 5) or
       (start_item.color_piece == :black and start_item.row == 3 and end_item.row == 2)
       # row is compatible, no check column
       if  @last_moved_item.col ==  end_item.col and @last_moved_item.row == start_item.row and
           (end_item.col - start_item.col).abs == 1
         # en passant
         #p 'en passant is true'
         return true
       else
         #p 'row compatible'
         #p start_item, end_item, @last_moved_item
       end
     else
       #p 'row incompatible'
       #p start_item, end_item, @last_moved_item
    end
    return false
  end
  
  ##
  # Check if the move has conflict, this happens on rook or horse 
  def check_conflict_move(type, start_item, end_item)
    res = ''
    if type == :cav
      res = check_conflict_horse(start_item, end_item)
    elsif type == :torr
      res = check_conflict_rook(start_item, end_item)
    end
    return res 
  end
  
  ##
  # Check if more than one horse could reach the end position
  def check_conflict_horse(start_item, end_item)
    res = ''
    horse_list = get_piece_list(:cav, start_item.color_piece)
    if horse_list.size > 2
      raise "Error More then 2 horses. why?"
    end
    # iterate horses  
    horse_list.each do |horse|
      if horse.row == start_item.row and 
         horse.col == start_item.col
         # same pice as start_item
        next
      end
      # the second piece, check if the end position is compatible
      if (end_item.row == horse.row - 1 or end_item.row == horse.row + 1) and
         (end_item.col == horse.col - 2 or end_item.col == horse.col + 2)
         # end position compatible with the first
         #p "extra info horse column #{start_item.color_piece}"
         #print_board
         if start_item.col == horse.col
           res = "#{start_item.row + 1}"
         else
           res = start_item.colix_tostr
         end
      end 
      # another possibility
      if (end_item.row == horse.row - 2 or end_item.row == horse.row + 2) and
         (end_item.col == horse.col - 1 or end_item.col == horse.col + 1)
         # end position compatible with the first
         #p "extra info horse column #{start_item.color_piece}"
         #print_board
         if start_item.col == horse.col
           res = "#{start_item.row + 1}"
         else
           res = start_item.colix_tostr
         end
      end
    end
    
    return res
  end
  
  ##
  # Check if more than on rook could reach the end position
  def check_conflict_rook(start_item, end_item)
    res = ''
    rook_list = get_piece_list(:torr, start_item.color_piece)
    if rook_list.size > 2
      raise "Error More then 2 rooks. why?"
    end
    rook_list.each do |rook|
      if rook.row == start_item.row and 
        rook.col == start_item.col
        # same pice as start_item
        next
      end
      # here we have the second rook
      # check if the final position is on the same row of the second rook
      if rook.row ==  end_item.row
        # check if the second rook could also reach the final position
        num = num_pieces_onrow(end_item, rook)
        if ( num == 0)
          #free street between, need more info: column of the start position
          #p "extra info rook row #{start_item.color_piece}"
          #print_board
          res =  start_item.colix_tostr
        end
      end
      # check if they are on the same column
      if rook.col ==  end_item.col
        num = num_pieces_oncolumn(end_item, rook)
        if ( num == 0)
          #free street between, need more info: row of the start position
          #p "extra info rook column #{start_item.color_piece}"
          #print_board
          res =  "#{start_item.row + 1}"
        end
      end
    end
    return res
  end
  
  ##
  # Provides a pices list on the board
  def get_piece_list(type, color)
    piece_list = []
    @infosquare.each do |row|
      row.each do |item|
        if item.type_piece == type and item.color_piece == color
          piece_list << item
        end
      end
    end
    return piece_list
  end
  
  ##
  # Make castle. Item in move is the king. we have also to move the rook
  def move_castle(start_item, end_item)
    # move the king
    BoardInfoItem.exchange(start_item, end_item)
    # move the rook
    king_row = end_item.row
    king_end_col = end_item.col
    rook_start_col = 0
    if king_end_col == 6
      # short castle
      rook_start_col = 7
      rook_end_col = king_end_col - 1
    else
      # long castle
      rook_start_col = 0
      rook_end_col = king_end_col + 1
    end
    
    rook_start_item =  @infosquare[king_row][rook_start_col]
    rook_end_item =  @infosquare[king_row][rook_end_col]
    BoardInfoItem.exchange(rook_start_item, rook_end_item)
  end
  
  ##
  # Number of pieces between two column on the same row
  def num_pieces_onrow(item1, item2)
    row_ref = item1.row
    col_info = [item1.col, item2.col]
    below = col_info.min
    upper = col_info.max
    num_res = 0
    @infosquare[row_ref].each do |item|
      if item.col <= below 
        next
      end
      if item.col >= upper 
        break
      end
      #valid range column
      if item.type_piece != :vuoto
        num_res += 1
      end
    end
    return num_res
  end
  
  ##
  # Check between two items if on the same column there are pieces
  def num_pieces_oncolumn(item1, item2)
    col_refe = item1.col
    rows_info = [item1.row, item2.row]
    below = rows_info.min
    upper = rows_info.max
    num_res = 0
    @infosquare.each do |row|
      if row.first.row <= below 
        next
      end
      if row.first.row >= upper 
        break
      end
      # valid range row
      item = row[col_refe]
       
      if item.type_piece != :vuoto
        num_res += 1
      end
    end
    return num_res
  end
  
  #
  # Process arr of pgn moves,. e.g. ["e4", "e5",...]
  def process_pgn_moves(arr_raw_pgn_move)
    #@color_on_turn = :white
    arr_raw_pgn_move.each do |move_str|
      
      if move_str == "1-0" or 
        move_str == "0-1"  or
        move_str == "1/2-1/2"
        @current_match.set_result(move_str)
        break
      end
      argument = trasform_pgn_move_inmymove(move_str)
      
      @current_match.add_pgn_move(move_str)
      @current_match.add_move(argument)
      
      do_the_move(argument)
      swap_color_on_turn
    end
  end
  
  def trasform_pgn_move_inmymove(move_str)
    argument = {:color => @color_on_turn, :movetype => :move}
    start_x =  start_y = end_x= end_y = 0
    if move_str == 'O-O'
      start_x = @color_on_turn == :white ? 0 : 7
      start_y = 4
      end_y = 6
      end_x = start_x
      argument[:movetype] = :shortcastle
    elsif move_str == 'O-O-O'
      argument[:movetype] = :longcastle
      start_x = @color_on_turn == :white ? 0 : 7 
      start_y = 4
      end_y = 2
      end_x = start_x
    else
      start_x, start_y, end_x, end_y = reco_pgn_piece(move_str)
      
    end
    
    argument[:start_x] = start_x
    argument[:start_y] = start_y 
    argument[:end_x] = end_x
    argument[:end_y] = end_y
    return argument
  end
  
  def reco_pgn_piece(move_str_unpure)
    @log.debug("reco_pgn_piece on move #{move_str_unpure}")
    move_str = move_str_unpure.gsub('x', '').gsub('ep', '').gsub('+', '').gsub('#', '')
    start_x = start_y = end_x = end_y = -1
    info = nil
    info_way = move_str.length + 1
    
    if move_str[0] == 'K'[0] 
      arr_pieces = pieces_get(:re, @color_on_turn)
      move_str = move_str[1..-1]
    elsif move_str[0] == 'Q'[0]
      arr_pieces = pieces_get(:reg, @color_on_turn)
      move_str = move_str[1..-1]
    elsif move_str[0] == 'N'[0]
      arr_pieces = pieces_get(:cav, @color_on_turn)
      move_str = move_str[1..-1]
    elsif move_str[0] == 'B'[0]
      arr_pieces = pieces_get(:alf, @color_on_turn)
      move_str = move_str[1..-1]
    elsif move_str[0] == 'R'[0]
      move_str = move_str[1..-1]
      arr_pieces = pieces_get(:torr, @color_on_turn)
    else
      arr_pieces = pieces_get(:ped, @color_on_turn)
    end
    
    if info_way == 2
      end_y = BoardInfoItem.colupstr_to_int(move_str[0,1])
      end_x = BoardInfoItem.rows_to_i(move_str[1,1])
    elsif info_way == 3
      start_x = info.column_start
      start_y = info.row_start
      end_y = BoardInfoItem.colupstr_to_int(move_str[1,1])
      end_x = BoardInfoItem.rows_to_i(move_str[2,1])
    elsif info_way == 4  
      start_x = BoardInfoItem.colupstr_to_int(move_str[0,1])
      start_y = BoardInfoItem.colupstr_to_int(move_str[1,1])
      end_y = BoardInfoItem.colupstr_to_int(move_str[2,1])
      end_x = BoardInfoItem.rows_to_i(move_str[3,1])
    end

    arr_pieces.each do |pez|
      pez.generate_possible_moves(self)
      if pez.possible_move_has?(start_x, start_y, end_x, end_y)
        info = pez
        @log.debug "Moving piece: #{pez.to_string_piece} #{BoardInfoItem.row_to_s(start_y)}#{pez.colix_tostr} - #{BoardInfoItem.column_to_s(end_x)}#{BoardInfoItem.row_to_s(end_y)}"
        break
      end
    end
    
    if info == nil
      @log.error "piece not recognized on #{move_str_unpure} or invalid move"
    else 
      start_x = info.column_start
      start_y = info.row_start
    end
    
    return start_x, start_y, end_x, end_y
  end
  
  # piece_key: :ped, :re,...
  # color: :white, :black
  def pieces_get(piece_key, color)
    res = []
    @pieces[color].each do |v|
      if v.type_piece ==  piece_key 
        res << v
      end
    end
    return res
  end
  
  def swap_color_on_turn
    if @color_on_turn == :white 
      @color_on_turn = :black
    else
      @color_on_turn = :white
    end
  end
  
  ##
  # Print the board
  def print_board
    puts "Current chess board (black player view):"
    strline = ''
    board_lines = []
    count = 1
    @infosquare.each do |row|
      line_coll = []
      # we are on black, need to reverse row
      row.reverse.each do |column|
        line_coll << column.to_ascii_board_piece
      end
      strline = "#{count}" + '| ' + line_coll.join(' | ') + " |\n"
      board_lines << strline
      numcar = strline.chomp.length
      strline = ''
      numcar.times{|ix| strline += '-'}
      board_lines << strline
      count += 1
    end
    # insert the last line also at the begin
    board_lines.insert(0,strline )
    # letters below the chess board
    strline = '  '
    ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'].reverse.each do |let|
      strline += " #{let}   "
    end
    board_lines << strline
    # render collected lines
    board_lines.each{|line| log line}
  end
  
  def log(str)
    puts str
  end
  
end # end board

if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  
  board = Board.new
  #board.init_pos
  
  #p pieces = board.pieces_get(:ped, :black)
  fen_str = "1N5r/7b/8/8/2ppp2p/B4Q1r/k3PR1P/1RK5 w - - 0 1"
  board.board_with_fen(fen_str)
  board.print_board
  #board.reco_pgn_piece("Bb4")
end
