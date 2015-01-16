#file: pgn_parser.rb

require 'Board'

class PgnParser
  
  def initialize
    @m_strText = ""
    @m_iStartPos = 0
    @m_iPos = 0
    @m_iSize = 0
    @board = Board.new
    @m_bDiagnose = false
    @log = Log4r::Logger["coregame_log"]
  end
  
  def peek_chr
    if @m_iPos < @m_iSize
      return @m_strText[@m_iPos, 1]
    else
      return '\0'
    end
  end
  
  def get_chr
    if @m_iPos < @m_iSize
      car =  @m_strText[@m_iPos, 1]
      @m_iPos += 1
      return car
    else
      return '\0'
    end
  end
  
  def skip_space
    while @m_iPos < @m_iSize and is_white_space?(@m_strText[@m_iPos])
      @m_iPos += 1
    end
  end
  
  def is_white_space?(car)
    if car == ' ' or car == 32
      return true
    else
      return false
    end
  end
  
  def is_digit?(car)
    if car[0] >= '0'[0] and car[0] <= '9'[0]
      return true
    else
      return false
    end
  end
  
  def skip_alt_move_and_remark 
      #p peek_chr
      #p @m_strText[@m_iPos]
      #p is_white_space?(@m_strText[@m_iPos])
      #p 'skip space'
      skip_space()
      #p peek_chr
      cSkipChr = peek_chr()
      while (cSkipChr == '(' or cSkipChr == '{')
          cEndSkip = (cSkipChr == '(') ? ')' : '}'
          cChr = get_chr()
          while (cChr != cEndSkip and cChr != '\0') 
              cChr = get_chr()
          end
          skip_space()
          cSkipChr = peek_chr()
      end
  end
  
  def decode_move(strPos)
    iStartCol = 0
    iStartRow = 0
    iEndPos = 0
    case strPos.length
      when 2
        if (strPos[0] < 'a' or strPos[0] > 'h' or
            strPos[1] < '1' or strPos[1] > '8') 
            raise("Unable to decode position")
        end
        iStartCol   = -1;
        iStartRow   = -1;
        iEndPos     = (7 - (strPos[0] - 'a')) + ((strPos[1] - '1') << 3);
      when 3
        if (strPos[0] >= 'a' and strPos[0] <= 'h') 
            iStartCol   = 7 - (strPos[0] - 'a');
            iStartRow   = -1;
         elsif (strPos[0] >= '1' and strPos[0] <= '8') 
              iStartCol   = -1;
              iStartRow   = (strPos[0] - '1');
          else 
              raise("Unable to decode position")
          end
          if (strPos[1] < 'a' or strPos[1] > 'h' or
              strPos[2] < '1' or strPos[2] > '8') 
                raise("Unable to decode position")
          end
          iEndPos     = (7 - (strPos[1] - 'a')) + ((strPos[2] - '1') << 3);
       when 4
         if (strPos[0] < 'a' or strPos[0] > 'h' or
             strPos[1] < '1' or strPos[1] > '8' or
             strPos[2] < 'a' or strPos[2] > 'h' or
             strPos[3] < '1' or strPos[3] > '8') 
              raise("Unable to decode position");
           end
           iStartCol   = 7 - (strPos[0] - 'a');
           iStartRow   = (strPos[1] - '1');
           iEndPos     = (7 - (strPos[2] - 'a')) + ((strPos[3] - '1') << 3);
       else
          raise("Unable to decode position")
    end#end case
    return [iStartCol, iStartRow, iEndPos]
  end#end decode_move
  
  def parse_attr(dict)
    strbName = "";
    strbValue = "";
    cChr = "";
    get_chr();
    cChr        = get_chr();
    while (!is_white_space?(cChr) and cChr != ']' and cChr != '\0') 
        strbName.concat(cChr);
        cChr = get_chr();
    end
      if (is_white_space?(cChr)) 
          skip_space();
          cChr = get_chr();
          if (cChr == '"') 
              cChr = get_chr();
              while (cChr != '"' and cChr != '\0') 
                  strbValue.concat(cChr);
                  cChr = get_chr();
              end
              skip_space();
              cChr = get_chr();
          end
      end #end if is_white
      if (cChr != ']') 
          raise("Syntax error");
      end
      dict[strbName.upcase] =  strbValue
      return dict
  end # end parse_attr
  
  def parse_file_content(str_text)
    #p str_text
    @m_strText = str_text
    @m_iStartPos = 0
    @m_iPos = 0
    @m_iSize = str_text.length
    skip_alt_move_and_remark()
    while(peek_chr() != '\0')
      @m_iStartPos = @m_iPos
      parse_next_move_list()
      if @m_iStartPos == @m_iPos
        @log.warn "No move recognized..., terminate"
        break
      end
    end
  end
  
  def parse_next_move_list()
    attrs = {}
    skip_alt_move_and_remark();
    
    while (peek_chr() == '[') 
        parse_attr(attrs);
        skip_alt_move_and_remark();
        #p "while #{peek_chr()}"
    end
    #p peek_chr()
    p attrs
    #p @m_iPos
    #exit
    @board.create_new_match
    @board.set_curr_match_attributes(attrs)
    
    iMoveIndex = 1;
    bEndOfMove = false;
    arrRawMove = []
    while (!bEndOfMove)
      strMove = parse_raw_move(iMoveIndex)
      arrStr = strMove.split(' ');
      if (arrStr.size == 2) 
          arrRawMove << arrStr[0]
          arrRawMove << arrStr[1]
      elsif (arrStr.size == 1)
           arrRawMove << arrStr[0]
      else
          bEndOfMove = true;
      end
      iMoveIndex += 1
    end #end while
    p arrRawMove
    @board.process_pgn_moves(arrRawMove)
    #exit
    if (arrRawMove.size == 0)
        if (@m_bDiagnose)
            raise("Syntax error");
        end
        @iSkip += 1
    end
    
  end #end parse_next_move_list
  
  
  def  parse_raw_move(iMoveIndex)
    strMove = ""
    iCount = 0
    cChr = ''
    
    strbMoveIndex   = ""
    strbMove        = ""
    strMove         = ""
    skip_alt_move_and_remark()
    if (is_digit?(peek_chr()))
        cChr = get_chr();
        while (is_digit?(cChr))
            strbMoveIndex.concat(cChr);
            cChr = get_chr();
          end
          if (iMoveIndex == strbMoveIndex.to_i and cChr == '.')
              skip_alt_move_and_remark()
              cChr    = get_chr();
              iCount  = 0;
              for iIndex in 0..1 do 
                while (!is_white_space?(cChr) and cChr != '\0')
                      strbMove.concat(cChr);
                      iCount += 1
                      cChr = get_chr();
                    end
                    skip_alt_move_and_remark()
                    if (iIndex == 0 and peek_chr() != '\0')
                        strbMove.concat(' ')
                        cChr = get_chr();
                    end
                    if (iCount == 0)
                          return ""
                    end
              end#end for
       end#end if (iMoveIndex == strbMoveIndex.to_i
       strMove = strbMove
     end#end if (is_digit?(peek_chr()))
     #p strMove
     return strMove
  end #end parse_raw_move
  
  def parse_pgn_file(fname)
    @log.debug "Process filename: #{fname}"
    @iSkip = 0
    str_content = ""
    File.open(fname, 'r').each_line do |line|
      str_content += line.chomp 
      str_content += " "
      #str_content += line
    end
    #p str_content
    parse_file_content(str_content)
  end
  
end #end PgnParser


if $0 == __FILE__
  require 'rubygems'
  require 'log4r'
  require 'yaml'
  
  include Log4r
  log = Log4r::Logger.new("coregame_log")
  log.outputters << Outputter.stdout
  
  parser = PgnParser.new
  parser.parse_pgn_file('Berliner00.pgn')
end