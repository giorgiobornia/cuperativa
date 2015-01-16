class HuoMatrix
  def initialize(row,col)
    @rows = Array.new(row)
    for i in 0..@rows.size-1 
      @rows[i] = Array.new(col)
    end
  end
  
  def [](i, j)
    @rows[i][j]
  end
  
  def []=(i, j, ele)
    @rows[i][j] = ele
  end
  
end

class String
  def CompareTo(str)
    return 0 if self.eql? str
    return 1
  end
  def self.Concat(*args)
    return args.join
  end
end

class Console
  def self.WriteLine(str)
    puts str
  end
  
  def self.Write(str)
    print str
  end
  
  #def self.ReadLine()
    #data = gets
    #data.chomp!
    #return data
  #end
  @@mydata = ['5', 'd', '7', 'd','5', 'e', '7', 'e', 'b']
  def self.ReadLine()
    data = @@mydata.pop
    p "provides data #{data}"
    return data
  end
end


class HuoChess_main 
      
      def initialize
        
        ######################/
        # Huo Chess                               #
        # version: 0.82                           #
        # Changes from version 0.81: Removed the  #
        # ComputerMove functions and used a       #
        # template function to create all new     #
        # ComputerMove functions I need.          #
        # Changes from version 0.722: Changed the #
        # ComputerMove, HumanMove, CountScore,    #
        # ElegxosOrthotitas functions.            #
        # Changes from verion 0.721: removed some #
        # useless code and added the variable     #
        # thinking depth (depending on the piece  #
        # the opponent moves) (see parts marked   #
        # with "2009 version 1 change")           #
        # Changes from version 0.6: Added more    #
        # thinking depths                         #
        # Year: 2008                              #
        # Place: Earth - Greece                   #
        # Programmed by Spiros I. Kakos (huo)     #
        # License: TOTALLY FREEWARE!              #
        #          Do anything you want with it!  #
        #          Spread the knowledge!          #
        #          Fix its bugs!                  #
        #          Sell it (if you can...)!       #
        #          Call me for help!              #
        # Site: www.kakos.com.gr                  #
        #       www.kakos.eu                      #
        ######################/

        #############################################/
        # MAIN ALGORITHM
        # 1. ComputerMove: Scans the chessboard and makes all possible moves.
        # 2. CheckMove: It checks the legality and correctness of these possible moves.
        # 3. (if thinking depth not reached) => call HumanMove
        # 4. HumanMove: Checks and finds the best answer of the human opponent.
        # 5. ComputerMove2: Scans the chessboard and makes all possible moves at the next thinking level.
        # 6. CheckMove: It checks the legality and correctness of these possible moves.
        # 7. (if thinking depth not reached) => call HumanMove
        # 8. HumanMove: Checks and finds the best answer of the human opponent.
        # 9. ComputerMove4: Scans the chessboard and makes all possible moves at the next thinking level.
        # 10. CheckMove: It checks the legality and correctness of these possible moves.
        # 11. (if thinking depth reached) => record the score of the final position.
        # 12. (if score of position the best so far) => record the move as best move!
        # 13. The algorithm continues until all possible moves are scanned.
        # SET huo_debug to TRUE to see live the progress of the computer thought!
        # FIND us at Codeproject (www.codeproject.com) or MSDN Code Gallery!
        ##############################################


        #public:
        ####################################################
        # DECLARE VARIABLES
        ####################################################

        #########/
        # 2009 v4 change
        #########/
        @@danger_penalty = 0;
        @@Destination_Piece_Value = 0;
        @@Moving_Piece_Value = 0;

        # v0.82
        # ISS commented
        #~ @@HuoChess_new_depth_2 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_4 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_6 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_8 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_10 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_12 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_14 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_16 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_18 = HuoChess_main.new;
        #~ @@HuoChess_new_depth_20 = HuoChess_main.new;
        # v0.82
        #########/
        # 2009 v4 change
        #########/

        # UNCOMMENT TO SHOW THINKING TIME!
        # (this and the other commands that use 'start' variable to record thinking time...)
        # public static int start; 

        # the chessboard (=@@Skakiera in Greek)
        @@Skakiera = HuoMatrix.new(8,8);  # Δήλωση πίνακα που αντιπροσωπεύει τη σκακιέρα

        # CODE FOR COMPARISON
        @@number_of_moves_analysed = 0;

        # Variable to note if the computer moves its piece to a square threatened by a pawn
        @@knight_pawn_threat = 0;
        @@bishop_pawn_threat = 0;
        @@rook_pawn_threat = 0;
        @@queen_pawn_threat = 0;
        @@checked_for_pawn_threats = 0;

        # Variable which determines of the program will show the inner
        # thinking process of the AI. Good for educational purposes!!!
        # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
        #bool huo_debug;

        # Arrays to use in ComputerMove function
        # Changed in version 0.5
        # Penalty for moving the only piece that defends a square to that square (thus leavind the defender
        # alone in the square he once defended, defenceless!)
        # This penalty is also used to indicate that the computer loses its Queen with the move analyzed
        @@Danger_penalty = 0;
        #bool LoseQueen_penalty;
        # Penalty for moving your piece to a square that the human opponent can hit with more power than the computer.
        @@Attackers_penalty = 0;
        # Penalty if the pieces of the human defending a square in which the computer movies in, have much less
        # value than the pieces the computer has to support the attack on that square
        @@Defenders_value_penalty = 0;

        @@m_PlayerColor = "Black";
        @@m_ComputerLevel = "Kakos";
        @@m_WhoPlays = "HY";
        @@m_WhichColorPlays = 0;
        @@MovingPiece = 0;

        # variable to store temporarily the piece that is moving
        @@ProsorinoKommati = 0;
        @@ProsorinoKommati = 0;

        # variables to check the legality of the move
        @@exit_elegxos_nomimothtas = false;
        @@h = 0;
        @@p = 0;
        @@how_to_move_Rank = 0;
        @@how_to_move_Column = 0;
        @@hhh = 0;

        # NEW
        @@kopa = 1;
        @@KingCheck = false;

        # coordinates of the starting square of the move
        @@m_StartingColumn = 0;
        @@m_StartingRank = 0;
        @@m_FinishingColumn = 0;
        @@m_FinishingRank = 0;

        # variable for en passant moves
        @@enpassant_occured = 0;

        # move number
        @@Move = 0;

        # variable to show if promotion of a pawn occured
        @@Promotion_Occured = false;

        # variable to show if castrling occured
        @@Castling_Occured = false;

        # variables to help find out if it is legal for the computer to perform castling
        @@White_King_Moved = false;
        @@Black_King_Moved = false;
        @@White_Rook_a1_Moved = false;
        @@White_Rook_h1_Moved = false;
        @@Black_Rook_a8_Moved = false;
        @@Black_Rook_h8_Moved = false;
        @@Can_Castle_Big_White = 0;
        @@Can_Castle_Big_Black = 0;
        @@Can_Castle_Small_White = 0;
        @@Can_Castle_Small_Black = 0;

        # variables to show where the kings are in the chessboard
        @@WhiteKingColumn = 0;
        @@WhiteKingRank = 0;
        @@BlackKingColumn = 0;
        @@BlackKingRank = 0;

        # variables to show if king is in check
        @@WhiteKingCheck = 0;
        @@BlackKingCheck = 0;

        # variables to show if there is a possibility for mate
        @@WhiteMate = false;
        @@BlackMate = false;
        @@Mate = 0;

        # variable to show if a move is found for the hy to do
        @@Best_Move_Found = 0;

        # variables to help find if a king is under check.
        # (see CheckForWhiteCheck and CheckForBlackCheck functions)
        @@DangerFromRight = 0;
        @@DangerFromLeft = 0;
        @@DangerFromUp = 0;
        @@DangerFromDown = 0;
        @@DangerFromUpRight = 0;
        @@DangerFromDownRight = 0;
        @@DangerFromUpLeft = 0;
        @@DangerFromDownLeft = 0;

        # initial coordinates of the two kings
        # (see CheckForWhiteCheck and CheckForBlackCheck functions)
        @@StartingWhiteKingColumn = 0;
        @@StartingWhiteKingRank = 0;
        @@StartingBlackKingColumn = 0;
        @@StartingBlackKingRank = 0;

        # column number inserted by the user
        @@m_StartingColumnNumber = 0;
        @@m_FinishingColumnNumber = 0;

        #################################################/
        # Μεταβλητές για τον έλεγχο της "ορθότητας" και της "νομιμότητας" μιας κίνησης του χρήστη
        #################################################/

        # variable for the correctness of the move
        @@m_OrthotitaKinisis = 0;
        # variable for the legality of the move
        @@m_NomimotitaKinisis = 0;
        # has the user entered a wrong column?
        @@m_WrongColumn = 0;

        # variables for 'For' loops
        #public static int i;
        #public static int j;

        @@ApophasiXristi = 1;

        ###################
        # Computer Thought
        ###################
        # Chessboards used for the computer throught
#        public static String[,] Skakiera_Move_0 = new String[8, 8]; # Δήλωση πίνακα που αντιπροσωπεύει τη σκακιέρα
#        public static String[,] Skakiera_Move_After = new String[8, 8];
#        public static String[,] Skakiera_Thinking = new String[8, 8];
#        
        @@Skakiera_Move_0 = HuoMatrix.new(8,8); 
        @@Skakiera_Move_After = HuoMatrix.new(8,8); 
        @@Skakiera_Thinking = HuoMatrix.new(8,8); 
        
        # rest of variables used for computer thought
        @@Best_Move_Score = 0;
        @@Current_Move_Score = 0;
        @@Best_Move_StartingColumnNumber = 0;
        @@Best_Move_FinishingColumnNumber = 0;
        @@Best_Move_StartingRank = 0;
        @@Best_Move_FinishingRank = 0;
        @@Move_Analyzed = 0;
        @@Stop_Analyzing = 0;
        @@Thinking_Depth = 0;
        @@m_StartingColumnNumber_HY = 0;
        @@m_FinishingColumnNumber_HY = 0;
        @@m_StartingRank_HY = 0;
        @@m_FinishingRank_HY = 0;
        @@First_Call = 0;
        @@Who_Is_Analyzed = 0;
        @@MovingPiece_HY = 0;

        # for writing the computer move
        @@HY_Starting_Column_Text = 0;
        @@HY_Finishing_Column_Text = 0;

        # chessboard to store the chessboard squares where it is dangerous
        # for the HY to move a piece
        # SEE function ComputerMove!
        #static array<String, 2> skakiera_Dangerous_Squares = new array<String, 2>(8,8);  # Δήλωση πίνακα που αντιπροσωπεύει τη σκακιέρα

        # variables which help find the best move of the human-opponent
        # during the HY thought analysis
#        public static String[,] Skakiera_Human_Move_0 = new String[8, 8];
#        public static String[,] Skakiera_Human_Thinking = new String[8, 8];
#        @@Skakiera_Human_Move_0 = HuoMatrix.new(8,8); # ISS non sembrano usate...
#        @@Skakiera_Human_Thinking = HuoMatrix.new(8,8); 
        
        
        @@First_Call_Human_Thought = 0;
        # 2009 version 1 change
        #public static int iii_Human;
        #public static int jjj_Human;
        @@MovingPiece_Human = "";
        @@m_StartingColumnNumber_Human = 1;
        @@m_FinishingColumnNumber_Human = 1;
        @@m_StartingRank_Human = 1;
        @@m_FinishingRank_Human = 1;
        @@Current_Human_Move_Score = 0;
        @@Best_Human_Move_Score = 0;
        @@Best_Move_Human_StartingColumnNumber = 0;
        @@Best_Move_Human_FinishingColumnNumber = 0;
        @@Best_Move_Human_StartingRank = 0;
        @@Best_Move_Human_FinishingRank = 0;
        @@Best_Human_Move_Found = 0;

        # does the HY eats the queen of his opponent with the move it analyzes?
        # Changed in version 0.5
        @@eat_queen = 0;

        # where the player can perform en passant
        @@enpassant_possible_target_rank = 0;
        @@enpassant_possible_target_column = 0;

        # is there a possible mate?
        @@Human_is_in_check = 0;
        @@Possible_mate = 0;

        # does the HY moves its King with the move it is analyzing?
        @@moving_the_king = 0;
        @@choise_of_user = 0;

        #################################################/
        # END OF VARIABLES DECLARATION
        #################################################/
      end #end initialize
      
      def set_huo_deph(huoChess_new_depth_2,huoChess_new_depth_4,huoChess_new_depth_6,huoChess_new_depth_8,
          huoChess_new_depth_10, huoChess_new_depth_12, huoChess_new_depth_14, huoChess_new_depth_16, 
          huoChess_new_depth_18, huoChess_new_depth_20)
        
        @@HuoChess_new_depth_2 = huoChess_new_depth_2
        @@HuoChess_new_depth_4 = huoChess_new_depth_4
        @@HuoChess_new_depth_6 = huoChess_new_depth_6
        @@HuoChess_new_depth_8 = huoChess_new_depth_8
        @@HuoChess_new_depth_10 = huoChess_new_depth_10
        @@HuoChess_new_depth_12 = huoChess_new_depth_12
        @@HuoChess_new_depth_14 = huoChess_new_depth_14
        @@HuoChess_new_depth_16 = huoChess_new_depth_16
        @@HuoChess_new_depth_18 = huoChess_new_depth_18
        @@HuoChess_new_depth_20 = huoChess_new_depth_20
        
      end
      
      #
      # Set initial player.
      # color: :white is white, :black is black
      def set_initial_color_of_hy(color)
        if color == :black
          @@m_PlayerColor = "White";
          @@m_WhoPlays = "Human";
          
        elsif color == :white
          @@m_PlayerColor = "Black";
          @@m_WhoPlays = "HY";
        else
          @log.error("invalid color #{color}")
        end
        @init_player_color = @@m_PlayerColor
        @init_who_plays = @@m_WhoPlays
        #p @@m_WhoPlays
      end
      
      def init_game(player_name)
        @log = Log4r::Logger["coregame_log"]
        @@Thinking_Depth = 0 #default is 20
        @@White_King_Moved = false;
        @@Black_King_Moved = false;
        @@White_Rook_a1_Moved = false;
        @@White_Rook_h1_Moved = false;
        @@Black_Rook_a8_Moved = false;
        @@Black_Rook_h8_Moved = false;
        @@Can_Castle_Big_White = true;
        @@Can_Castle_Big_Black = true;
        @@Can_Castle_Small_White = true;
        @@Can_Castle_Small_Black = true;
        @@Move = 0;
        @@m_WhichColorPlays = "White";
        @player_name = player_name
        starting_position()
      end
      
      # start_col,fin_col: string A-H
      # start_rank,fin_rank: integer 1-8
      def set_human_move(start_col, start_rank, fin_col, fin_rank)
        @@m_StartingColumn = start_col
        @@m_StartingRank = start_rank
        @@m_FinishingColumn = fin_col
        @@m_FinishingRank = fin_rank
        
       
        Enter_move()
      end
      
      def make_hy_move
        @log.debug "move for #{@player_name}"
        @last_move_hy = []
        #@@m_PlayerColor = @init_player_color
        #@@m_WhoPlays = @init_who_plays
        if @@m_WhoPlays != "HY"
          @log.error("make_hy_move is not playing, but #{@@m_WhoPlays}")
          return []
        end
        @@Move = 0
        @@Move_Analyzed = 0
        @@Stop_Analyzing = false
        @@First_Call = true
        @@Best_Move_Found = false
        @@Who_Is_Analyzed = "HY"
        
        ComputerMove(@@Skakiera)
        return @last_move_hy
      end

      def DoGame()
            ##########/
            # Setup game
            ##########/
            Console.Write("Choose color (w/b): ");
            the_choise_of_user = Console.ReadLine();
            @@m_WhoPlays = "HY"
            if ((the_choise_of_user.CompareTo("w") == 0) || (the_choise_of_user.CompareTo("W") == 0))
                @@m_PlayerColor = "White";
                @@m_WhoPlays = "Human";
            elsif ((the_choise_of_user.CompareTo("b") == 0) || (the_choise_of_user.CompareTo("B") == 0))
                @@m_PlayerColor = "Black";
                @@m_WhoPlays = "HY";
            end

            ####################################/
            # UNCOMMENT THE FOLLOWING TO HAVE MORE THINKING DEPTHS
            # BUT REMEMBER TO ALSO UNCOMMENT ComputerMove4,6,8 functions and
            # the respective part in HumanMove function that calls them!
            ####################################/
            # ΠΡΟΣΟΧΗ: Αν βάλω τον υπολογιστή να σκεφτεί σε βάθος 1 κίνησης
            # (ήτοι @@Thinking_Depth = 0), τότε ΔΕΝ σκέφτεται σωστά! Αυτό συμβαίνει
            # διότι η HumanMove πρέπει να κληθεί τουλάχιστον μία φορά για να
            # ολοκληρωθεί σωστά τουλάχιστον ένας πλήρης κύκλος σκέψης του ΗΥ.
            ####################################/
            #Console.Write("Enter level (1-4) : ");
            #@@choise_of_user = Int32.Parse(Console.ReadLine());

            #switch(@@choise_of_user)
            #{
            #case 1:
            #@@m_ComputerLevel = "M";
            #	@@Thinking_Depth = 2;
            #	break;

            #case 2:
            #@@m_ComputerLevel = "GM";
            #	@@Thinking_Depth = 4;
            #	break;

            #case 3:
            #@@m_ComputerLevel = "World Champion";
            #	@@Thinking_Depth = 6;
            #	break;

            #case 4:
            #@@m_ComputerLevel = "Spiros Kakos";
            #	@@Thinking_Depth = 8;
            #	break;

            ##########/
            # 2009 v4 change
            ##########/
            # PLAYING
         #@@Thinking_Depth = 20; # ISS valore di default 20
         @@Thinking_Depth = 0
            # PLAYING END
            ##########/
            # 2009 v4 change
            ##########/

            #default:
            #@@m_ComputerLevel = "";
            #	break;
            #};

            ##############################
            # SHOW THE INNER THINKING PROCESS OF THE COMPUTER?
            # GOOD FOR EDUCATIONAL PURPOSES!
            # SET huo_debug to TRUE to show inner thinking process!
            ##############################
            #Console.Write("Show thinking process (y/n)? ");
            #the_choise_of_user = Console.ReadLine();
            #if((the_choise_of_user.CompareTo("y") == 0)||(the_choise_of_user.CompareTo("Y") == 0))
            #	huo_debug = true;
            #elsif((the_choise_of_user.CompareTo("n") == 0)||(the_choise_of_user.CompareTo("N") == 0))
            #	huo_debug = false;

            Console.WriteLine("\nHuo Chess v0.82 by Spiros I.Kakos (huo) [2009] - C# Edition");

            # initial values
            @@White_King_Moved = false;
            @@Black_King_Moved = false;
            @@White_Rook_a1_Moved = false;
            @@White_Rook_h1_Moved = false;
            @@Black_Rook_a8_Moved = false;
            @@Black_Rook_h8_Moved = false;
            @@Can_Castle_Big_White = true;
            @@Can_Castle_Big_Black = true;
            @@Can_Castle_Small_White = true;
            @@Can_Castle_Small_Black = true;
            @@Move = 0;
            @@m_WhichColorPlays = "White";

            # fix startup position
            starting_position();

            # if it is the turn of HY to play, then call the respective function
            # to implement HY thought

            exit_game = false;

            while (exit_game == false)
                if (@@m_WhoPlays.CompareTo("HY") == 0)
                    # call HY Thought function
                    @@Move = 0;

                    if (@@Move == 0)
                        Console.WriteLine("");
                        Console.WriteLine("Thinking...");
                    end

                    @@Move_Analyzed = 0;
                    @@Stop_Analyzing = false;
                    @@First_Call = true;
                    @@Best_Move_Found = false;
                    @@Who_Is_Analyzed = "HY";
                    ComputerMove(@@Skakiera);
                elsif (@@m_WhoPlays.CompareTo("Human") == 0)
                    ##############
                    # Human enters his move
                    ##############
                    Console.WriteLine("");
                    Console.Write("Starting column (A to H)...");
                    @@m_StartingColumn = Console.ReadLine().upcase;

                    Console.Write("Starting rank (1 to 8).....");
                    @@m_StartingRank = Console.ReadLine.to_i

                    Console.Write("Finishing column (A to H)...");
                    @@m_FinishingColumn = Console.ReadLine().upcase;

                    Console.Write("Finishing rank (1 to 8).....");
                    @@m_FinishingRank = Console.ReadLine.to_i

                    # show the move entered

                    huoMove = String.Concat("Your move: ", @@m_StartingColumn, @@m_StartingRank.to_s, " -> ");

                    huoMove = String.Concat(huoMove, @@m_FinishingColumn, @@m_FinishingRank.to_s);
                    Console.WriteLine(huoMove);

                    #StreamWriter huo_sw3 = new StreamWriter("game.txt", true);
                    #huo_sw3.WriteLine(huoMove);
                    #huo_sw3.Close();

                    Console.WriteLine("");
                    Console.WriteLine("Thinking...");

                    # check the move entered by the human for correctness (='Orthotita' in Greek)
                    # and legality (='Nomimotita' in Greek)
                    Enter_move();
                end
          end 
        end #end DoGame

      def CheckForBlackCheck(bCSkakiera) 
            # TODO: Add your control notification handler code here

            kingCheck = false;

            #######################################################/
            # Εύρεση των συντεταγμένων του βασιλιά.
            # Αν σε κάποιο τετράγωνο βρεθεί ότι υπάρχει ένας βασιλιάς, τότε απλά καταγράφεται η τιμή του εν λόγω
            # τετραγώνου στις αντίστοιχες μεταβλητές που δηλώνουν τη στήλη και τη γραμμή στην οποία υπάρχει μαύρος
            # βασιλιάς.
            # ΠΡΟΣΟΧΗ: Γράφω (i+1) αντί για i και (j+1) αντί για j γιατί το πρώτο στοιχείο του πίνακα bCSkakiera[(8),(8)]
            # είναι το bCSkakiera[(0),(0)] και ΟΧΙ το bCSkakiera[(1),(1)]!
            #######################################################/

            for i in 0..7 do
                for j in 0..7 do
                    if (bCSkakiera[(i), (j)].CompareTo("Black King") == 0)
                        @@BlackKingColumn = (i + 1);
                        @@BlackKingRank = (j + 1);
                    end
                end
            end

            ###############################/
            # Έλεγχος του αν ο μαύρος βασιλιάς υφίσταται "σαχ"
            ###############################/

            kingCheck = false;

            ########################################################
            # Ελέγχουμε αρχικά αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΤΑ ΔΕΞΙΑ ΤΟΥ. Για να μην βγούμε έξω από τα
            # όρια της bCSkakiera[(8),(8)] έχουμε προσθέσει τον έλεγχο (@@BlackKingColumn + 1) <= 8 στο "if". Αρχικά ο "κίνδυνος"
            # από τα "δεξιά" είναι υπαρκτός, άρα @@DangerFromRight = true. Ωστόσο αν βρεθεί ότι στα δεξιά του μαύρου βασι-
            # λιά υπάρχει κάποιο μαύρο κομμάτι, τότε δεν είναι δυνατόν ο εν λόγω βασιλιάς να υφίσταται σαχ από τα δεξιά
            # του (αφού θα "προστατεύεται" από το κομμάτι ιδίου χρώματος), οπότε η @@DangerFromRight = false και ο έλεγχος
            # για απειλές από τα δεξιά σταματάει (για αυτό και έχω προσθέσει την προϋπόθεση (@@DangerFromRight == true) στα
            # "if" που κάνουν αυτόν τον έλεγχο).
            # Αν όμως δεν υπάρχει κανένα μαύρο κομμάτι δεξιά του βασιλιά για να τον προστατεύει, τότε συνεχίζει να
            # υπάρχει πιθανότητα να απειλείται ο βασιλιάς από τα δεξιά του, οπότε ο έλεγχος συνεχίζεται.
            # Σημείωση: Ο έλεγχος γίνεται για πιθανό σαχ από πύργο ή βασίλισσα αντίθετου χρώματος.
            ########################################################

            @@DangerFromRight = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn + klopa) <= 8) && (@@DangerFromRight == true))
                    if ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromRight = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - 1)].CompareTo("White King") == 0))
                        @@DangerFromRight = false;
                    end
                end
            end

            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΤΑ ΑΡΙΣΤΕΡΑ ΤΟΥ (από πύργο ή βασίλισσα).
            ###################################################/

            @@DangerFromLeft = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn - klopa) >= 1) && (@@DangerFromLeft == true))
                    if ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromLeft = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - 1)].CompareTo("White King") == 0))
                        @@DangerFromLeft = false;
                    end
                end
            end

            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΠΑΝΩ (από πύργο ή βασίλισσα).
            ###################################################/

            @@DangerFromUp = true;

            for klopa in 1..7 do
                if (((@@BlackKingRank + klopa) <= 8) && (@@DangerFromUp == true))
                    if ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromUp = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromUp = false;
                    end
                end
            end

            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΚΑΤΩ (από πύργο ή βασίλισσα).
            ###################################################/

            @@DangerFromDown = true;

            for klopa in 1..7 do
                if (((@@BlackKingRank - klopa) >= 1) && (@@DangerFromDown == true))
                    if ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromDown = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromDown = false;
                    end
                end
            end

            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΠΑΝΩ-ΔΕΞΙΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromUpRight = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn + klopa) <= 8) && ((@@BlackKingRank + klopa) <= 8) && (@@DangerFromUpRight == true))
                    if ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromUpRight = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromUpRight = false;
                    end
                end
            end

            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΚΑΤΩ-ΑΡΙΣΤΕΡΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromDownLeft = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn - klopa) >= 1) && ((@@BlackKingRank - klopa) >= 1) && (@@DangerFromDownLeft == true))
                    if ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromDownLeft = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromDownLeft = false;
                    end
                end
            end

            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΚΑΤΩ-ΔΕΞΙΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromDownRight = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn + klopa) <= 8) && ((@@BlackKingRank - klopa) >= 1) && (@@DangerFromDownRight == true))
                    if ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromDownRight = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn + klopa - 1), (@@BlackKingRank - klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromDownRight = false;
                    end
                end
            end

            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το μαύρο βασιλιά ΑΠΟ ΠΑΝΩ-ΑΡΙΣΤΕΡΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromUpLeft = true;

            for klopa in 1..7 do
                if (((@@BlackKingColumn - klopa) >= 1) && ((@@BlackKingRank + klopa) <= 8) && (@@DangerFromUpLeft == true))
                    if ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        kingCheck = true;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        @@DangerFromUpLeft = false;
                    elsif ((bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (bCSkakiera[(@@BlackKingColumn - klopa - 1), (@@BlackKingRank + klopa - 1)].CompareTo("White King") == 0))
                        @@DangerFromUpLeft = false;
                    end
                end
            end

            #####################################
            # Έλεγχος για το αν ο μαύρος βασιλιάς απειλείται από πιόνι.
            #####################################

            if (((@@BlackKingColumn + 1) <= 8) && ((@@BlackKingRank - 1) >= 1))
                if (bCSkakiera[(@@BlackKingColumn + 1 - 1), (@@BlackKingRank - 1 - 1)].CompareTo("White Pawn") == 0)
                    kingCheck = true;
                end
            end


            if (((@@BlackKingColumn - 1) >= 1) && ((@@BlackKingRank - 1) >= 1))
                if (bCSkakiera[(@@BlackKingColumn - 1 - 1), (@@BlackKingRank - 1 - 1)].CompareTo("White Pawn") == 0)
                    kingCheck = true;
                end
            end


            ###################################/
            # Έλεγχος για το αν ο μαύρος βασιλιάς απειλείται από ίππο.
            ###################################/

            if (((@@BlackKingColumn + 1) <= 8) && ((@@BlackKingRank + 2) <= 8))
                if (bCSkakiera[(@@BlackKingColumn + 1 - 1), (@@BlackKingRank + 2 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@BlackKingColumn + 2) <= 8) && ((@@BlackKingRank - 1) >= 1))
                if (bCSkakiera[(@@BlackKingColumn + 2 - 1), (@@BlackKingRank - 1 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@BlackKingColumn + 1) <= 8) && ((@@BlackKingRank - 2) >= 1))
                if (bCSkakiera[(@@BlackKingColumn + 1 - 1), (@@BlackKingRank - 2 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@BlackKingColumn - 1) >= 1) && ((@@BlackKingRank - 2) >= 1))
                if (bCSkakiera[(@@BlackKingColumn - 1 - 1), (@@BlackKingRank - 2 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end                
                    

            if (((@@BlackKingColumn - 2) >= 1) && ((@@BlackKingRank - 1) >= 1))
                if (bCSkakiera[(@@BlackKingColumn - 2 - 1), (@@BlackKingRank - 1 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end
                    

            if (((@@BlackKingColumn - 2) >= 1) && ((@@BlackKingRank + 1) <= 8))
                if (bCSkakiera[(@@BlackKingColumn - 2 - 1), (@@BlackKingRank + 1 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end 

            if (((@@BlackKingColumn - 1) >= 1) && ((@@BlackKingRank + 2) <= 8))
                if (bCSkakiera[(@@BlackKingColumn - 1 - 1), (@@BlackKingRank + 2 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end 

            if (((@@BlackKingColumn + 2) <= 8) && ((@@BlackKingRank + 1) <= 8))
                if (bCSkakiera[(@@BlackKingColumn + 2 - 1), (@@BlackKingRank + 1 - 1)].CompareTo("White Knight") == 0)
                    kingCheck = true;
                end
            end 

            return kingCheck;
      end #end CheckForBlackCheck

      def CheckForBlackMate(bMSkakiera) 
            # TODO: Add your control notification handler code here

#            bool  mate;

            ####################################################/
            # Μεταβλητή που χρησιμεύει στον έλεγχο για το αν υπάρχει ματ (βλ. συναρτήσεις CheckForWhiteMate() και
            # CheckForBlackMate()).
            # Αναλυτικότερα, το πρόγραμμα ελέγχει αν αρχικά υπάρχει σαχ και, αν υπάρχει, ελέγχει αν αυτό το
            # σαχ μπορεί να αποφευχθεί με τη μετακίνηση του υπό απειλή βασιλιά σε κάποιο γειτονικό τετράγωνο.
            # Η μεταβλητή καταγράφει το αν συνεχίζει να υπάρχει πιθανότητα να υπάρχει ματ στη σκακιέρα.
            ####################################################/

#            bool dangerForMate;

            ##############################
            # Έλεγχος του αν υπάρχει "ματ" στον μαύρο βασιλιά
            ##############################

            mate = false;
            dangerForMate = true;    # Αρχικά, προφανώς υπάρχει πιθανότητα να υπάρχει ματ στη σκακιέρα.
            # Αν, ωστόσο, κάποια στιγμή βρεθεί ότι αν ο βασιλιάς μπορεί να μετακινηθεί
            # σε ένα διπλανό τετράγωνο και να πάψει να υφίσταται σαχ, τότε παύει να
            # υπάρχει πιθανότητα να υπάρχει ματ (προφανώς) και η μεταβλητή παίρνει την
            # τιμή false.


            ###############################
            # Εύρεση των αρχικών συντεταγμένων του βασιλιά
            ###############################

            for i in 0..7 do
                for j in 0..7 do
                    if (bMSkakiera[(i), (j)].CompareTo("Black King") == 0)
                        @@StartingBlackKingColumn = (i + 1);
                        @@StartingBlackKingRank = (j + 1);
                    end
                end
            end


            #########################
            # Έλεγχος αν ο μαύρος βασιλιάς είναι ματ
            #########################


            if (@@m_WhichColorPlays.CompareTo("Black") == 0)

                ########################
                # Έλεγχος αν υπάρχει σαχ αυτή τη στιγμή
                ########################

                @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                if (@@BlackKingCheck == false)     # Αν αυτή τη στιγμή δεν υφίσταται σαχ, τότε να μη συνεχιστεί ο έλεγχος
                    dangerForMate = false;         # καθώς ΔΕΝ συνεχίζει να υφίσταται πιθανότητα να υπάρχει ματ.
                end

                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω
                #######################################################/

                if (@@StartingBlackKingRank < 8)
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 + 1)];
                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 + 1) <= 7))

                        # (Προσωρινή) μετακίνηση του βασιλιά προς τα πάνω και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.
                        # Ο έλεγχος γίνεται μόνο αν στο τετράγωνο που μετακινείται προσωρινά ο βασιλιάς δεν υπάρχει άλλο κομμάτι
                        # του ίδιου χρώματος που να τον εμποδίζει και αν, φυσικά, ο βασιλιάς δεν βγαίνει έξω από τη σκακιέρα με
                        # αυτή του την κίνηση και αν, προφανώς, συνεχίζει να υπάρχει πιθανότητα να ύπάρχει ματ (καθώς αν δεν
                        # υπάρχει τέτοια πιθανότητα, τότε ο έλεγχος είναι άχρηστος).

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 + 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 + 1)] = @@ProsorinoKommati;
                    end
                end#end if @@StartingBlackKingRank


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω-δεξιά
                #######################################################/

                if ((@@StartingBlackKingColumn < 8) && (@@StartingBlackKingRank < 8))

                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 + 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 + 1) <= 7) && ((@@StartingBlackKingColumn - 1 + 1) <= 7))

                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 + 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 + 1)] = @@ProsorinoKommati;

                    end

                end#end @@StartingBlackKingColumn


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα δεξιά
                #######################################################/

                if (@@StartingBlackKingColumn < 8)
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingColumn - 1 + 1) <= 7))
                    

                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1)] = @@ProsorinoKommati;
                    end
                end

                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω-δεξιά
                #######################################################/

                if ((@@StartingBlackKingColumn < 8) && (@@StartingBlackKingRank > 1))
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 - 1) >= 0) && ((@@StartingBlackKingColumn - 1 + 1) <= 7))

                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 - 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end
                    
                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.
                        
                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 + 1), (@@StartingBlackKingRank - 1 - 1)] = @@ProsorinoKommati;
                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω
                #######################################################/

                if (@@StartingBlackKingRank > 1)
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 - 1) >= 0))
                        # (Προσωρινή) μετακίνηση του βασιλιά προς τα πάνω και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 - 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1 - 1)] = @@ProsorinoKommati;
                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω-αριστερά
                #######################################################/

                if ((@@StartingBlackKingColumn > 1) && (@@StartingBlackKingRank > 1))
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 - 1) >= 0) && ((@@StartingBlackKingColumn - 1 - 1) >= 0))
                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 - 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 - 1)] = @@ProsorinoKommati;
                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα αριστερά
                #######################################################/

                if (@@StartingBlackKingColumn > 1)
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingColumn - 1 - 1) >= 0))
                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1)] = @@ProsorinoKommati;

                    end

                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο μαύρος βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω-αριστερά
                #######################################################/

                if ((@@StartingBlackKingColumn > 1) && (@@StartingBlackKingRank < 8))
                    @@MovingPiece = bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)];
                    @@ProsorinoKommati = bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 + 1)];

                    if ((@@ProsorinoKommati.CompareTo("Black Queen") == 1) && (@@ProsorinoKommati.CompareTo("Black Rook") == 1) && (@@ProsorinoKommati.CompareTo("Black Knight") == 1) && (@@ProsorinoKommati.CompareTo("Black Bishop") == 1) && (@@ProsorinoKommati.CompareTo("Black Pawn") == 1) && (dangerForMate == true) && ((@@StartingBlackKingRank - 1 + 1) <= 7) && ((@@StartingBlackKingColumn - 1 - 1) >= 0))
                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = "";
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 + 1)] = @@MovingPiece;
                        @@BlackKingCheck = CheckForBlackCheck(bMSkakiera);

                        if (@@BlackKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        bMSkakiera[(@@StartingBlackKingColumn - 1), (@@StartingBlackKingRank - 1)] = @@MovingPiece;
                        bMSkakiera[(@@StartingBlackKingColumn - 1 - 1), (@@StartingBlackKingRank - 1 + 1)] = @@ProsorinoKommati;

                    end
                end

                if (dangerForMate == true)
                    mate = true;
                end

            end #end if black

            return mate;
        end#end CheckForBlackMate
        
      def CheckForWhiteCheck(wCSkakiera) 

            kingCheck = false;

            #######################################################/
            # Εύρεση των συντεταγμένων του βασιλιά.
            # Αν σε κάποιο τετράγωνο βρεθεί ότι υπάρχει ένας βασιλιάς, τότε απλά καταγράφεται η τιμή του εν λόγω
            # τετραγώνου στις αντίστοιχες μεταβλητές που δηλώνουν τη στήλη και τη γραμμή στην οποία υπάρχει λευκός
            # βασιλιάς.
            # ΠΡΟΣΟΧΗ: Γράφω (i+1) αντί για i και (j+1) αντί για j γιατί το πρώτο στοιχείο του πίνακα WCWCSkakiera[(8),(8)]
            # είναι το wCSkakiera[(0),(0)] και ΟΧΙ το wCSkakiera[(1),(1)]!
            #######################################################/

            for i in 0..7 do
                for j in 0..7 do
                    if (wCSkakiera[(i), (j)].CompareTo("White King") == 0)
                        @@WhiteKingColumn = (i + 1);
                        @@WhiteKingRank = (j + 1);
                    end
                end
            end

            ###############################/
            # Έλεγχος του αν ο λευκός βασιλιάς υφίσταται "σαχ"
            ###############################/

            kingCheck = false;

            ########################################################
            # Ελέγχουμε αρχικά αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΤΑ ΔΕΞΙΑ ΤΟΥ. Για να μην βγούμε έξω από τα
            # όρια της wCSkakiera[(8),(8)] έχουμε προσθέσει τον έλεγχο (@@WhiteKingColumn + 1) <= 8 στο "if". Αρχικά ο "κίνδυνος"
            # από τα "δεξιά" είναι υπαρκτός, άρα @@DangerFromRight = true. Ωστόσο αν βρεθεί ότι στα δεξιά του λευκού βασι-
            # λιά υπάρχει κάποιο λευκό κομμάτι, τότε δεν είναι δυνατόν ο εν λόγω βασιλιάς να υφίσταται σαχ από τα δεξιά
            # του (αφού θα "προστατεύεται" από το κομμάτι ιδίου χρώματος), οπότε η @@DangerFromRight = false και ο έλεγχος
            # για απειλές από τα δεξιά σταματάει (για αυτό και έχω προσθέσει την προϋπόθεση (@@DangerFromRight == true) στα
            # "if" που κάνουν αυτόν τον έλεγχο).
            # Αν όμως δεν υπάρχει κανένα λευκό κομμάτι δεξιά του βασιλιά για να τον προστατεύει, τότε συνεχίζει να
            # υπάρχει πιθανότητα να απειλείται ο βασιλιάς από τα δεξιά του, οπότε ο έλεγχος συνεχίζεται.
            # Σημείωση: Ο έλεγχος γίνεται για πιθανό σαχ από πύργο ή βασίλισσα αντίθετου χρώματος.
            ########################################################

            @@DangerFromRight = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn + klopa) <= 8) && (@@DangerFromRight == true))
                    if ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromRight = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black King") == 0))
                        @@DangerFromRight = false;
                    end
                end
            end


            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΤΑ ΑΡΙΣΤΕΡΑ ΤΟΥ (από πύργο ή βασίλισσα).
            ###################################################/

            @@DangerFromLeft = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn - klopa) >= 1) && (@@DangerFromLeft == true))
                    if ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromLeft = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - 1)].CompareTo("Black King") == 0))
                        @@DangerFromLeft = false;
                    end
                end
            end


            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΠΑΝΩ (από πύργο ή βασίλισσα).
            ###################################################/


            @@DangerFromUp = true;

            for klopa in 1..7 do
                if (((@@WhiteKingRank + klopa) <= 8) && (@@DangerFromUp == true))
                    if ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromUp = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromUp = false;
                    end
                end
            end


            ###################################################/
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΚΑΤΩ (από πύργο ή βασίλισσα).
            ###################################################/

            @@DangerFromDown = true;

            for klopa in 1..7 do
                if (((@@WhiteKingRank - klopa) >= 1) && (@@DangerFromDown == true))
                    if ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromDown = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromDown = false;
                    end
                end
            end


            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΠΑΝΩ-ΔΕΞΙΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromUpRight = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn + klopa) <= 8) && ((@@WhiteKingRank + klopa) <= 8) && (@@DangerFromUpRight == true))
                    if ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromUpRight = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromUpRight = false;
                    end
                end
            end


            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΚΑΤΩ-ΑΡΙΣΤΕΡΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromDownLeft = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn - klopa) >= 1) && ((@@WhiteKingRank - klopa) >= 1) && (@@DangerFromDownLeft == true))
                    if ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromDownLeft = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromDownLeft = false;
                    end
                end
            end

            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΚΑΤΩ-ΔΕΞΙΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromDownRight = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn + klopa) <= 8) && ((@@WhiteKingRank - klopa) >= 1) && (@@DangerFromDownRight == true))
                    if ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromDownRight = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn + klopa - 1), (@@WhiteKingRank - klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromDownRight = false;
                    end
                end
            end


            ########################################################
            # Έλεγχος αν υπάρχει κίνδυνος για το λευκό βασιλιά ΑΠΟ ΠΑΝΩ-ΑΡΙΣΤΕΡΑ ΤΟΥ (από βασίλισσα ή αξιωματικό).
            ########################################################

            @@DangerFromUpLeft = true;

            for klopa in 1..7 do
                if (((@@WhiteKingColumn - klopa) >= 1) && ((@@WhiteKingRank + klopa) <= 8) && (@@DangerFromUpLeft == true))
                    if ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Queen") == 0))
                        kingCheck = true;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Bishop") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("White Queen") == 0))
                        @@DangerFromUpLeft = false;
                    elsif ((wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Pawn") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Rook") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black Knight") == 0) || (wCSkakiera[(@@WhiteKingColumn - klopa - 1), (@@WhiteKingRank + klopa - 1)].CompareTo("Black King") == 0))
                        @@DangerFromUpLeft = false;
                    end
                end
            end



            #####################################
            # Έλεγχος για το αν ο λευκός βασιλιάς απειλείται από πιόνι.
            #####################################

            if (((@@WhiteKingColumn + 1) <= 8) && ((@@WhiteKingRank + 1) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn + 1 - 1), (@@WhiteKingRank + 1 - 1)].CompareTo("Black Pawn") == 0)
                    kingCheck = true;
                end
            end


            if (((@@WhiteKingColumn - 1) >= 1) && ((@@WhiteKingRank + 1) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn - 1 - 1), (@@WhiteKingRank + 1 - 1)].CompareTo("Black Pawn") == 0)
                    kingCheck = true;
                end
            end


            ###################################/
            # Έλεγχος για το αν ο λευκός βασιλιάς απειλείται από ίππο.
            ###################################/

            if (((@@WhiteKingColumn + 1) <= 8) && ((@@WhiteKingRank + 2) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn + 1 - 1), (@@WhiteKingRank + 2 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn + 2) <= 8) && ((@@WhiteKingRank - 1) >= 1))
                if (wCSkakiera[(@@WhiteKingColumn + 2 - 1), (@@WhiteKingRank - 1 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn + 1) <= 8) && ((@@WhiteKingRank - 2) >= 1))
                if (wCSkakiera[(@@WhiteKingColumn + 1 - 1), (@@WhiteKingRank - 2 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn - 1) >= 1) && ((@@WhiteKingRank - 2) >= 1))
                if (wCSkakiera[(@@WhiteKingColumn - 1 - 1), (@@WhiteKingRank - 2 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn - 2) >= 1) && ((@@WhiteKingRank - 1) >= 1))
                if (wCSkakiera[(@@WhiteKingColumn - 2 - 1), (@@WhiteKingRank - 1 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn - 2) >= 1) && ((@@WhiteKingRank + 1) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn - 2 - 1), (@@WhiteKingRank + 1 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn - 1) >= 1) && ((@@WhiteKingRank + 2) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn - 1 - 1), (@@WhiteKingRank + 2 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            if (((@@WhiteKingColumn + 2) <= 8) && ((@@WhiteKingRank + 1) <= 8))
                if (wCSkakiera[(@@WhiteKingColumn + 2 - 1), (@@WhiteKingRank + 1 - 1)].CompareTo("Black Knight") == 0)
                    kingCheck = true;
                end
            end

            return kingCheck;
      end #end CheckForWhiteCheck

      def CheckForWhiteMate(wMSkakiera)

            ####################################################/
            # Μεταβλητή που χρησιμεύει στον έλεγχο για το αν υπάρχει ματ (βλ. συναρτήσεις CheckForWhiteMate() και
            # CheckForBlackMate()).
            # Αναλυτικότερα, το πρόγραμμα ελέγχει αν αρχικά υπάρχει σαχ και, αν υπάρχει, ελέγχει αν αυτό το
            # σαχ μπορεί να αποφευχθεί με τη μετακίνηση του υπό απειλή βασιλιά σε κάποιο γειτονικό τετράγωνο.
            # Η μεταβλητή καταγράφει το αν συνεχίζει να υπάρχει πιθανότητα να υπάρχει ματ στη σκακιέρα.
            ####################################################/


            ##############################
            # Έλεγχος του αν υπάρχει "ματ" στον λευκό βασιλιά
            ##############################

            mate = false;
            dangerForMate = true;    # Αρχικά, προφανώς υπάρχει πιθανότητα να υπάρχει ματ στη σκακιέρα.
            # Αν, ωστόσο, κάποια στιγμή βρεθεί ότι αν ο βασιλιάς μπορεί να μετακινηθεί
            # σε ένα διπλανό τετράγωνο και να πάψει να υφίσταται σαχ, τότε παύει να
            # υπάρχει πιθανότητα να υπάρχει ματ (προφανώς) και η μεταβλητή παίρνει την
            # τιμή false.


            ###############################
            # Εύρεση των αρχικών συντεταγμένων του βασιλιά
            ###############################

            for i in 0..7 do
                for j in 0..7 do
                    if (wMSkakiera[(i), (j)].CompareTo("White King") == 0)
                        @@StartingWhiteKingColumn = (i + 1);
                        @@StartingWhiteKingRank = (j + 1);
                    end

                end
            end


            #########################
            # Έλεγχος αν ο λευκός βασιλιάς είναι ματ
            #########################


            if (@@m_WhichColorPlays.CompareTo("White") == 0)
            
                ########################
                # Έλεγχος αν υπάρχει σαχ αυτή τη στιγμή
                ########################

                @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                if (@@WhiteKingCheck == false)     # Αν αυτή τη στιγμή δεν υφίσταται σαχ, τότε να μη συνεχιστεί ο έλεγχος
                    dangerForMate = false;         # καθώς ΔΕΝ συνεχίζει να υφίσταται πιθανότητα να υπάρχει ματ.
                end

                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω
                #######################################################/

                if (@@StartingWhiteKingRank < 8)
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 + 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 + 1) <= 7))

                        # (Προσωρινή) μετακίνηση του βασιλιά προς τα πάνω και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.
                        # Ο έλεγχος γίνεται μόνο αν στο τετράγωνο που μετακινείται προσωρινά ο βασιλιάς δεν υπάρχει άλλο κομμάτι
                        # του ίδιου χρώματος που να τον εμποδίζει και αν, φυσικά, ο βασιλιάς δεν βγαίνει έξω από τη σκακιέρα με
                        # αυτή του την κίνηση και αν, προφανώς, συνεχίζει να υπάρχει πιθανότητα να ύπάρχει ματ (καθώς αν δεν
                        # υπάρχει τέτοια πιθανότητα, τότε ο έλεγχος είναι άχρηστος).

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 + 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 + 1)] = @@ProsorinoKommati;

                    end

                end #end if @@StartingWhiteKingRank


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω-δεξιά
                #######################################################/

                if ((@@StartingWhiteKingColumn < 8) && (@@StartingWhiteKingRank < 8))
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 + 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 + 1) <= 7) && ((@@StartingWhiteKingColumn - 1 + 1) <= 7))
                        # (Προσωρινή) μετακίνηση του βασιλιά και έλεγχος του αν συνεχίζει τότε να υπάρχει σαχ.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 + 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 + 1)] = @@ProsorinoKommati;
                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα δεξιά
                #######################################################/

                if (@@StartingWhiteKingColumn < 8)
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingColumn - 1 + 1) <= 7))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1)] = @@ProsorinoKommati;

                    end

                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω-δεξιά
                #######################################################/

                if ((@@StartingWhiteKingColumn < 8) && (@@StartingWhiteKingRank > 1))
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 - 1) >= 0) && ((@@StartingWhiteKingColumn - 1 + 1) <= 7))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 - 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 + 1), (@@StartingWhiteKingRank - 1 - 1)] = @@ProsorinoKommati;

                    end

                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω
                #######################################################/

                if (@@StartingWhiteKingRank > 1)
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 - 1) >= 0))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 - 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1 - 1)] = @@ProsorinoKommati;

                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα κάτω-αριστερά
                #######################################################/

                if ((@@StartingWhiteKingColumn > 1) && (@@StartingWhiteKingRank > 1))
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 - 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 - 1) >= 0) && ((@@StartingWhiteKingColumn - 1 - 1) >= 0))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 - 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 - 1)] = @@ProsorinoKommati;

                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα αριστερά
                #######################################################/

                if (@@StartingWhiteKingColumn > 1)
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingColumn - 1 - 1) >= 0))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1)] = @@ProsorinoKommati;
                    end
                end


                #######################################################/
                # Έλεγχος του αν θα συνεχίσει να υπάρχει σαχ αν ο λευκός βασιλιάς προσπαθήσει να διαφύγει μετακινούμενος
                # προς τα πάνω-αριστερά
                #######################################################/

                if ((@@StartingWhiteKingColumn > 1) && (@@StartingWhiteKingRank < 8))
                    @@MovingPiece = wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)];
                    @@ProsorinoKommati = wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 + 1)];

                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 1) && (@@ProsorinoKommati.CompareTo("White Rook") == 1) && (@@ProsorinoKommati.CompareTo("White Knight") == 1) && (@@ProsorinoKommati.CompareTo("White Bishop") == 1) && (@@ProsorinoKommati.CompareTo("White Pawn") == 1) && (dangerForMate == true) && ((@@StartingWhiteKingRank - 1 + 1) <= 7) && ((@@StartingWhiteKingColumn - 1 - 1) >= 0))
                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = "";
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 + 1)] = @@MovingPiece;
                        @@WhiteKingCheck = CheckForWhiteCheck(wMSkakiera);

                        if (@@WhiteKingCheck == false)
                            dangerForMate = false;
                        end

                        # Επαναφορά της σκακιέρας στην κατάσταση στην οποία βρισκόταν πριν μετακινηθεί ο βασιλιάς για τους
                        # σκοπούς του ελέγχου.

                        wMSkakiera[(@@StartingWhiteKingColumn - 1), (@@StartingWhiteKingRank - 1)] = @@MovingPiece;
                        wMSkakiera[(@@StartingWhiteKingColumn - 1 - 1), (@@StartingWhiteKingRank - 1 + 1)] = @@ProsorinoKommati;

                    end

                end

                if (dangerForMate == true)
                    mate = true;
                end

            end #end if @@m_WhichColorPlays.CompareTo("White")

            return mate;
        end #end CheckForWhiteMate

      def CheckMove(cMSkakiera)
            @@number_of_moves_analysed += 1;

            # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
            #if(huo_debug == true)
            #{
            #	Console.WriteLine("CheckMove called");
            #	Console.ReadKey();
            #}
            # Assign values to @@m_WhoPlays and @@m_WrongColumn variables,
            # which are necessary for the proper function of ElegxosNomimotitas and ElegxosOrthotitas
            @@m_WhoPlays = "Human";
            @@m_WrongColumn = false;
            @@MovingPiece = cMSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)];

            # Check correctness of move
            @@m_OrthotitaKinisis = ElegxosOrthotitas(cMSkakiera);
            # if move is correct, then check the legality also
            if (@@m_OrthotitaKinisis == true)
                @@m_NomimotitaKinisis = ElegxosNomimotitas(cMSkakiera);
            end

            # restore the normal value of the @@m_WhoPlays
            @@m_WhoPlays = "HY";

            #####################################################/
            # CHECK FOR MATE
            #####################################################/

            if (((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true)) && (@@Move_Analyzed == 0))

                ######################################################
                # temporarily move the piece to see if the king will continue to be under check
                ####################################################/

                cMSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                @@ProsorinoKommati = cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];   # Προσωρινή αποθήκευση του
                # κομματιού που βρίσκεται στο
                # τετράγωνο προορισμού
                # (βλ. μετά για τη χρησιμότητα
                # του, εκεί που γίνεται έλεγ-
                # χος για το αν συνεχίζει να
                # υφίσταται σαχ).

                cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@MovingPiece;


                #####################################
                # is the king still under check?
                #####################################

                @@WhiteKingCheck = CheckForWhiteCheck(cMSkakiera);

                if ((@@m_WhichColorPlays.CompareTo("White") == 0) && (@@WhiteKingCheck == true))
                    @@m_NomimotitaKinisis = false;
                end


                #####################################/
                # is the black king under check?
                #####################################/

                @@BlackKingCheck = CheckForBlackCheck(cMSkakiera);

                if ((@@m_WhichColorPlays.CompareTo("Black") == 0) && (@@BlackKingCheck == true))
                    @@m_NomimotitaKinisis = false;
              end


                # restore pieces to their initial positions
                cMSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = @@MovingPiece;
                cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@ProsorinoKommati;

            end

            ######################################################
            # end of checking in the king is still under check!
            ######################################################

            # restore the normal value of @@m_WhoPlays
            @@m_WhoPlays = "HY";


            # check if HY moves the king next to the king of the opponent
            # (this case is not controlled in the lines above)
            if (@@MovingPiece.CompareTo("White King") == 0)
                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1 + 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1) >= 0) && ((@@m_FinishingColumnNumber - 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 + 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1 + 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1) >= 0) && ((@@m_FinishingRank - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1 - 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1) >= 0) && ((@@m_FinishingColumnNumber - 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1 - 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1) >= 0) && ((@@m_FinishingRank - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1)].CompareTo("Black King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
              end
            end #end @@MovingPiece.CompareTo("White King")


            if (@@MovingPiece.CompareTo("Black King") == 0)
                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1 + 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1) >= 0) && ((@@m_FinishingColumnNumber - 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 + 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1 + 1) >= 0) && ((@@m_FinishingRank - 1 + 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1 + 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1) >= 0) && ((@@m_FinishingRank - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 - 1) >= 0) && ((@@m_FinishingColumnNumber - 1 - 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 - 1), (@@m_FinishingRank - 1 - 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1) >= 0) && ((@@m_FinishingColumnNumber - 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1 - 1) >= 0) && ((@@m_FinishingRank - 1 - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1 - 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
                end

                if (((@@m_FinishingColumnNumber - 1 + 1) >= 0) && ((@@m_FinishingColumnNumber - 1 + 1) <= 7) && ((@@m_FinishingRank - 1) >= 0) && ((@@m_FinishingRank - 1) <= 7))
                    if (cMSkakiera[(@@m_FinishingColumnNumber - 1 + 1), (@@m_FinishingRank - 1)].CompareTo("White King") == 0)
                        @@m_NomimotitaKinisis = false;
                    end
              end
            end #end @@MovingPiece.CompareTo("Black King") == 0


            # if the move under analysis is correct and legal, then do it and measure its score

            if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))
                # temporarily perform the move
                @@ProsorinoKommati = cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];
                cMSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@MovingPiece;


                # check is there is a pawn promotion
                if (@@m_FinishingRank == 8)
                    cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "White Queen";
                    @@Promotion_Occured = true;
                elsif (@@m_FinishingRank == 1)
                    cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "Black Queen";
                    @@Promotion_Occured = true;
                end


                # store the move to ***_HY variables (because after continuous calls of ComputerMove the initial move under analysis will be lost...)
                if ((@@Move_Analyzed == 0) && (((@@m_PlayerColor.CompareTo("White") == 0) && ((@@MovingPiece.CompareTo("Black Pawn") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0) || (@@MovingPiece.CompareTo("Black King") == 0))) || ((@@m_PlayerColor.CompareTo("Black") == 0) && ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("White King") == 0)))))
                    # CHECK IF THE COMPUTER MOVES THE PIECE TO A SQUARE THAT IS THREATENED BY A PAWN
                    @@rook_pawn_threat = false;
                    @@queen_pawn_threat = false;
                    @@knight_pawn_threat = false;
                    @@bishop_pawn_threat = false;
                    @@checked_for_pawn_threats = false;
                    CountScore(cMSkakiera);

                    # check is HY eats the opponents queen
                    # (so it is preferable to do so...)
                    # Changed in version 0.5
                    if ((@@ProsorinoKommati.CompareTo("White Queen") == 0) || (@@ProsorinoKommati.CompareTo("Black Queen") == 0))
                        @@eat_queen = true;
                    else
                        @@eat_queen = false;
                    end

                    @@MovingPiece_HY = @@MovingPiece;
                    @@m_StartingColumnNumber_HY = @@m_StartingColumnNumber;
                    @@m_FinishingColumnNumber_HY = @@m_FinishingColumnNumber;
                    @@m_StartingRank_HY = @@m_StartingRank;
                    @@m_FinishingRank_HY = @@m_FinishingRank;
                end

                # if the HY moves its king in the initial moves, then there is a penalty
                if ((@@MovingPiece_HY.CompareTo("White King") == 0) || (@@MovingPiece_HY.CompareTo("Black King") == 0))
                    @@moving_the_king = true;
                else
                    @@moving_the_king = false;
                end

                if ((@@First_Call == true) && (@@Move_Analyzed == @@Thinking_Depth))
                    @@Best_Move_StartingColumnNumber = @@m_StartingColumnNumber_HY;
                    @@Best_Move_FinishingColumnNumber = @@m_FinishingColumnNumber_HY;
                    @@Best_Move_StartingRank = @@m_StartingRank_HY;
                    @@Best_Move_FinishingRank = @@m_FinishingRank_HY;

                    # Measure the move score
                    CountScore(cMSkakiera);
                    @@Best_Move_Score = @@Current_Move_Score;

                    @@First_Call = false;
                    @@Best_Move_Found = true;
                end

                if (@@Move_Analyzed == @@Thinking_Depth)
                    # Measure the move score
                    CountScore(cMSkakiera);

                    # HUO DEBUG
                    # If the computer loses its queen...then penalty!
                    #if(LoseQueen_penalty == true)
                    #{
                    #Console.WriteLine("Danger penalty noted!");
                    #	if(@@m_PlayerColor.CompareTo("White") == 0)
                    #		@@Current_Move_Score = @@Current_Move_Score + 50;
                    #	elsif(@@m_PlayerColor.CompareTo("Black") == 0)
                    #		@@Current_Move_Score = @@Current_Move_Score - 50;
                    #}

                    # record the score as the best move score, if it is the best
                    # move score!
                    # HUO DEBUG
                    #if(LoseQueen_penalty == false)
                    #{
                    #Console.WriteLine("Checked move...");
                    if (((@@m_PlayerColor.CompareTo("Black") == 0) && (@@Current_Move_Score > @@Best_Move_Score)) || ((@@m_PlayerColor.CompareTo("White") == 0) && (@@Current_Move_Score < @@Best_Move_Score)))
                        # HUO DEBUG
                        #StreamWriter swer = new StreamWriter("BestMoves.txt",true);
                        #swer.WriteLine(String.Concat((@@m_StartingColumnNumber_HY).ToString(),(@@m_StartingRank_HY).ToString(),(@@m_FinishingColumnNumber_HY).ToString(),(@@m_FinishingRank_HY).ToString(),"  : Best @@Move Found!"));
                        #swer.Close();

                        @@Best_Move_StartingColumnNumber = @@m_StartingColumnNumber_HY;
                        @@Best_Move_FinishingColumnNumber = @@m_FinishingColumnNumber_HY;
                        @@Best_Move_StartingRank = @@m_StartingRank_HY;
                        @@Best_Move_FinishingRank = @@m_FinishingRank_HY;
                        @@Best_Move_Score = @@Current_Move_Score;
                    elsif ((@@Current_Move_Score == @@Best_Move_Score) && (((@@m_PlayerColor.CompareTo("White") == 0) && ((@@MovingPiece.CompareTo("Black Pawn") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0) || (@@MovingPiece.CompareTo("Black King") == 0))) || ((@@m_PlayerColor.CompareTo("Black") == 0) && ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("White King") == 0)))))
                        # if score of move analyzed is equal to so-far best move score, then
                        # let chance ('Τυχη' in Greek) decide to which move will be kept as best move
                        # (target: maximize variety of computer game)
                        # REMOVE THIS PART TO MAXIMIZE THE STABILITY OF COMPUTER GAME PLAY
                        # Αν το σκορ της κίνησης που αναλύεται είναι ΙΣΟ με το σκορ της έως τώρα καλύτερης κίνησης, τότε
                        # αφήνουμε να αποφασίσει η τύχη για το αν η κίνηση αυτή θα αντικαταστήσει την έως τώρα καλύτερη.
                        # Στόχος: Η εισαγωγή της ποικιλίας στο παιχνίδι του υπολογιστή.

                        #Random random_number = new Random();
                        #int Arithmos = random_number.Next(1, 20);
                        arithmos = rand(20) + 1

                        if (arithmos > 13)
                            @@Best_Move_StartingColumnNumber = @@m_StartingColumnNumber_HY;
                            @@Best_Move_FinishingColumnNumber = @@m_FinishingColumnNumber_HY;
                            @@Best_Move_StartingRank = @@m_StartingRank_HY;
                            @@Best_Move_FinishingRank = @@m_FinishingRank_HY;
                            @@Best_Move_Score = @@Current_Move_Score;
                        end
                    end
                    #}

                    ####################################
                    # restore the pieces to their initial positions
                    ####################################
                    for i in 0..7 do
                        for j in 0..7 do
                            @@Skakiera[(i), (j)] = @@Skakiera_Move_0[(i), (j)];
                        end
                    end

                    # restore promoted pawn (if exists)
                    if ((@@m_FinishingRank == 8) && (@@Promotion_Occured == true))
                        cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "White Pawn";
                        @@Promotion_Occured = false;
                    elsif ((@@m_FinishingColumnNumber == 1) && (@@Promotion_Occured == true))
                        cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "Black Pawn";
                        @@Promotion_Occured = false;
                    end

                    # restore pieces
                    cMSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = @@MovingPiece;
                    cMSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@ProsorinoKommati;
              end #end if (@@Move_Analyzed == @@Thinking_Depth)

                ###########################################/
                # NOW CHECK FOR POSSIBLE ANSWERS BY THE OPPONENT
                ###########################################/

                if (@@Move_Analyzed < @@Thinking_Depth)
                    ###############################
                    # is human's king in check?
                    ###############################
                    @@Human_is_in_check = false;

                    @@WhiteKingCheck = CheckForWhiteCheck(cMSkakiera);
                    if ((@@m_PlayerColor.CompareTo("White") == 0) && (@@WhiteKingCheck == true))
                        @@Human_is_in_check = true;
                    end

                    @@BlackKingCheck = CheckForBlackCheck(cMSkakiera);
                    if ((@@m_PlayerColor.CompareTo("Black") == 0) && (@@BlackKingCheck == true))
                        @@Human_is_in_check = true;
                    end

                    @@Move_Analyzed = @@Move_Analyzed + 1;

                    for i in 0..7 do
                        for j in 0..7 do
                            @@Skakiera_Move_After[(i), (j)] = cMSkakiera[(i), (j)];
                        end
                    end

                    @@Who_Is_Analyzed = "Human";
                    @@First_Call_Human_Thought = true;

                    # check human move (to find the best possible answer of the human
                    # to the move currently analyzed by the HY Thought process)
                    HumanMove(@@Skakiera_Move_After);
                    # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
                    #if(huo_debug == true)
                    #{
                    #	Console.WriteLine("RETURNED TO CheckMove");
                    #	Console.ReadKey();
                    #}
                end #end if (@@Move_Analyzed < @@Thinking_Depth)

            end #end if ((@@m_OrthotitaKinisis == true)
        end #end CheckMove

      def ComputerMove(skakiera_Thinking_init)
            # UNCOMMENT TO SHOW THINKING TIME!
            #start = Environment.TickCount;

            # Uncomment to have the program record the start and stop time to a log .txt file
            #StreamWriter huo_sw = new StreamWriter("game.txt", true);
            #Console.WriteLine(string.Concat("Started thinking at: ", DateTime.Now.ToString("hh:mm:ss.fffffff")));
            #huo_sw.WriteLine(string.Concat("Strarted thinking at: ", DateTime.Now.ToString("hh:mm:ss.fffffff")));
            #huo_sw.Close();

            # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
            #if(huo_debug == true)
            #{
            #	Console.WriteLine("ComputerMove called");
            #	Console.ReadKey();
            #}
            # set mate=false, to avoid false alarms for mate.
            # if the program finds out in a next step that mate exists,
            # then it will tell it to you, don't worry! :)
            @@mate = false;


            if (@@First_Call == true)
                # store the initial position in the chessboard
                for iii in 0..7 do
                    for jjj in 0..7 do
                        @@Skakiera_Thinking[iii, jjj] = skakiera_Thinking_init[(iii), (jjj)];
                        @@Skakiera_Move_0[(iii), (jjj)] = skakiera_Thinking_init[(iii), (jjj)];
                    end
                end
            end


            # check is computer has thought as far as the ThinkingDepth dictates
            if (@@Move_Analyzed > @@Thinking_Depth)
                @@Stop_Analyzing = true;
            end

            ####################################
            # CHECK IF POSITION IS IN THE OPENING BOOK
            ####################################


            opening = 1;

            exit_opening_loop = false;
            # Μεταβλητή που καταδεικνύει το αν υπάρχει ταίριασμα της παρούσας θέσης με κάποια από τις θέσεις που υπάρχουν αποθηκευμένες στο βιβλίο ανοιγμάτων του ΗΥ
            match_found = false;

            line_in_opening_book = "";

            while (exit_opening_loop == false)
                #if (File.Exists(String.Concat("Huo Chess Opening Book\\", opening.ToString(), ".txt")))
                fname_dir = File.join(File.dirname(__FILE__), "Huo Chess Opening Book")
                fname = File.join(fname_dir, "#{opening}.txt")
                if (File.exist?(fname))
                    # Άνοιγμα των αρχείων .txt που περιέχει η βάση δεδομένων του ΗΥ
                    #StreamReader sr = new StreamReader(String.Concat("Huo Chess Opening Book\\", opening.ToString(), ".txt"));
                    sr = File.open(fname, 'r')
                    match_found = true;

                    for op_iii in 0..7 do
                        for op_jjj in 0..7 do
                            #line_in_opening_book = sr.ReadLine();
                            line_in_opening_book = sr.readline.chomp
                            if (@@Skakiera_Thinking[op_iii, op_jjj].CompareTo(line_in_opening_book) != 0)
                                match_found = false;
                            end
                        end
                    end

                    # Αν βρέθηκε μια θέση που είναι αποθηκευμένη στο βιβλίο ανοιγμάτων,
                    # τότε διάβασε και τις επόμενες σειρές στο αρχείο text οι οποίες περιέχουν
                    # την κίνηση που πρέπει να κάνει ο ΗΥ στην παρούσα θέση.

                    if (match_found == true)
                        # Αφού βρέθηκε θέση, τότε δεν χρειάζεται περαιτέρω ανάλυση.
                        exit_opening_loop = true;

                        # Αφού βρέθηκε θέση, τότε ο ΗΥ δεν χρειάζεται να σκεφτεί για την κίνηση του, την έχει βρει έτοιμη!
                        @@Stop_Analyzing = true;

                        # Διάβασμα της κενής γραμμής που υπάρχει στο αρχείο.
                        line_in_opening_book = sr.readline.chomp

                        line_in_opening_book = sr.readline.chomp
                        @@Best_Move_StartingColumnNumber = line_in_opening_book.to_i;
                        line_in_opening_book = sr.readline.chomp
                        @@Best_Move_StartingRank = line_in_opening_book.to_i

                        line_in_opening_book = sr.readline.chomp
                        @@Best_Move_FinishingColumnNumber = line_in_opening_book.to_i
                        line_in_opening_book = sr.readline.chomp
                        @@Best_Move_FinishingRank = line_in_opening_book.to_i
                    end
                else
                    exit_opening_loop = true;
                end #end if file.exist?

                opening = opening + 1;
            end#end while

            ###################
            # END OF OPENING BOOK CHECK
            ###################

            if (@@Stop_Analyzing == false)
                skakiera_Dangerous_Squares = HuoMatrix.new(8,8)
                number_of_defenders = HuoMatrix.new(8,8)
                number_of_attackers = HuoMatrix.new(8,8);
                value_of_defenders = HuoMatrix.new(8,8)
                value_of_attackers = HuoMatrix.new(8,8)
                exception_defender_column = HuoMatrix.new(8,8)
                exception_defender_rank = HuoMatrix.new(8,8)
                
                # Scan the chessboard . if a piece of HY is found . check all
                # possible destinations in the chessboard . check correctness of
                # the move analyzed . check legality of the move analyzed . if
                # correct and legal, then do the move.
                # NOTE: In all column and rank numbers I add +1, because I must transform
                # them from the 0...7 'measure system' of the chessboard (='@@Skakiera' in Greek) table
                # to the 1...8 'measure system' of the chessboard.
                
                # find the dangerous squares in the chessboard, where if the HY
                # moves its piece, will immediately loose it.
                for i in 0..7 do
                    for j in 0..7 do
                        skakiera_Dangerous_Squares[i, j] = "";
                    end
                end
                    
                    # Changed in version 0.5
                    # Initialize variables for finfind the dangerous squares
                    for di in 0..7 do
                        for dj in 0..7 do
                            number_of_attackers[di, dj] = 0;
                            number_of_defenders[di, dj] = 0;
                            value_of_attackers[di, dj] = 0;
                            value_of_defenders[di, dj] = 0;
                            exception_defender_column[di, dj] = -9;
                            exception_defender_rank[di, dj] = -9;
                        end
              end
              
              for iii2 in 0..7 do
                  for jjj2 in 0..7 do
                      if ((((((@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White King") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White Queen") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White Rook") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White Knight") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White Bishop") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)) || (((@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black King") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black Queen") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black Rook") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black Knight") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black Bishop") == 0) || (@@Skakiera_Thinking[(iii2), (jjj2)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)))))
                          # find squares where the human opponent can hit
                          for w2 in 0..7 do
                              for r2 in 0..7 do
                                  @@MovingPiece = @@Skakiera_Thinking[(iii2), (jjj2)];
                                  @@m_StartingColumnNumber = iii2 + 1;
                                  @@m_FinishingColumnNumber = w2 + 1;
                                  @@m_StartingRank = jjj2 + 1;
                                  @@m_FinishingRank = r2 + 1;
                                  
                                  # check the move
                                  @@m_WhoPlays = "Human";
                                  @@m_WrongColumn = false;
                                  @@m_OrthotitaKinisis = ElegxosOrthotitas(@@Skakiera_Thinking);
                                  if (@@m_OrthotitaKinisis == true)
                                    @@m_NomimotitaKinisis = ElegxosNomimotitas(@@Skakiera_Thinking);
                                  end
                                  # restore normal value of m_whoplays
                                  @@m_WhoPlays = "HY";
                                  if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))
                                      # Another attacker on that square found!
                                      number_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = number_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 1;
                                      skakiera_Dangerous_Squares[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "Danger";
                                      
                                      # PLAYING
                                      #if (((@@m_FinishingColumnNumber - 1) == 2) && ((@@m_FinishingRank - 1) == 4))
                                      #    Console.WriteLine("ha");
                                      # PLAYING
                                      
                                      #if(skakiera_Dangerous_Squares[(@@m_FinishingColumnNumber-1),(@@m_FinishingRank-1)].ToString().Equals("Danger") == true)
                                      #	Console.WriteLine("Added new dangerous square!");
                                      
                                      # Calculate the value (total value) of the attackers
                                      if ((@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0))
                                        value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 5;
                                      elsif ((@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0))
                                        value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 3;
                                      elsif ((@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0))
                                        value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 3;
                                      elsif ((@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0))
                                        value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 9;
                                      elsif ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0))
                                        value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 1;
                                      end
                                    end
                                  end#end for r2
                                end#end for w2
                              end#end if ((((((@@Skakiera_Thinking
                            end#end for jjj2
                   end #end for iii2
                   
                   ###########################################/
                   # ΑΠΟΘΗΚΕΥΣΗ ΤΩΝ ΕΠΙΚΙΝΔΥΝΩΝ ΤΕΤΡΑΓΩΝΩΝ
                   # USE FOR DEBUGGING PURPOSES ONLY!
                   #StreamWriter srw = new StreamWriter(String.Concat("log1.txt"));
                   #srw.WriteLine(String.Concat("@@Move: ",@@Move.ToString()));
                   #srw.WriteLine("*************************************");
                   #for iii in 0..7 do
                   #{
                   #	for jjj in 0..7 do
                   #	{
                   #		if(skakiera_Dangerous_Squares[(iii),(jjj)].ToString().Equals("Danger") == true)
                   #			srw.WriteLine(String.Concat(iii.ToString(),jjj.ToString()," DANGER!"));
                   #		elsif(skakiera_Dangerous_Squares[(iii),(jjj)].ToString().Equals("") == true)
                   #			srw.WriteLine(String.Concat(iii.ToString(),jjj.ToString()," No danger...Χαλαρά!"));
                   #		else
                   #			srw.WriteLine(String.Concat(iii.ToString(),jjj.ToString()));
                   #	}
                   #}
                   #srw.WriteLine("**********************************");
                   #srw.Close();
                   ############################################/
                   
                   
                   # Find squares that are also 'protected' by a piece of the HY.
                   # If protected, then the square is not really dangerous
                   
                   # Changed in version 0.5
                   # Initialize all variables used to find exceptions in the non-dangerous squares.
                   # Exceptions definition: If human can hit a square and the computer defends it with its pieces, then the
                   # square is not dangerous. However, if the computer has only one (1) piece to defend that square, then
                   # it cannot move that specific piece to that square (because then the square would have no defenders and
                   # would become again a dangerous square!).
                   
                   for iii3 in 0..7 do
                       for jjj3 in 0..7 do
                           if (((@@Who_Is_Analyzed.CompareTo("HY") == 0) && ((((@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White King") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White Queen") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White Rook") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White Knight") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White Bishop") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)) || (((@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black King") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black Queen") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black Rook") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black Knight") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black Bishop") == 0) || (@@Skakiera_Thinking[(iii3), (jjj3)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)))))
                               for w1 in 0..7 do
                                   for r1 in 0..7 do
                                       @@MovingPiece = @@Skakiera_Thinking[(iii3), (jjj3)];
                                       @@m_StartingColumnNumber = iii3 + 1;
                                       @@m_FinishingColumnNumber = w1 + 1;
                                       @@m_StartingRank = jjj3 + 1;
                                       @@m_FinishingRank = r1 + 1;
                                       
                                       # Έλεγχος της κίνησης
                                       # Απόδοση τιμών στις μεταβλητές @@m_WhoPlays και @@m_WrongColumn, οι οποίες είναι απαραίτητες για να λειτουργήσει σωστά οι συναρτήσεις ElegxosNomimotitas και ElegxosOrthotitas
                                       @@m_WhoPlays = "Human";
                                       @@m_WrongColumn = false;
                                       @@m_OrthotitaKinisis = ElegxosOrthotitas(@@Skakiera_Thinking);
                                       if (@@m_OrthotitaKinisis == true)
                                         @@m_NomimotitaKinisis = ElegxosNomimotitas(@@Skakiera_Thinking);
                                       end
                                         # Επαναφορά της κανονικής τιμής της @@m_WhoPlays
                                         
                                         # NEW
                                         # You can count for all moves that "defend" a square,
                                         # except the move of a pawn forward! :)
                                         if ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0))
                                             if (@@m_FinishingColumnNumber == @@m_StartingColumnNumber)
                                               @@m_OrthotitaKinisis = false;
                                             end
                                         end
                                             # NEW
                                             
                                             @@m_WhoPlays = "HY";
                                             if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))
                                                 # Changed in version 0.5
                                                 # A new defender for that square is found!
                                                 number_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = number_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 1;
                                                 
                                                 # Calculate the value (total value) of the defenders
                                                 if ((@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0))
                                                   value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 5;
                                                 elsif ((@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0))
                                                   value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 3;
                                                 elsif ((@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0))
                                                   value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 3;
                                                 elsif ((@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0))
                                                   value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 9;
                                                 elsif ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0))
                                                   value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] + 1;
                                                 end
                                                 
                                                 # Record the coordinates of the defender.
                                                 # If the defender found is the only one, then that defender cannot move to that square,
                                                 # since then the square would be again dangerous (since its only defender would have moved into it!)
                                                 # If more than one defenders is found, then no exceptions exist.
                                                 if (number_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] == 1)
                                                     exception_defender_column[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = (@@m_StartingColumnNumber - 1);
                                                     exception_defender_rank[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = (@@m_StartingRank - 1);
                                                     
                                                     # PLAYING
                                                     #if (((@@m_FinishingColumnNumber - 1) == 2) && ((@@m_FinishingRank - 1) == 4))
                                                     #{
                                                     #    Console.WriteLine("hOU");
                                                     #    Console.WriteLine(String.Concat("@@Move found: ", @@m_StartingColumnNumber.ToString(), @@m_StartingRank.ToString(), "->", @@m_FinishingColumnNumber.ToString(), @@m_FinishingRank.ToString()));
                                                     #    Console.WriteLine(String.Concat("Exception column: ",exception_defender_column[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)]));
                                                     #    Console.WriteLine(String.Concat("Exception rank: ",exception_defender_rank[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)]));
                                                     #    Console.WriteLine(String.Concat("Exception column: ",(iii3).ToString()));
                                                     #    Console.WriteLine(String.Concat("Exception rank: ",(jjj3).ToString() ));
                                                     #}
                                                     # PLAYING
                                                   end
                                                   # PLAYING: Change 1 to 2 ???
                                                   if (number_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] > 1)
                                                       exception_defender_column[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = -99;
                                                       exception_defender_rank[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = -99;
                                                   end
                                                     
                                                     #if (skakiera_Dangerous_Squares[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Danger") == 0)
                                                     #{
                                                     #    skakiera_Dangerous_Squares[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "";
                                                     #}
                                             end#end if ((@@m_OrthotitaKinisis == true)
                                   end#end for r1
                               end#end for w1
                           end#end if (((@@Who_Is_Analyzed
                       end#end jjj3
                   end#end iii3
                                                          ###############################/
                                                          #***********************************************************#
                                                          ###############################/
                                                          
                                                          ############################################
                                                          # ΑΠΟΘΗΚΕΥΣΗ ΤΩΝ ΕΠΙΚΙΝΔΥΝΩΝ ΤΕΤΡΑΓΩΝΩΝ
                                                          # USE FOR DEBUGGING PURPOSES ONLY!
                                                          #StreamWriter srw2 = new StreamWriter(String.Concat("log2.txt"));
                                                          #srw2.WriteLine("AFTER CHECKING THE COMPUTER DEFENDERS");
                                                          #srw2.WriteLine(String.Concat("@@Move: ",@@Move.ToString()));
                                                          #srw2.WriteLine("*************************************");
                                                          #for iii in 0..7 do
                                                          #{
                                                          #	for jjj in 0..7 do
                                                          #	{
                                                          #		if(skakiera_Dangerous_Squares[(iii),(jjj)].ToString().Equals("Danger") == true)
                                                          #			srw2.WriteLine(String.Concat(iii.ToString(),jjj.ToString()," DANGER!"));
                                                          #		else
                                                          #			srw2.WriteLine(String.Concat(iii.ToString(),jjj.ToString()));
                                                          #	}
                                                          #}
                                                          #srw2.WriteLine("**********************************");
                                                          #srw2.Close();
                                                          ############################################
                                                          # v0.8 change
                                                          
                                                          ##############/
                                                          # 2009 v4 change
                                                          ##############/
                                                          value_of_piece_in_square = 0;
                                                          piece_in_danger_rank = 0;
                                                          piece_in_danger_column = 0;
                                                          danger_for_piece = false;
                                                          
                                                          for y in 0..7 do
                                                              for u in 0..7 do
                                                                  # Find value of piece in @@Skakiera(y,u)
                                                                  value_of_piece_in_square = 0;
                                                                  if ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Rook") == 0) || (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Rook") == 0))
                                                                    value_of_piece_in_square = 5;
                                                                  elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Bishop") == 0) || (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Bishop") == 0))
                                                                    value_of_piece_in_square = 3;
                                                                  elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Knight") == 0) || (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Knight") == 0))
                                                                    value_of_piece_in_square = 3;
                                                                  elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Queen") == 0) || (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Queen") == 0))
                                                                    value_of_piece_in_square = 9;
                                                                  elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Pawn") == 0) || (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Pawn") == 0))
                                                                    value_of_piece_in_square = 1;
                                                                  end
                                                                  
                                                                  #if((value_of_defenders[(y), (u)] + value_of_piece_in_square) > value_of_attackers[(y), (u)])
                                                                  #{
                                                                  #    skakiera_Dangerous_Squares[(y), (u)] = "Danger";
                                                                  #}
                                                                  
                                                                  if ((number_of_defenders[(y), (u)] <= number_of_attackers[(y), (u)]) && ((value_of_defenders[(y), (u)]) > value_of_attackers[(y), (u)]))
                                                                      skakiera_Dangerous_Squares[(y), (u)] = "Danger";
                                                                  else
                                                                      skakiera_Dangerous_Squares[(y), (u)] = "";
                                                                  end
                                                                    
                                                                    if ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Queen") == 0) && (@@m_PlayerColor.CompareTo("Black") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Queen") == 0) && (@@m_PlayerColor.CompareTo("White") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Rook") == 0) && (@@m_PlayerColor.CompareTo("Black") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Rook") == 0) && (@@m_PlayerColor.CompareTo("White") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Knight") == 0) && (@@m_PlayerColor.CompareTo("Black") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Knight") == 0) && (@@m_PlayerColor.CompareTo("White") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("White Bishop") == 0) && (@@m_PlayerColor.CompareTo("Black") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    elsif ((skakiera_Dangerous_Squares[(y), (u)].CompareTo("Danger") == 0) && (skakiera_Dangerous_Squares[(y), (u)].CompareTo("Black Bishop") == 0) && (@@m_PlayerColor.CompareTo("White") == 0))
                                                                        danger_for_piece = true;
                                                                        piece_in_danger_rank = u;
                                                                        piece_in_danger_column = y;
                                                                    end
                                                                      
                                                              end#end for u
                                                          end#end for y
                                                                  ##############/
                                                                  # 2009 v4 change
                                                                  ##############/
                                                                  
                    for iii in 0..7 do
                        for jjj in 0..7 do
                            
                            if (((@@Who_Is_Analyzed.CompareTo("HY") == 0) && ((((@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White King") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Queen") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Rook") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Knight") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Bishop") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)) || (((@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black King") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Queen") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Rook") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Knight") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Bishop") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)))) || ((@@Who_Is_Analyzed.CompareTo("Human") == 0) && ((((@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White King") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Queen") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Rook") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Knight") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Bishop") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)) || (((@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black King") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Queen") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Rook") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Knight") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Bishop") == 0) || (@@Skakiera_Thinking[(iii), (jjj)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)))))
                                
                                for w in 0..7 do
                                    for r in 0..7 do
                                        # Changed in version 0.5
                                        @@Danger_penalty = false;
                                        @@Attackers_penalty = false;
                                        @@Defenders_value_penalty = false;
                                        
                                        @@MovingPiece = @@Skakiera_Thinking[(iii), (jjj)];
                                        @@m_StartingColumnNumber = iii + 1;
                                        @@m_FinishingColumnNumber = w + 1;
                                        @@m_StartingRank = jjj + 1;
                                        @@m_FinishingRank = r + 1;
                                        
                                        @@Moving_Piece_Value = 0;
                                        @@Destination_Piece_Value = 0;
                                        
                                        # Calculate the value (total value) of the moving piece
                                        if ((@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0))
                                          @@Moving_Piece_Value = 5;
                                        elsif ((@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0))
                                          @@Moving_Piece_Value = 3;
                                        elsif ((@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0))
                                          @@Moving_Piece_Value = 3;
                                        elsif ((@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0))
                                          @@Moving_Piece_Value = 9;
                                        elsif ((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0))
                                          @@Moving_Piece_Value = 1;
                                        end
                                        
                                        # Find the value of the piece in the destination square
                                        if ((@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Rook") == 0) || (@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Rook") == 0))
                                          @@Destination_Piece_Value = 5;
                                        elsif ((@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Bishop") == 0) || (@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Bishop") == 0))
                                          @@Destination_Piece_Value = 3;
                                        elsif ((@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Knight") == 0) || (@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Knight") == 0))
                                          @@Destination_Piece_Value = 3;
                                        elsif ((@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Queen") == 0) || (@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Queen") == 0))
                                          @@Destination_Piece_Value = 9;
                                        elsif ((@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Pawn") == 0) || (@@Skakiera_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Pawn") == 0))
                                          @@Destination_Piece_Value = 1;
                                        end
                                        
                                        
                                        ##############/
                                        # 2009 v4 change
                                        ##############/
                                        @@danger_penalty = false;
                                        
                                        # check move, ONLY if the destination square is not
                                        # one of the dangerous squares found above.
                                        # OPTIMIZE BY CHANGING CODE HERE (danger_penalty = false OR true;)
                                        if ((skakiera_Dangerous_Squares[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Danger") == 0))
                                          @@danger_penalty = true;
                                        end
                                        
                                        if ((exception_defender_column[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] == (@@m_StartingColumnNumber - 1)) && (exception_defender_rank[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] == (@@m_StartingRank - 1)))
                                          @@danger_penalty = true;
                                        end
                                        
                                        if (danger_for_piece == true)
                                            #if ((skakiera_Dangerous_Squares[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Danger") == 0))
                                            if (((@@m_StartingColumnNumber - 1) != piece_in_danger_column) || ((@@m_StartingRank - 1) != piece_in_danger_rank))
                                              
                                                @@danger_penalty = true;
                                            end
                                        end
                                            
                                            # Penalty for moving your piece to a square that the human opponent can hit with more power than the computer.
                                            #    if (number_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] > number_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)])
                                            #    { @@Attackers_penalty = true; }
                                            
                                            # Penalty if the pieces of the human defending a square in which the computer movies in, have much less
                                            # value than the pieces the computer has to support the attack on that square
                                            #if (value_of_attackers[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] > value_of_defenders[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)])
                                            #{ @@Defenders_value_penalty = true; }
                                            
                                            # Penalty for moving the only piece that defends a square to that square (thus leavind the defender
                                            # alone in the square he once defended, defenceless!)
                                            #if ((exception_defender_column[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] == (@@m_StartingColumnNumber - 1)) && (exception_defender_rank[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] == (@@m_StartingRank - 1)))
                                    #    danger_penalty = false;

                                    # HUO DEBUG
                                    #LoseQueen_penalty = false;

                                    #if (danger_penalty == true)
                                    #{
                                    CheckMove(@@Skakiera_Thinking);
                                    #}
                                    # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
                                    #if(huo_debug == true)
                                    #{
                                    #	Console.WriteLine("RETURNED TO ComputerMove");
                                    #	Console.ReadKey();
                                    #}
                                    #}

                                    ##############/
                                    # 2009 v4 change
                                    ##############/
                                end#end for r
                            end# end for w

                        end#end if (((@@Who_Is_Analyzed.CompareTo("HY")


                    end#end for jjj
                end#end for iii


            end #end if @@Stop_Analyzing == false


            ######################################################/
            # find if there is mate
            ######################################################/

            if ((@@Move_Analyzed == 0) && ((@@WhiteKingCheck == true) || (@@BlackKingCheck == true)))
                if (@@Best_Move_Found == false)
                    @@mate = true;
                    if (@@m_PlayerColor.CompareTo("White") == 0)
                        Console.WriteLine("Black is MATE!");
                    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                        Console.WriteLine("White is MATE!");
                    end
                end

            end


            # DO THE BEST MOVE FOUND

            if (@@Move_Analyzed == 0)
                # Επαναφορά της τιμής της @@Stop_Analyzing (βλ. πιο πάνω)
                @@Stop_Analyzing = false;

                ################################################/
                # REDRAW THE CHESSBOARD
                ################################################/

                # erase the initial square

                for iii in 0..7 do
                    for jjj in 0..7 do
                        @@Skakiera[(iii), (jjj)] = @@Skakiera_Move_0[(iii), (jjj)];
                    end
                end

                @@MovingPiece = @@Skakiera[(@@Best_Move_StartingColumnNumber - 1), (@@Best_Move_StartingRank - 1)];
                @@Skakiera[(@@Best_Move_StartingColumnNumber - 1), (@@Best_Move_StartingRank - 1)] = "";

                if (@@Best_Move_StartingColumnNumber == 1)
                    @@HY_Starting_Column_Text = "a";
                elsif (@@Best_Move_StartingColumnNumber == 2)
                    @@HY_Starting_Column_Text = "b";
                elsif (@@Best_Move_StartingColumnNumber == 3)
                    @@HY_Starting_Column_Text = "c";
                elsif (@@Best_Move_StartingColumnNumber == 4)
                    @@HY_Starting_Column_Text = "d";
                elsif (@@Best_Move_StartingColumnNumber == 5)
                    @@HY_Starting_Column_Text = "e";
                elsif (@@Best_Move_StartingColumnNumber == 6)
                    @@HY_Starting_Column_Text = "f";
                elsif (@@Best_Move_StartingColumnNumber == 7)
                    @@HY_Starting_Column_Text = "g";
                elsif (@@Best_Move_StartingColumnNumber == 8)
                    @@HY_Starting_Column_Text = "h";
                end

                # position piece to the square of destination

                @@Skakiera[(@@Best_Move_FinishingColumnNumber - 1), (@@Best_Move_FinishingRank - 1)] = @@MovingPiece;

                if (@@Best_Move_FinishingColumnNumber == 1)
                    @@HY_Finishing_Column_Text = "a";
                elsif (@@Best_Move_FinishingColumnNumber == 2)
                    @@HY_Finishing_Column_Text = "b";
                elsif (@@Best_Move_FinishingColumnNumber == 3)
                    @@HY_Finishing_Column_Text = "c";
                elsif (@@Best_Move_FinishingColumnNumber == 4)
                    @@HY_Finishing_Column_Text = "d";
                elsif (@@Best_Move_FinishingColumnNumber == 5)
                    @@HY_Finishing_Column_Text = "e";
                elsif (@@Best_Move_FinishingColumnNumber == 6)
                    @@HY_Finishing_Column_Text = "f";
                elsif (@@Best_Move_FinishingColumnNumber == 7)
                    @@HY_Finishing_Column_Text = "g";
                elsif (@@Best_Move_FinishingColumnNumber == 8)
                    @@HY_Finishing_Column_Text = "h";
                end

                # if king is moved, no castling can occur
                if (@@MovingPiece.CompareTo("White King") == 0)
                    @@White_King_Moved = true;
                elsif (@@MovingPiece.CompareTo("Black King") == 0)
                    @@Black_King_Moved = false;
                elsif (@@MovingPiece.CompareTo("White Rook") == 0)
                    if ((@@Best_Move_StartingColumnNumber == 1) && (@@Best_Move_StartingRank == 1))
                        @@White_Rook_a1_Moved = false;
                    elsif ((@@Best_Move_StartingColumnNumber == 8) && (@@Best_Move_StartingRank == 1))
                        @@White_Rook_h1_Moved = false;
                    end
                elsif (@@MovingPiece.CompareTo("Black Rook") == 0)
                    if ((@@Best_Move_StartingColumnNumber == 1) && (@@Best_Move_StartingRank == 8))
                        @@Black_Rook_a8_Moved = false;
                    elsif ((@@Best_Move_StartingColumnNumber == 8) && (@@Best_Move_StartingRank == 8))
                        @@Black_Rook_h8_Moved = false;
                    end
                end

                # is there a pawn to promote?
                if (((@@MovingPiece.CompareTo("White Pawn") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0)) && (@@m_WhoPlays.CompareTo("HY") == 0))

                    if (@@Best_Move_FinishingRank == 8)
                        @@Skakiera[(@@Best_Move_FinishingColumnNumber - 1), (@@Best_Move_FinishingRank - 1)] = "White Queen";
                    elsif (@@Best_Move_FinishingRank == 1)
                        @@Skakiera[(@@Best_Move_FinishingColumnNumber - 1), (@@Best_Move_FinishingRank - 1)] = "Black Queen";
                    end

                end


                ###################################
                # show HY move
                ###################################
                # COMPARISON CODE
                # UNCOMMENT TO SHOW THINKING TIME!
                # Uncomment to have the program record the start and stop time to a log .txt file
                #StreamWriter huo_sw2 = new StreamWriter("game.txt", true);
                #Console.WriteLine(string.Concat("Stoped thinking at: ", DateTime.Now.ToString("hh:mm:ss.fffffff")));
                #huo_sw2.WriteLine(string.Concat("Stoped thinking at: ", DateTime.Now.ToString("hh:mm:ss.fffffff")));
                #Console.WriteLine(string.Concat("Number of moves analyzed: ", @@number_of_moves_analysed.ToString()));
                #huo_sw2.WriteLine(string.Concat("Number of moves analyzed: ", @@number_of_moves_analysed.ToString()));

                #nextLine = String.Concat(@@HY_Starting_Column_Text, @@Best_Move_StartingRank.to_s, " -> ", @@HY_Finishing_Column_Text, @@Best_Move_FinishingRank.to_s);
                #Console.WriteLine(String.Concat("My move is: ", nextLine));
                @last_move_hy = [@@HY_Starting_Column_Text, @@Best_Move_StartingRank, @@HY_Finishing_Column_Text, @@Best_Move_FinishingRank]
                
                #thinking = false;

                # UNCOMMENT TO SHOW THINKING TIME!
                #Console.WriteLine("Computer thought for {0} seconds", 0.001 * (Environment.TickCount - start));

                #huo_sw2.Close();
                @@number_of_moves_analysed = 0;

                # Αν ο υπολογιστής παίζει με τα λευκά, τότε αυξάνεται τώρα το νούμερο της κίνησης.
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Move = @@Move + 1;
                end

                # now it is the other color's turn to play
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@m_WhichColorPlays = "Black";
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@m_WhichColorPlays = "White";
                end

                # now it is the human's turn to play
                @@m_WhoPlays = "Human";

            else
                @@Move_Analyzed = @@Move_Analyzed - 2;
                @@Who_Is_Analyzed = "HY";
                for i in 0..7 do
                    for j in 0..7 do
                        @@Skakiera_Thinking[i, j] = @@Skakiera_Move_0[i, j];
                    end
                end
            end#end if (@@Move_Analyzed == 0)
        end #end ComputerMove

      def CountScore(cSSkakiera)
            # Changed in version 0.5
            # white pieces: positive score
            # black pieces: negative score

            @@Current_Move_Score = 0;

            if (@@Destination_Piece_Value > @@Moving_Piece_Value)
                if (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 100 * (@@Destination_Piece_Value - @@Moving_Piece_Value);
                elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 100 * (@@Destination_Piece_Value - @@Moving_Piece_Value);
                end
            end

            ##############/
            # 2009 v4 change
            ##############/
            # Changed in version 0.5
            # PENALTIES SECTION
            # (see ComputerMove for explanation of the Dangerous Squares)

            #if (@@Danger_penalty == true)
            #{
            #    if (@@m_PlayerColor.CompareTo("White") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score + 5;
            #    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score - 5;
            #}

            #if (@@Attackers_penalty == true)
            #{
            #    if (@@m_PlayerColor.CompareTo("White") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score + 4;
            #    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score - 4;
            #}

            #if (@@Defenders_value_penalty == true)
            #{
            #    if (@@m_PlayerColor.CompareTo("White") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score + 4;
            #    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
            #        @@Current_Move_Score = @@Current_Move_Score - 4;
            #}
            ##############/
            # 2009 v4 change
            ##############/

            for i in 0..7 do
                for j in 0..7 do
                    if (cSSkakiera[(i), (j)].CompareTo("White Pawn") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 1;
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Rook") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 5;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("Black") == 0)
                                if (((i + 1) <= 7) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i + 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@rook_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i - 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@rook_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Knight") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 3;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("Black") == 0)
                                if (((i + 1) <= 7) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i + 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@knight_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i - 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@knight_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Bishop") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 3;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("Black") == 0)
                                if (((i + 1) <= 7) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i + 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@bishop_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i - 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@bishop_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Queen") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 9;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("Black") == 0)
                                if (((i + 1) <= 7) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i + 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@queen_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j + 1) <= 7))
                                    if (cSSkakiera[(i - 1), (j + 1)].CompareTo("Black Pawn") == 0)
                                        @@queen_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("White King") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 15;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Pawn") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 1;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Rook") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 5;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("White") == 0)
                                if (((i + 1) <= 7) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i + 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@rook_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i - 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@rook_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Knight") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 3;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("White") == 0)
                                if (((i + 1) <= 7) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i + 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@knight_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i - 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@knight_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Bishop") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 3;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("White") == 0)
                                if (((i + 1) <= 7) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i + 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@bishop_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i - 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@bishop_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Queen") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 9;

                        # Penalty if the piece of the computer is threatened by a pawn (see CheckMove)
                        if (@@checked_for_pawn_threats == false)
                            if (@@m_PlayerColor.CompareTo("White") == 0)
                                if (((i + 1) <= 7) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i + 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@queen_pawn_threat = true;
                                    end
                                end

                                if (((i - 1) >= 0) && ((j - 1) >= 0))
                                    if (cSSkakiera[(i - 1), (j - 1)].CompareTo("White Pawn") == 0)
                                        @@queen_pawn_threat = true;
                                    end
                                end
                            end
                        end
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black King") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 15;
                    end

                end#end for j
            end#end for i

            ##############/
            # 2009 v4 change
            ##############/
            # Pawn threat penalties: if the computer moves its piece at a square where it is
            # threatened by an opponent's pawn, there is a penalty (see CheckMove and CountScore).
            # ADDED IN VERSION 0.6
            if (@@rook_pawn_threat == true)
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 10;
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 10;
                end
            end

            if (@@knight_pawn_threat == true)
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 6;
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 6;
                end
            end

            if (@@bishop_pawn_threat == true)
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 6;
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 6;
                end
            end

            if (@@queen_pawn_threat == true)
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 20;
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 20;
                end
            end

            if (@@danger_penalty == true)
                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 20;
                elsif (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 20;
                end
            end
            ##############/
            # 2009 v4 change
            ##############/

            # if we are in the beginning of the game, it is not good to move
            # your queen, king, rooks etc...

            if (@@Move < 11)

                # control the center with your pawns

                if (cSSkakiera[3, 2].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[3, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[4, 2].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[4, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[3, 5].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.4;
                end

                if (cSSkakiera[3, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.4;
                end

                if (cSSkakiera[4, 5].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.4;
                end

                if (cSSkakiera[4, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.4;
                end

                # don't play a4, h4, etc

                if (cSSkakiera[0, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.2;
                end

                if (cSSkakiera[1, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.2;
                end

                if (cSSkakiera[6, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.2;
                end

                if (cSSkakiera[7, 3].CompareTo("White Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.2;
                end

                if (cSSkakiera[0, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[1, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[6, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                if (cSSkakiera[7, 4].CompareTo("Black Pawn") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.4;
                end

                # don't play the rook

                if (cSSkakiera[0, 0].CompareTo("") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.1;
                end

                if (cSSkakiera[7, 0].CompareTo("") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.1;
                end

                if (cSSkakiera[0, 7].CompareTo("") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.1;
                end

                if (cSSkakiera[7, 7].CompareTo("") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.1;
                end


                if (cSSkakiera[0, 2].CompareTo("White Knight") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.1;
                end

                if (cSSkakiera[7, 2].CompareTo("White Knight") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 0.1;
                end

                if (cSSkakiera[0, 5].CompareTo("Black Knight") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.1;
                end

                if (cSSkakiera[7, 5].CompareTo("Black Knight") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 0.1;
                end
            end#end if (@@Move < 11)

            if (@@Move < 10)
                # Μην κινείς τη βασίλισσα νωρίς

                if (@@m_PlayerColor.CompareTo("Black") == 0)
                    if (cSSkakiera[3, 0].CompareTo("") == 0)
                        @@Current_Move_Score = @@Current_Move_Score - 10.9;
                    end
                end

                if (@@m_PlayerColor.CompareTo("White") == 0)
                    if (cSSkakiera[3, 7].CompareTo("") == 0)
                        @@Current_Move_Score = @@Current_Move_Score + 10.9;
                    end
                end
            end

            if (@@Move < 8)
                # Μην κινείς το βασιλιά νωρίς

                if ((cSSkakiera[4, 0].CompareTo("") == 0) && (@@m_PlayerColor.CompareTo("Black") == 0))
                    @@Current_Move_Score = @@Current_Move_Score - 3;
                end

                if ((cSSkakiera[4, 7].CompareTo("") == 0) && (@@m_PlayerColor.CompareTo("White") == 0))
                    @@Current_Move_Score = @@Current_Move_Score + 3;
                end
            end

            #	if( @@Move < 7 )
            #	{
            #		# don't go to check too early!
            #
            #		if(@@m_PlayerColor.CompareTo("Black") == 0)
            #		{
            #			CheckForBlackCheck(cSSkakiera);
            #			if (@@BlackKingCheck == true)
            #				@@Current_Move_Score = @@Current_Move_Score - 3;
            #		}
            #
            #		if(@@m_PlayerColor.CompareTo("White") == 0)
            #		{
            #			CheckForWhiteCheck(cSSkakiera);
            #			if (@@WhiteKingCheck == true)
            #				@@Current_Move_Score = @@Current_Move_Score + 3;
            #		}
            #	}

            # HY likes to eat the opponent's queen, so as to simplify the game!
            if (@@eat_queen == true)
                if (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Current_Move_Score = @@Current_Move_Score - 2;
                elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@Current_Move_Score = @@Current_Move_Score + 2;
                end
            end

            # if mate is possible, go for it!
            #if( @@Possible_mate == true )
            #{
            #	if( @@m_PlayerColor.CompareTo("White") == 0 )
            #		@@Current_Move_Score = @@Current_Move_Score - 0.2;
            #	elsif( @@m_PlayerColor.CompareTo("Black") == 0 )
            #		@@Current_Move_Score = @@Current_Move_Score + 0.2;
            #}

            # don't move the king early in the game!
            #if( (@@moving_the_king == true) && (@@Move < 10) )
            #{
            #	if( @@m_PlayerColor.CompareTo("White") == 0 )
            #		@@Current_Move_Score = @@Current_Move_Score + 0.4;
            #	elsif( @@m_PlayerColor.CompareTo("Black") == 0 )
            #		@@Current_Move_Score = @@Current_Move_Score - 0.4;
            #}


        end #end CountScore

      def CountScore_Human(cSSkakiera)
            # count score for human moves analyzed
            # SEE RESPECTIVE CountScore funtion for analytical comments in English!
            # All pieces values here are increased by +2 relatively to the respective values
            # in CountScore. This is to show/emphasize to the computer that its human opponent
            # will aim at killing his pieces!
            @@Current_Human_Move_Score = 0;

            for i in 0..7 do
                for j in 0..7 do
                    if (cSSkakiera[(i), (j)].CompareTo("White Pawn") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 1;

                        # Αν το πιόνι πάει να βγει βασίλισσα.
                        # Ο έλεγχος γίνεται μόνο για τα πιόνια του αντιπάλου,
                        # αλλιώς ο ΗΥ θα προωθούσε συνεχώς τα πιόνια του
                        # no matter what!
                        #if( m_PlayerColor.CompareTo("White") == 0 )
                        #{
                        #	if( j == 5 )
                        #		@@Current_Human_Move_Score = @@Current_Human_Move_Score + 1;
                        #	elsif( j == 6 )
                        #		@@Current_Human_Move_Score = @@Current_Human_Move_Score + 1.1;
                        #	elsif( j == 7 )
                        #		@@Current_Human_Move_Score = @@Current_Human_Move_Score + 1.2;
                        #}
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Rook") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 7;
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Knight") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 5;
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Bishop") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 5;
                    elsif (cSSkakiera[(i), (j)].CompareTo("White Queen") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 11;
                    elsif (cSSkakiera[(i), (j)].CompareTo("White King") == 0)
                        # Ο (λευκός) βασιλιάς έχει πολύ μικρό σκορ.
                        # Αυτό γίνεται διότι εάν ο λευκός βασιλιάς είχε π.χ.
                        # σκορ 100 (ήτοι πολύ μεγάλο), τότε ο μαύρος
                        # υπολογιστής θα κινούσε όλα τα κομμάτια του
                        # με μοναδικό στόχο να φάει το βασιλιά του αντιπάλου,
                        # άρα θα έκανε τρομερές βλακείες.
                        # Π.χ. αν στο τέλος των 5 κινήσεων που βλέπει σε βάθος
                        # ο υπολογιστής έβλεπε ότι θα έτρωγε τον αντίπαλο βασιλιά,
                        # τότε μπορεί να έπαιζε ακόμα και τη βασίλισσα του πολύ
                        # νωρίς στο παιχνίδι ή να αγνοούσε ένα πιθανό ματ που θα
                        # του έκανε ο αντίπαλος 1 κίνηση πριν (αφού στο τέλος όλων
                        # των κινήσεων θα μετρούσε το τελικό σκορ της θέσης και
                        # θα έβισκε ότι θα ήταν μια χαρά: το +100 του λευκού βασιλιά
                        # θα αντισταθμιζόταν από το -100 του μαύρου και όλα θα
                        # "φαινόντουσαν" καλα!
                        # Το αντίστοιχο συμβαίνει με τον μαύρο βασιλιά.
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score + 17;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Pawn") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 1;

                        # Αν το πιόνι πάει να βγει βασίλισσα.
                        # Ο έλεγχος γίνεται μόνο για τα πιόνια του αντιπάλου,
                        # αλλιώς ο ΗΥ θα προωθούσε συνεχώς τα πιόνια του
                        # no matter what!
                        #if( @@m_PlayerColor.CompareTo("Black") == 0 )
                        #{
                        #if( j == 2 )
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 1;
                        #elsif( j == 1 )
                        #	@@Current_Human_Move_Score = @@Current_Human_Move_Score - 1.1;
                        #elsif( j == 0 )
                        #	@@Current_Human_Move_Score = @@Current_Human_Move_Score - 1.2;
                        #}
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Rook") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 7;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Knight") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 5;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Bishop") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 5;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black Queen") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 11;
                    elsif (cSSkakiera[(i), (j)].CompareTo("Black King") == 0)
                        @@Current_Human_Move_Score = @@Current_Human_Move_Score - 17;
                    end

                end #end for j
            end#end for i

        end #end CountScore_Human

        # FUNCTION TO CHECK THE LEGALITY (='Nomimotita' in Greek) OF A MOVE
        # (i.e. if between the initial and the destination square lies another
        # piece, then the move is not legal).
      def ElegxosNomimotitas(eNSkakiera) 
          
            nomimotita = true;

            if (((@@m_FinishingRank - 1) > 7) || ((@@m_FinishingRank - 1) < 0) || ((@@m_FinishingColumnNumber - 1) > 7) || ((@@m_FinishingColumnNumber - 1) < 0))
                nomimotita = false;
            end

            # if a piece of the same colout is in the destination square...
            if ((@@MovingPiece.CompareTo("White King") == 0) || (@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("White Pawn") == 0))
                if ((eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White King") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White Queen") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White Rook") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White Knight") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White Bishop") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("White Pawn") == 0))
                    nomimotita = false;
                end
            elsif ((@@MovingPiece.CompareTo("Black King") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0) || (@@MovingPiece.CompareTo("Black Pawn") == 0))
                if ((eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black King") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black Queen") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black Rook") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black Knight") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black Bishop") == 0) || (eNSkakiera[((@@m_FinishingColumnNumber - 1)), ((@@m_FinishingRank - 1))].CompareTo("Black Pawn") == 0))
                    nomimotita = false;
                end
            end

            if (@@MovingPiece.CompareTo("White King") == 0)
                ############/
                # white king
                ############/
                # is the king threatened in the destination square?
                # temporarily move king
                eNSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                @@ProsorinoKommati = eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];
                eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "White King";

                @@WhiteKingCheck = CheckForWhiteCheck(eNSkakiera);

                if (@@WhiteKingCheck == true)
                    nomimotita = false;
                end

                # restore pieces
                eNSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "White King";
                eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@ProsorinoKommati;

            elsif (@@MovingPiece.CompareTo("Black King") == 0)
                #############/
                # black king
                #############/
                # is the black king threatened in the destination square?
                # temporarily move king
                eNSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                @@ProsorinoKommati = eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];
                eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = "Black King";

                @@BlackKingCheck = CheckForBlackCheck(eNSkakiera);

                if (@@BlackKingCheck == true)
                    nomimotita = false;
                end

                # restore pieces
                eNSkakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "Black King";
                eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@ProsorinoKommati;

            elsif (@@MovingPiece.CompareTo("White Pawn") == 0)
                ##########/
                # white pawn
                ##########/

                # move forward

                if ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                    if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 1)
                        nomimotita = false;
                    end
                # move forward for 2 squares
                elsif ((@@m_FinishingRank == (@@m_StartingRank + 2)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                    if (@@m_StartingRank == 2)
                        if ((eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 1) || (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)].CompareTo("") == 1))
                            nomimotita = false;
                        end
                    end
                # eat forward to the right
                elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber + 1))
                    if (@@enpassant_occured == false)
                        if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 0)
                            nomimotita = false;
                        end
                    else
                        if ((@@m_FinishingRank != @@enpassant_possible_target_rank) || (@@m_FinishingColumnNumber != @@enpassant_possible_target_column))
                            nomimotita = false;
                        end
                    end
                # eat forward to the left
                elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber - 1))
                    if (@@enpassant_occured == false)
                        if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 0)
                            nomimotita = false;
                        end
                    else
                        if ((@@m_FinishingRank != @@enpassant_possible_target_rank) || (@@m_FinishingColumnNumber != @@enpassant_possible_target_column))
                            nomimotita = false;
                        end
                    end
                end

            elsif (@@MovingPiece.CompareTo("Black Pawn") == 0)
                ##########/
                # black pawn
                ##########/

                # move forward

                if ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                    if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 1)
                        nomimotita = false;
                    end
                # move forward for 2 squares
                elsif ((@@m_FinishingRank == (@@m_StartingRank - 2)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                    if (@@m_StartingRank == 7)
                        if ((eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 1) || (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank + 1 - 1)].CompareTo("") == 1))
                            nomimotita = false;
                        end
                    end
                # eat forward to the right

                elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber + 1))
                    if (@@enpassant_occured == false)
                        if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 0)
                            nomimotita = false;
                        end
                    else
                        if ((@@m_FinishingRank != @@enpassant_possible_target_rank) || (@@m_FinishingColumnNumber != @@enpassant_possible_target_column))
                            nomimotita = false;
                        end
                    end
                # eat forward to the left

                elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber - 1))
                    if (@@enpassant_occured == false)
                        if (eNSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("") == 0)
                            nomimotita = false;
                        end
                    else
                        if ((@@m_FinishingRank != @@enpassant_possible_target_rank) || (@@m_FinishingColumnNumber != @@enpassant_possible_target_column))
                            nomimotita = false;
                        end
                    end
                end

            elsif ((@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0))
                @@h = 0;
                @@p = 0;
                @@hhh = 0;
                @@how_to_move_Rank = 0;
                @@how_to_move_Column = 0;

                if (((@@m_FinishingRank - 1) > (@@m_StartingRank - 1)) || ((@@m_FinishingRank - 1) < (@@m_StartingRank - 1)))
                    @@how_to_move_Rank = ((@@m_FinishingRank - 1) - (@@m_StartingRank - 1)) / ((@@m_FinishingRank - 1) - (@@m_StartingRank - 1)).abs;
                end

                if (((@@m_FinishingColumnNumber - 1) > (@@m_StartingColumnNumber - 1)) || ((@@m_FinishingColumnNumber - 1) < (@@m_StartingColumnNumber - 1)))
                    @@how_to_move_Column = ((@@m_FinishingColumnNumber - 1) - (@@m_StartingColumnNumber - 1)) / ((@@m_FinishingColumnNumber - 1) - (@@m_StartingColumnNumber - 1)).abs;
                end

                @@exit_elegxos_nomimothtas = false;

                while (@@exit_elegxos_nomimothtas == false);
                    @@h = @@h + @@how_to_move_Rank;
                    @@p = @@p + @@how_to_move_Column;

                    if ((((@@m_StartingRank - 1) + @@h) == (@@m_FinishingRank - 1)) && ((((@@m_StartingColumnNumber - 1) + @@p)) == (@@m_FinishingColumnNumber - 1)))
                        @@exit_elegxos_nomimothtas = true;
                    end

                    if ((@@m_StartingColumnNumber - 1 + @@p) < 0)
                        @@exit_elegxos_nomimothtas = true;
                    elsif ((@@m_StartingRank - 1 + @@h) < 0)
                        @@exit_elegxos_nomimothtas = true;
                    elsif ((@@m_StartingColumnNumber - 1 + @@p) > 7)
                        @@exit_elegxos_nomimothtas = true;
                    elsif ((@@m_StartingRank - 1 + @@h) > 7)
                        @@exit_elegxos_nomimothtas = true;
                    end

                    # if a piece exists between the initial and the destination square,
                    # then the move is illegal!
                    if (@@exit_elegxos_nomimothtas == false)
                        if (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White Rook") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White Knight") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White Bishop") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White Queen") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White King") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("White Pawn") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        end

                        if (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black Rook") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black Knight") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black Bishop") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black Queen") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black King") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        elsif (eNSkakiera[(@@m_StartingColumnNumber - 1 + @@p), (@@m_StartingRank - 1 + @@h)].CompareTo("Black Pawn") == 0)
                            nomimotita = false;
                            @@exit_elegxos_nomimothtas = true;
                        end
                    end #if (@@exit_elegxos_nomimothtas == false)
                end #end while
          end #if
            return nomimotita;
        end #end ElegxosNomimotitas


        # FUNCTION TO CHECK THE CORRECTNESS (='orthotita' in Greek) OF THE MOVE
        # (i.e. a Bishop can only move in diagonals, rooks in lines and columns etc)
      def ElegxosOrthotitas(eOSkakiera)

            orthotita = false;
            @@enpassant_occured = false;

            if ((@@m_WhoPlays.CompareTo("Human") == 0) && (@@m_WrongColumn == false) && (@@MovingPiece.CompareTo("") == 1))    # Αν ο χρήστης έχει γράψει μία έγκυρη στήλη και έχει
            
                # ROOK

                if ((@@MovingPiece.CompareTo("White Rook") == 0) || (@@MovingPiece.CompareTo("Black Rook") == 0))
                    if ((@@m_FinishingColumnNumber != @@m_StartingColumnNumber) && (@@m_FinishingRank == @@m_StartingRank))       # Κίνηση σε στήλη
                        orthotita = true;
                    elsif ((@@m_FinishingRank != @@m_StartingRank) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))  # Κίνηση σε γραμμή
                        orthotita = true;
                    end
                end

                # horse (with knight...)

                if ((@@MovingPiece.CompareTo("White Knight") == 0) || (@@MovingPiece.CompareTo("Black Knight") == 0))
                    if ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && (@@m_FinishingRank == (@@m_StartingRank + 2)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 2)) && (@@m_FinishingRank == (@@m_StartingRank - 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && (@@m_FinishingRank == (@@m_StartingRank - 2)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && (@@m_FinishingRank == (@@m_StartingRank - 2)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 2)) && (@@m_FinishingRank == (@@m_StartingRank - 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 2)) && (@@m_FinishingRank == (@@m_StartingRank + 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && (@@m_FinishingRank == (@@m_StartingRank + 2)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 2)) && (@@m_FinishingRank == (@@m_StartingRank + 1)))
                        orthotita = true;
                    end
                end

                # bishop

                if ((@@MovingPiece.CompareTo("White Bishop") == 0) || (@@MovingPiece.CompareTo("Black Bishop") == 0))
                    ##########
                    # 2009 v4 change
                    ##########
                    #if ((Math.Abs(@@m_FinishingColumnNumber - @@m_StartingColumnNumber)) == (Math.Abs(@@m_FinishingRank - @@m_StartingRank)))
                    #    orthotita = true;
                    if ((((@@m_FinishingColumnNumber - @@m_StartingColumnNumber)).abs == ((@@m_FinishingRank - @@m_StartingRank).abs)) && (@@m_FinishingColumnNumber != @@m_StartingColumnNumber) && (@@m_FinishingRank != @@m_StartingRank))
                        orthotita = true;
                    end
                    ##########
                    # 2009 v4 change
                    ##########
                end

                # queen

                if ((@@MovingPiece.CompareTo("White Queen") == 0) || (@@MovingPiece.CompareTo("Black Queen") == 0))
                    if ((@@m_FinishingColumnNumber != @@m_StartingColumnNumber) && (@@m_FinishingRank == @@m_StartingRank))       # Κίνηση σε στήλη
                        orthotita = true;
                    elsif ((@@m_FinishingRank != @@m_StartingRank) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))  # Κίνηση σε γραμμή
                        orthotita = true;
                    end

                    ##########
                    # 2009 v4 change
                    ##########
                    # move in diagonals
                    #if ((Math.Abs(@@m_FinishingColumnNumber - @@m_StartingColumnNumber)) == (Math.Abs(@@m_FinishingRank - @@m_StartingRank)))
                    #    orthotita = true;
                    if ((((@@m_FinishingColumnNumber - @@m_StartingColumnNumber).abs) == ((@@m_FinishingRank - @@m_StartingRank).abs)) && (@@m_FinishingColumnNumber != @@m_StartingColumnNumber) && (@@m_FinishingRank != @@m_StartingRank))
                        orthotita = true;
                    end
                    ##########
                    # 2009 v4 change
                    ##########
                end

                # king

                if ((@@MovingPiece.CompareTo("White King") == 0) || (@@MovingPiece.CompareTo("Black King") == 0))
                    # move in rows and columns

                    if ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && (@@m_FinishingRank == @@m_StartingRank))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && (@@m_FinishingRank == @@m_StartingRank))
                        orthotita = true;
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                        orthotita = true;
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                        orthotita = true;
                   
                    # move in diagonals

                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && (@@m_FinishingRank == (@@m_StartingRank + 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && (@@m_FinishingRank == (@@m_StartingRank - 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && (@@m_FinishingRank == (@@m_StartingRank - 1)))
                        orthotita = true;
                    elsif ((@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && (@@m_FinishingRank == (@@m_StartingRank + 1)))
                        orthotita = true;
                    end

                end

                # white pawn

                if (@@MovingPiece.CompareTo("White Pawn") == 0)
                    # move forward

                    if ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                        orthotita = true;
                    # move forward for 2 squares
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 2)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber) && (@@m_StartingRank == 2))
                        orthotita = true;

                    # eat forward to the left
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && ((eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Pawn") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Rook") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Knight") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Bishop") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Queen") == 0)))
                        orthotita = true;

                    # eat forward to the right
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && ((eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Pawn") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Rook") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Knight") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Bishop") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("Black Queen") == 0)))
                        orthotita = true;

                    # En Passant eat forward to the left
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)))
                        if ((@@m_FinishingRank == 4) && (eOSkakiera[(@@m_FinishingColumnNumber - 1), (4)].CompareTo("Black Pawn") == 0))
                            orthotita = true;
                            @@enpassant_occured = true;
                            eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)] = "";
                        else
                            orthotita = false;
                            @@enpassant_occured = false;
                        end
                    # En Passant eat forward to the right
                    elsif ((@@m_FinishingRank == (@@m_StartingRank + 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)))
                        if ((@@m_FinishingRank == 4) && (eOSkakiera[(@@m_FinishingColumnNumber - 1), (4)].CompareTo("Black Pawn") == 0))
                            orthotita = true;
                            @@enpassant_occured = true;
                            eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)] = "";
                        else
                            orthotita = false;
                            @@enpassant_occured = false;
                        end
                    end

                end #if (@@MovingPiece.CompareTo("White Pawn")


                # black pawn

                if (@@MovingPiece.CompareTo("Black Pawn") == 0)
                    # move forward

                    if ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber))
                        orthotita = true;
                    # move forward for 2 squares
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 2)) && (@@m_FinishingColumnNumber == @@m_StartingColumnNumber) && (@@m_StartingRank == 7))
                        orthotita = true;

                    # eat forward to the left
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)) && ((eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Pawn") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Rook") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Knight") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Bishop") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Queen") == 0)))
                        orthotita = true;

                    # eat forward to the right
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)) && ((eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Pawn") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Rook") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Knight") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Bishop") == 0) || (eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)].CompareTo("White Queen") == 0)))
                        orthotita = true;

                    # En Passant eat forward to the left
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber + 1)))
                        if ((@@m_FinishingRank == 3) && (eOSkakiera[(@@m_FinishingColumnNumber - 1), (3)].CompareTo("White Pawn") == 0))
                            orthotita = true;
                            @@enpassant_occured = true;
                            eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank + 1 - 1)] = "";
                        else
                            orthotita = false;
                            @@enpassant_occured = false;
                        end
                    # En Passant eat forward to the right
                    elsif ((@@m_FinishingRank == (@@m_StartingRank - 1)) && (@@m_FinishingColumnNumber == (@@m_StartingColumnNumber - 1)))
                        if ((@@m_FinishingRank == 3) && (eOSkakiera[(@@m_FinishingColumnNumber - 1), (3)].CompareTo("White Pawn") == 0))
                            orthotita = true;
                            @@enpassant_occured = true;
                            eOSkakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank + 1 - 1)] = "";
                        else
                            orthotita = false;
                            @@enpassant_occured = false;
                        end
                    end

                end#end if (@@MovingPiece.CompareTo("Black Pawn"

            end#end if ((@@m_WhoPlays.CompareTo("Human")

            return orthotita;
        end #end ElegxosOrthotitas


      def Enter_move()

            #######################################################/
            #######################################################/
            # show the move entered by the human player
            #######################################################/
            #######################################################/

            if (@@m_StartingColumn.CompareTo("A") == 0)
                @@m_StartingColumnNumber = 1;
            elsif (@@m_StartingColumn.CompareTo("B") == 0)
                @@m_StartingColumnNumber = 2;
            elsif (@@m_StartingColumn.CompareTo("C") == 0)
                @@m_StartingColumnNumber = 3;
            elsif (@@m_StartingColumn.CompareTo("D") == 0)
                @@m_StartingColumnNumber = 4;
            elsif (@@m_StartingColumn.CompareTo("E") == 0)
                @@m_StartingColumnNumber = 5;
            elsif (@@m_StartingColumn.CompareTo("F") == 0)
                @@m_StartingColumnNumber = 6;
            elsif (@@m_StartingColumn.CompareTo("G") == 0)
                @@m_StartingColumnNumber = 7;
            elsif (@@m_StartingColumn.CompareTo("H") == 0)
                @@m_StartingColumnNumber = 8;
            end


            if (@@m_FinishingColumn.CompareTo("A") == 0)
                @@m_FinishingColumnNumber = 1;
            elsif (@@m_FinishingColumn.CompareTo("B") == 0)
                @@m_FinishingColumnNumber = 2;
            elsif (@@m_FinishingColumn.CompareTo("C") == 0)
                @@m_FinishingColumnNumber = 3;
            elsif (@@m_FinishingColumn.CompareTo("D") == 0)
                @@m_FinishingColumnNumber = 4;
            elsif (@@m_FinishingColumn.CompareTo("E") == 0)
                @@m_FinishingColumnNumber = 5;
            elsif (@@m_FinishingColumn.CompareTo("F") == 0)
                @@m_FinishingColumnNumber = 6;
            elsif (@@m_FinishingColumn.CompareTo("G") == 0)
                @@m_FinishingColumnNumber = 7;
            elsif (@@m_FinishingColumn.CompareTo("H") == 0)
                @@m_FinishingColumnNumber = 8;
            end


            ################################################/
            ################################################/
            # record which piece is moving
            ################################################/
            ################################################/

            if (@@m_WhoPlays.CompareTo("HY") == 0)   # Αν είναι η σειρά του υπολογιστή να παίξει (και όχι του χρήστη), τότε άκυρο!!
                Console.WriteLine("It's not your turn.");
            elsif (((@@m_WhoPlays.CompareTo("Human") == 0) || (@@m_PlayerColor.CompareTo("Self") == 0)) && (((@@m_WhichColorPlays.CompareTo("White") == 0) && ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White Pawn") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White Rook") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White Knight") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White Bishop") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White Queen") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White King") == 0))) || ((@@m_WhichColorPlays.CompareTo("Black") == 0) && ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black Pawn") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black Rook") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black Knight") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black Bishop") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black Queen") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black King") == 0)))))

                @@m_WrongColumn = false;
                @@MovingPiece = "";

                # is the king under check?
                if (@@m_PlayerColor.CompareTo("White") == 0)
                    @@WhiteKingCheck = CheckForWhiteCheck(@@Skakiera);
                elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                    @@BlackKingCheck = CheckForBlackCheck(@@Skakiera);
                end

                @@MovingPiece = @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)];

                # if he chooses to move a piece of different colour...
                if (((@@m_PlayerColor.CompareTo("White") == 0) || (@@m_PlayerColor.CompareTo("Self") == 0) && ((@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White Rook") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White Knight") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White Bishop") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White Queen") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White King") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("White Pawn") == 0))) || (((@@m_PlayerColor.CompareTo("Black") == 0) || (@@m_PlayerColor.CompareTo("Self") == 0)) && ((@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black Rook") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black Knight") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black Bishop") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black Queen") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black King") == 0) || (@@Skakiera[(@@m_StartingColumnNumber - 1), ((@@m_StartingRank - 1))].CompareTo("Black Pawn") == 0))))
                    @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                end

            else
                if (@@m_WhichColorPlays.CompareTo("White") == 0)
                    Console.WriteLine("White plays.");
                elsif (@@m_WhichColorPlays.CompareTo("Black") == 0)
                    Console.WriteLine("Black plays.");
                end

                @@m_WrongColumn = true;          
            end

            # Check correctness of move entered
            @@m_OrthotitaKinisis = ElegxosOrthotitas(@@Skakiera);

            # check legality of move entered
            # (only if it is correct - so as to save time!)
            if (@@m_OrthotitaKinisis == true)
                @@m_NomimotitaKinisis = ElegxosNomimotitas(@@Skakiera);
            else
                @@m_NomimotitaKinisis = false;
            end

            # check if the human's king is in check even after his move!
            # temporarily move the piece the user wants to move
            @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
            @@ProsorinoKommati = @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];
            @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@MovingPiece;

            # check if king is still under check
            @@WhiteKingCheck = CheckForWhiteCheck(@@Skakiera);

            if ((@@m_WhichColorPlays.CompareTo("White") == 0) && (@@WhiteKingCheck == true))
                @@m_NomimotitaKinisis = false;
            end


            # check if black king is still under check
            @@BlackKingCheck = CheckForBlackCheck(@@Skakiera);

            if ((@@m_WhichColorPlays.CompareTo("Black") == 0) && (@@BlackKingCheck == true))
                @@m_NomimotitaKinisis = false;
            end

            # restore all pieces to the initial state
            @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = @@MovingPiece;
            @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@ProsorinoKommati;

            #################################/
            # CHECK IF THE HUMAN HAS ENTERED A CASTLING MOVE
            #################################/

            #############/
            # WHITE CASTLING
            #############/

            # small castling

            if ((@@m_PlayerColor.CompareTo("White") == 0) && (@@m_StartingColumnNumber == 5) && (@@m_FinishingColumnNumber == 7) && (@@m_StartingRank == 1) && (@@m_FinishingRank == 1))
                if ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White King") == 0) && (@@Skakiera[(7), (0)].CompareTo("White Rook") == 0) && (@@Skakiera[(5), (0)].CompareTo("") == 0) && (@@Skakiera[(6), (0)].CompareTo("") == 0))
                    @@m_OrthotitaKinisis = true;
                    @@m_NomimotitaKinisis = true;
                    @@Castling_Occured = true;
                end
            end

            # big castling

            if ((@@m_PlayerColor.CompareTo("White") == 0) && (@@m_StartingColumnNumber == 5) && (@@m_FinishingColumnNumber == 3) && (@@m_StartingRank == 1) && (@@m_FinishingRank == 1))
                if ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("White King") == 0) && (@@Skakiera[(0), (0)].CompareTo("White Rook") == 0) && (@@Skakiera[(1), (0)].CompareTo("") == 0) && (@@Skakiera[(2), (0)].CompareTo("") == 0) && (@@Skakiera[(3), (0)].CompareTo("") == 0))
                    @@m_OrthotitaKinisis = true;
                    @@m_NomimotitaKinisis = true;
                    @@Castling_Occured = true;
                end
            end


            #############/
            # black castling
            #############/

            # small castling

            if ((@@m_PlayerColor.CompareTo("Black") == 0) && (@@m_StartingColumnNumber == 5) && (@@m_FinishingColumnNumber == 7) && (@@m_StartingRank == 8) && (@@m_FinishingRank == 8))
                if ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black King") == 0) && (@@Skakiera[(7), (7)].CompareTo("Black Rook") == 0) && (@@Skakiera[(5), (7)].CompareTo("") == 0) && (@@Skakiera[(6), (7)].CompareTo("") == 0))
                    @@m_OrthotitaKinisis = true;
                    @@m_NomimotitaKinisis = true;
                    @@Castling_Occured = true;
                end
            end

            # big castling

            if ((@@m_PlayerColor.CompareTo("Black") == 0) && (@@m_StartingColumnNumber == 5) && (@@m_FinishingColumnNumber == 3) && (@@m_StartingRank == 8) && (@@m_FinishingRank == 8))
                if ((@@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)].CompareTo("Black King") == 0) && (@@Skakiera[(0), (7)].CompareTo("Black Rook") == 0) && (@@Skakiera[(1), (7)].CompareTo("") == 0) && (@@Skakiera[(2), (7)].CompareTo("") == 0) && (@@Skakiera[(3), (7)].CompareTo("") == 0))
                    @@m_OrthotitaKinisis = true;
                    @@m_NomimotitaKinisis = true;
                    @@Castling_Occured = true;
                end
            end

            # redraw the chessboard
            if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))
                # game moves on by 1 move (this happens only when the player plays,
                # so as to avoid increasing the game moves every half-move!)
                if (@@m_PlayerColor.CompareTo("White") == 0)
                    @@Move = @@Move + 1;
                end

                # erase initial square
                @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";

                # go to destination square
                @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@MovingPiece;


                #############################
                # check for en passant
                #############################
                if (@@enpassant_occured == true)
                    if (@@m_PlayerColor.CompareTo("White") == 0)
                        @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 - 1)] = "";
                    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                        @@Skakiera[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1 + 1)] = "";
                    end
                end


                ##################################
                # record possible sqaure when the next one playing will
                # be able to perform en passant
                ##################################
                if ((@@m_StartingRank == 2) && (@@m_FinishingRank == 4))
                    @@enpassant_possible_target_rank = @@m_FinishingRank - 1;
                    @@enpassant_possible_target_column = @@m_FinishingColumnNumber;
                elsif ((@@m_StartingRank == 7) && (@@m_FinishingRank == 5))
                    @@enpassant_possible_target_rank = @@m_FinishingRank + 1;
                    @@enpassant_possible_target_column = @@m_FinishingColumnNumber;
                else
                    # invalid value for enpassant move (= enpassant not possible in the next move)
                    @@enpassant_possible_target_rank = -9;
                    @@enpassant_possible_target_column = -9;
                end

                # check if castling occured (so as to move the rook next to the
                # moving king)
                if (@@Castling_Occured == true)
                    if (@@m_PlayerColor.CompareTo("White") == 0)
                        if (@@Skakiera[(6), (0)].CompareTo("White King") == 0)
                            @@Skakiera[(5), (0)] = "White Rook";
                            @@Skakiera[(7), (0)] = "";
                            #Console.WriteLine( "Ο λευκός κάνει μικρό ροκε." ); # Changed in version 0.5
                        elsif (@@Skakiera[(2), (0)].CompareTo("White King") == 0)
                            @@Skakiera[(3), (0)] = "White Rook";
                            @@Skakiera[(0), (0)] = "";
                            #Console.WriteLine( "Ο λευκός κάνει μεγάλο ροκε." ); # Changed in version 0.5
                        end
                    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                        if (@@Skakiera[(6), (7)].CompareTo("Black King") == 0)
                            @@Skakiera[(5), (7)] = "Black Rook";
                            @@Skakiera[(7), (7)] = "";
                            #Console.WriteLine( "Ο μαύρος κάνει μικρό ροκε." ); # Changed in version 0.5
                        elsif (@@Skakiera[(2), (7)].CompareTo("Black King") == 0)
                            @@Skakiera[(3), (7)] = "Black Rook";
                            @@Skakiera[(0), (7)] = "";
                            #Console.WriteLine( "Ο μαύρος κάνει μεγάλο ροκε." ); # Changed in version 0.5
                        end
                    end

                    # restore the @@Castling_Occured variable to false, so as to avoid false castlings in the future!
                    @@Castling_Occured = false;

                end #if (@@Castling_Occured == true)


                #############################
                # does a pawn needs promotion?
                #############################

                PawnPromotion();

                if ((@@m_PlayerColor.CompareTo("White") == 0) || (@@m_PlayerColor.CompareTo("Black") == 0))
                    @@m_WhoPlays = "HY";
                end

                # it is the other color's turn to play
                if (@@m_WhichColorPlays.CompareTo("White") == 0)
                    @@m_WhichColorPlays = "Black";
                elsif (@@m_WhichColorPlays.CompareTo("Black") == 0)
                    @@m_WhichColorPlays = "White";
                end

                # restore variable values to initial values
                @@m_StartingColumn = "";
                @@m_FinishingColumn = "";
                @@m_StartingRank = 1;
                @@m_FinishingRank = 1;

            else
                Console.WriteLine("INVALID MOVE!");
                @@Skakiera[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = @@MovingPiece;
                @@MovingPiece = "";
                @@m_WhoPlays = "Human";
          end #end if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))



            ######################/
            # CHECK MESSAGE
            ######################/

            @@WhiteKingCheck = CheckForWhiteCheck(@@Skakiera);
            @@BlackKingCheck = CheckForBlackCheck(@@Skakiera);

            if ((@@WhiteKingCheck == true) || (@@BlackKingCheck == true))
                Console.WriteLine("CHECK!");
            end


            #######################################################/
            # if it is the turn of the HY to play, then call the respective
            # HY Thought function
            #######################################################/

            if (@@m_WhoPlays.CompareTo("HY") == 0)
                @@Move_Analyzed = 0;
                @@Stop_Analyzing = false;
                @@First_Call = true;
                @@Best_Move_Found = false;
                @@Who_Is_Analyzed = "HY";
                ComputerMove(@@Skakiera);
            end



        end #end Enter_move


      def PawnPromotion()
            for i in 0..7 do
                if (@@Skakiera[(i), (0)].CompareTo("Black Pawn") == 0)
                    if (@@m_WhoPlays.CompareTo("Human") == 0)
                        #############/
                        # promote pawn
                        #############/

                        Console.WriteLine("");

                        Console.WriteLine("Promote your pawn to: 1. Queen, 2. Rook, 3. Knight, 4. Bishop");
                        Console.Write("CHOOSE (1-4): ");
                        @@choise_of_user = Console.ReadLine.to_i

                        case (@@choise_of_user)
                            when 1
                              @@Skakiera[(i), (0)] = "Black Queen";
                            when 2
                              @@Skakiera[(i), (0)] = "Black Rook";
                            when 3
                                @@Skakiera[(i), (0)] = "Black Knight";
                            when 4
                                @@Skakiera[(i), (0)] = "Black Bishop";
                        end #end case
                    end#end if (@@m_WhoPlays.CompareTo("Human") == 0)

                end #end if (@@Skakiera[(i), (0)]

                if (@@Skakiera[(i), (7)].CompareTo("White Pawn") == 0)
                    if (@@m_WhoPlays.CompareTo("Human") == 0)
                        #############/
                        # promote pawn
                        #############/

                        Console.WriteLine("");

                        Console.WriteLine("Promote your pawn to: 1. Queen, 2. Rook, 3. Knight, 4. Bishop");
                        Console.Write("CHOOSE (1-4): ");
                        @@choise_of_user = Console.ReadLine.to_i;

                        case (@@choise_of_user)
                          when 1
                            @@Skakiera[(i), (0)] = "White Queen";
                          when 2
                            @@Skakiera[(i), (0)] = "White Rook";
                          when 3
                            @@Skakiera[(i), (0)] = "White Knight";
                          when 4:
                            @@Skakiera[(i), (0)] = "White Bishop";
                        end #end case
                    end#end if (@@m_WhoPlays.CompareTo("Human") == 0)

              end#end if (@@Skakiera[(i), (7)].CompareTo("White Pawn") == 0)

            end #end for i
        end #end PawnPromotion


      def starting_position()
            for a in 0..7 do
                for b in 0..7 do
                    @@Skakiera[(a), (b)] = "";
                end
            end

            @@Skakiera[(0), (0)] = "White Rook";
            @@Skakiera[(0), (1)] = "White Pawn";
            @@Skakiera[(0), (6)] = "Black Pawn";
            @@Skakiera[(0), (7)] = "Black Rook";
            @@Skakiera[(1), (0)] = "White Knight";
            @@Skakiera[(1), (1)] = "White Pawn";
            @@Skakiera[(1), (6)] = "Black Pawn";
            @@Skakiera[(1), (7)] = "Black Knight";
            @@Skakiera[(2), (0)] = "White Bishop";
            @@Skakiera[(2), (1)] = "White Pawn";
            @@Skakiera[(2), (6)] = "Black Pawn";
            @@Skakiera[(2), (7)] = "Black Bishop";
            @@Skakiera[(3), (0)] = "White Queen";
            @@Skakiera[(3), (1)] = "White Pawn";
            @@Skakiera[(3), (6)] = "Black Pawn";
            @@Skakiera[(3), (7)] = "Black Queen";
            @@Skakiera[(4), (0)] = "White King";
            @@Skakiera[(4), (1)] = "White Pawn";
            @@Skakiera[(4), (6)] = "Black Pawn";
            @@Skakiera[(4), (7)] = "Black King";
            @@Skakiera[(5), (0)] = "White Bishop";
            @@Skakiera[(5), (1)] = "White Pawn";
            @@Skakiera[(5), (6)] = "Black Pawn";
            @@Skakiera[(5), (7)] = "Black Bishop";
            @@Skakiera[(6), (0)] = "White Knight";
            @@Skakiera[(6), (1)] = "White Pawn";
            @@Skakiera[(6), (6)] = "Black Pawn";
            @@Skakiera[(6), (7)] = "Black Knight";
            @@Skakiera[(7), (0)] = "White Rook";
            @@Skakiera[(7), (1)] = "White Pawn";
            @@Skakiera[(7), (6)] = "Black Pawn";
            @@Skakiera[(7), (7)] = "Black Rook";

            @@m_WhichColorPlays = "White";
        end #end Starting_position

        # 2009 version 1 change
      def HumanMove(skakiera_Human_Thinking)
            # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
            #if(huo_debug == true)
            #{
            #	Console.WriteLine("HumanMove called");
            #	Console.ReadKey();
            #}

            # 2009 version 1 change
            #if (@@First_Call_Human_Thought == true)
            #{
            #		# store initial chessboard position
            #		for (iii_Human = 0; iii_Human <= 7; iii_Human++)
            #		{
            #			for (jjj_Human = 0; jjj_Human <= 7; jjj_Human++)
            #			{
            #				skakiera_Human_Thinking[(iii_Human),(jjj_Human)] = Skakiera_Human_Thinking_init[(iii_Human),(jjj_Human)];
            #				Skakiera_Human_Move_0[(iii_Human),(jjj_Human)] = Skakiera_Human_Thinking_init[(iii_Human),(jjj_Human)];
            #			}
            #		}
            #}


            # scan chessboard . find a piece of the human player . move to all
            # possible squares . check correctness and legality of move . if
            # all ok then measure the move's score . do the best move and handle
            # over to the ComputerMove function to continue analysis in the next
            # move (deeper depth...)
            

            for www1 in 0..7 do
                for rrr1 in 0..7 do

                    if (((@@Who_Is_Analyzed.CompareTo("Human") == 0) && ((((skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black King") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black Queen") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black Rook") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black Knight") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black Bishop") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)) || (((skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White King") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White Queen") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White Rook") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White Knight") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White Bishop") == 0) || (skakiera_Human_Thinking[(www1), (rrr1)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)))))
                        for ww in 0..7 do 
                            for  rr in 0..7 do
                                #try{

                                # HUO DEBUG
                                # Να αλλάξω το FinishingColumn / Rank έτσι ώστε να παίρνει όλες τις τιμές (-7 έως +7)!
                                @@MovingPiece = skakiera_Human_Thinking[(www1), (rrr1)];
                                @@m_StartingColumnNumber = www1 + 1;
                                @@m_FinishingColumnNumber = ww + 1; #www1+ww;
                                @@m_StartingRank = rrr1 + 1;
                                @@m_FinishingRank = rr + 1; # rrr1+rr;

                                # HUO DEBUG
                                #if((@@m_StartingColumnNumber == 4) && (@@m_StartingRank == 7))
                                #{
                                #	if((@@m_FinishingColumnNumber == 1) && (@@m_FinishingRank == 4))
                                #	{
                                #		Console.WriteLine("test ok!");
                                #	}
                                #}

                                # check the move
                                CheckHumanMove(skakiera_Human_Thinking);
                                # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
                                #if(huo_debug == true)
                                #{
                                #	Console.WriteLine("RETURNED TO HumanMove");
                                #	Console.ReadKey();
                                #}
                            end#end for rr
                        end#end for ww
                    end#end if (((@@Who_Is_Analyzed.CompareTo("Human") == 0)

                end#end for rrr1
            end#end for www1

            # perform the best move of human opponent
            @@MovingPiece = skakiera_Human_Thinking[(@@Best_Move_Human_StartingColumnNumber - 1), (@@Best_Move_Human_StartingRank - 1)];
            skakiera_Human_Thinking[(@@Best_Move_Human_StartingColumnNumber - 1), (@@Best_Move_Human_StartingRank - 1)] = "";
            skakiera_Human_Thinking[(@@Best_Move_Human_FinishingColumnNumber - 1), (@@Best_Move_Human_FinishingRank - 1)] = @@MovingPiece;

            # call ComputerMove for the HY throught process to continue
            @@Move_Analyzed = @@Move_Analyzed + 1;

            @@Who_Is_Analyzed = "HY";

            for i in 0..7 do
                for j in 0..7 do
                    @@Skakiera_Move_After[(i), (j)] = skakiera_Human_Thinking[(i), (j)];
                end
            end

            #######################################
            # UNCOMMENT TO (TRY TO) USE THREADS...
            #######################################
            # Issues with threads: You must have a seperate ComputerMove function for each
            # level of thinking (that is why I have the ComputerMove2,4,6 and 8 functions).
            # If you try to have only one ComputerMove function and call it will the thread
            # calling code depicted below, you will end up calling a new ComputerMove function
            # every time you start a new thread, thus having the program not thinking! :)
            # HOWEVER, I have found out that the use of threads is not going to work after
            # all because each branch of thinking (e.g. for ThinkingDepth = 4: ComputerMove2,
            # HumanMove, ComputerMove4, HumanMove, found the best move for that variant, go
            # back to the loop of ComputerMove2, HumanMove, ComputerMove4, HumanMove, found
            # the best move for that variant etc) must be completed sequentially. If you
            # attempt to create a new thread each time the ComputerMove4 needs to be called,
            # then the computer will lose the proper order of thinking (which is controlled
            # by the ComputerMove4 "for" loop) and the program will not function correctly.
            ######################################/

            #if (@@Move_Analyzed == 2)
            #{
            #    HuoChess_main newChess = HuoChess_main.new;
            #    # Creating a Thread reference object in one line from a member method
            #    Thread thr2 = new Thread(new ParameterizedThreadStart(HuoChess_main.ComputerMove2));
            #    #HuoChess_main.ComputerMove2(@@Skakiera_Move_After);
            #    thr2.Start(@@Skakiera_Move_After);
            #    Console.WriteLine("New thread started (@@Move analyzed = 2)");
            #}
            #elsif (@@Move_Analyzed == 4)
            #{
            #    HuoChess_main newChess = HuoChess_main.new;
            #    # Creating a Thread reference object in one line from a member method
            #    Thread thr2 = new Thread(new ParameterizedThreadStart(HuoChess_main.ComputerMove2));
            #    #HuoChess_main.ComputerMove4(@@Skakiera_Move_After);
            #    thr2.Start(@@Skakiera_Move_After);
            #    Console.WriteLine("New thread started (@@Move analyzed = 4)");
            #}

            ##########/
            # 2009 v4 change
            ##########/
            # v0.82
            if (@@Move_Analyzed == 2)
                @@HuoChess_new_depth_2.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 4)
                @@HuoChess_new_depth_4.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 6)
                @@HuoChess_new_depth_6.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 8)
                @@HuoChess_new_depth_8.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 10)
                @@HuoChess_new_depth_10.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 12)
                @@HuoChess_new_depth_12.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 14)
                @@HuoChess_new_depth_14.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 16)
                @@HuoChess_new_depth_16.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 18)
                @@HuoChess_new_depth_18.ComputerMove_template(@@Skakiera_Move_After);
            elsif (@@Move_Analyzed == 20)
                @@HuoChess_new_depth_20.ComputerMove_template(@@Skakiera_Move_After);
            end
            # v0.82
            ##########/
            # 2009 v4 change
            ##########/

        end #end HumanMove


      def CheckHumanMove(cMSkakiera_Human_Thinking)
            @@number_of_moves_analysed += 1

            # Necessary values for variables for the ElegxosOrthotitas (check move correctness) and
            # ElegxosNomimotitas (check move legality) function to...function properly.
            @@m_WhoPlays = "Human";
            @@m_WrongColumn = false;
            @@MovingPiece = cMSkakiera_Human_Thinking[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)];

            @@m_OrthotitaKinisis = ElegxosOrthotitas(cMSkakiera_Human_Thinking);
            @@m_NomimotitaKinisis = ElegxosNomimotitas(cMSkakiera_Human_Thinking);

            # restore normal value of @@m_WhoPlays
            @@m_WhoPlays = "HY";

            # if all ok, then do the move and measure it
            if ((@@m_OrthotitaKinisis == true) && (@@m_NomimotitaKinisis == true))
                # HUO DEBUG
                # Added in version 0.5
                # If Human can eat the Queen of the computer, then the move has a penalty!
                #if(@@m_PlayerColor.CompareTo("White") == 0)
                #{
                #	if(cMSkakiera_Human_Thinking[(@@m_FinishingColumnNumber - 1),(@@m_FinishingRank - 1)].Equals("Black Queen") == true)
                #		LoseQueen_penalty = true;
                #}
                #elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                #{
                #	if(cMSkakiera_Human_Thinking[(@@m_FinishingColumnNumber - 1),(@@m_FinishingRank - 1)].Equals("White Queen") == true)
                #	{
                #		LoseQueen_penalty = true;
                #		Console.WriteLine("Found move that eats the queen!");
                #	}
                #}

                # HUO DEBUG
                #if((@@m_StartingColumnNumber == 4) && (@@m_StartingRank == 7))
                #{
                #	if((@@m_FinishingColumnNumber == 1) && (@@m_FinishingRank == 4))
                #	{
                #		int test;
                #		Console.WriteLine("test ok!");
                #	}
                #}

                # do the move
                @@ProsorinoKommati = cMSkakiera_Human_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)];
                cMSkakiera_Human_Thinking[(@@m_StartingColumnNumber - 1), (@@m_StartingRank - 1)] = "";
                cMSkakiera_Human_Thinking[(@@m_FinishingColumnNumber - 1), (@@m_FinishingRank - 1)] = @@MovingPiece;

                #################################/
                # is the king still under check? if yes, then we have mate!
                #################################/
                @@Possible_mate = false;

                if (@@Human_is_in_check == true)
                    @@WhiteKingCheck = CheckForWhiteCheck(cMSkakiera_Human_Thinking);
                    if ((@@m_PlayerColor.CompareTo("White") == 0) && (@@WhiteKingCheck == true))
                        @@Possible_mate = true;
                    end

                    @@BlackKingCheck = CheckForBlackCheck(cMSkakiera_Human_Thinking);
                    if ((@@m_PlayerColor.CompareTo("Black") == 0) && (@@BlackKingCheck == true))
                        @@Possible_mate = true;
                    end
                end


                # if this is the first time the function is called, then store
                # the move no matter how auful!
                if (@@First_Call_Human_Thought == true)
                    @@Best_Move_Human_StartingColumnNumber = @@m_StartingColumnNumber;
                    @@Best_Move_Human_FinishingColumnNumber = @@m_FinishingColumnNumber;
                    @@Best_Move_Human_StartingRank = @@m_StartingRank;
                    @@Best_Move_Human_FinishingRank = @@m_FinishingRank;

                    CountScore_Human(cMSkakiera_Human_Thinking);
                    @@Best_Human_Move_Score = @@Current_Human_Move_Score;

                    @@First_Call_Human_Thought = false;
                    @@Best_Human_Move_Found = true;
                end

                # record the move with the best score
                CountScore_Human(cMSkakiera_Human_Thinking);
                if (((@@m_PlayerColor.CompareTo("Black") == 0) && (@@Current_Human_Move_Score < @@Best_Human_Move_Score)) || ((@@m_PlayerColor.CompareTo("White") == 0) && (@@Current_Human_Move_Score > @@Best_Human_Move_Score)))
                    @@Best_Move_Human_StartingColumnNumber = @@m_StartingColumnNumber;
                    @@Best_Move_Human_FinishingColumnNumber = @@m_FinishingColumnNumber;
                    @@Best_Move_Human_StartingRank = @@m_StartingRank;
                    @@Best_Move_Human_FinishingRank = @@m_FinishingRank;
                    @@Best_Human_Move_Score = @@Current_Human_Move_Score;
                end

                ####################################
                # restore pieces in the initial position
                ####################################
                # 2009 version 1 change
                #for i in 0..7 do
                #{
                #	for j in 0..7 do
                #	{
                #		Skakiera_Human_Thinking[(i),(j)] = Skakiera_Human_Move_0[(i),(j)];
                #	}
                #}
            end #end if ((@@m_OrthotitaKinisis == true)

        end #end CheckHumanMove


        # HY Thought Process:
        # Depth 0 (@@Move_Analyzed = 0): First half move analyzed - First HY half move analyzed
        # Depth 1 (@@Move_Analyzed = 1): Second half move analyzed - First human half move analyzed
        # Depth 2 (@@Move_Analyzed = 2): Thirf half move analyzed - Second HY half move analyzed
        # etc

        # Functions for analyzing the HY Thought in depth...
        # ...of the 3rd half move (ComputerMove2)
        # ...of the 5th half move (ComputerMove4)
        # ...of the 7th half move (ComputerMove6)
        # ...of the 9th half move (ComputerMove8)


     def ComputerMove_template(skakiera_Thinking_template)
            # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
            #if(huo_debug == true)
            #{
            #	Console.WriteLine("ComputerMove_template called");
            #	Console.ReadKey();
            #}
            #################################
            # SEE RESPECTIVE ComputerMove function for english comments
            #################################

            # Θέτουμε την τιμή της @@mate σε false για να μην υπάρξει λανθασμένος συναγερμός για ματ.
            # Αν στη συνέχεια διαπιστωθεί ότι υπάρχει ματ (βλ. συνάρτηση CheckMove), τότε η τιμή της @@mate θα γίνει true.

            @@mate = false;

            # Δήλωση μεταβλητών που χρησιμοποιούνται στο βρόγχο "for"
            # (δεν μπορεί να χρησιμοποιηθούν οι μεταβλητές i και j διότι αυτές οι
            # μεταβλητές είναι καθολικές και δημιουργείται πρόβλημα κατά την
            # επιστροφή στην ComputerMove από την CheckMove

           

            # Έλεγχος του αν ο υπολογιστής έχει σκεφτεί όσο του έχει βάλει ο χρήστης να σκέφτεται (το σήμα " > " μπήκε διότι το πρόγραμμα αυξάνει την τιμή της @@Move_Analyzed ΠΡΙΝ αναλύσει την κίνηση - βλ. μετά)

            if (@@Move_Analyzed > @@Thinking_Depth)
                @@Stop_Analyzing = true;
            end


            if (@@Stop_Analyzing == false)
                for iii in 0..7 do
                    for jjj in 0..7 do
                        if (((@@Who_Is_Analyzed.CompareTo("HY") == 0) && ((((skakiera_Thinking_template[(iii), (jjj)].CompareTo("White King") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Queen") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Rook") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Knight") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Bishop") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)) || (((skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black King") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Queen") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Rook") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Knight") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Bishop") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)))) || ((@@Who_Is_Analyzed.CompareTo("Human") == 0) && ((((skakiera_Thinking_template[(iii), (jjj)].CompareTo("White King") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Queen") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Rook") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Knight") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Bishop") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("White Pawn") == 0)) && (@@m_PlayerColor.CompareTo("White") == 0)) || (((skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black King") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Queen") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Rook") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Knight") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Bishop") == 0) || (skakiera_Thinking_template[(iii), (jjj)].CompareTo("Black Pawn") == 0)) && (@@m_PlayerColor.CompareTo("Black") == 0)))))
                            for w in 0..7 do
                                for r in 0..7 do
                                    @@MovingPiece = skakiera_Thinking_template[(iii), (jjj)];
                                    @@m_StartingColumnNumber = iii + 1;
                                    @@m_FinishingColumnNumber = w + 1;
                                    @@m_StartingRank = jjj + 1;
                                    @@m_FinishingRank = r + 1;

                                    # Έλεγχος της κίνησης
                                    CheckMove(skakiera_Thinking_template);
                                    # UNCOMMENT TO SHOW INNER THINKING MECHANISM!
                                    #if(huo_debug == true)
                                    #{
                                    #	Console.WriteLine("RETURNED TO ComputerMove_template");
                                    #	Console.ReadKey();
                                    #}
                                end
                            end
                        end #end if (((@@Who_Is_Analyzed.CompareTo("HY") == 0)


                    end#end for jjj
                end#end for iii
            end#end if (@@Stop_Analyzing == false)


            if ((@@Move_Analyzed == 0) && ((@@WhiteKingCheck == true) || (@@BlackKingCheck == true)))
                if (@@Best_Move_Found == false)
                    @@mate = true;

                    if (@@m_PlayerColor.CompareTo("White") == 0)
                        Console.WriteLine("Black is in mate!");
                    elsif (@@m_PlayerColor.CompareTo("Black") == 0)
                        Console.WriteLine("White is in mate!");
                    end
                end

            end

            @@Move_Analyzed = @@Move_Analyzed - 2;
            @@Who_Is_Analyzed = "HY";

            # DEBUGGING CODE
            # Use only for solving application problems!
            #sw_hy_thought.WriteLine("--------------- MOVE ANALYZED REDUCED BY 2! ----------------");

            for i in 0..7 do
                for j in 0..7 do
                    @@Skakiera_Thinking[i, j] = @@Skakiera_Move_0[i, j];
                end
            end

        end #end ComputerMove_template
        
end #end class HuoChess_main


if $0 == __FILE__
  HuoChess_new_depth_2 = HuoChess_main.new;
  HuoChess_new_depth_4 = HuoChess_main.new;
  HuoChess_new_depth_6 = HuoChess_main.new;
  HuoChess_new_depth_8 = HuoChess_main.new;
  HuoChess_new_depth_10 = HuoChess_main.new;
  HuoChess_new_depth_12 = HuoChess_main.new;
  HuoChess_new_depth_14 = HuoChess_main.new;
  HuoChess_new_depth_16 = HuoChess_main.new;
  HuoChess_new_depth_18 = HuoChess_main.new;
  HuoChess_new_depth_20 = HuoChess_main.new;
  
  huo = HuoChess_main.new
  huo.set_huo_deph(HuoChess_new_depth_2,HuoChess_new_depth_4,HuoChess_new_depth_6,HuoChess_new_depth_8,
                    HuoChess_new_depth_10, HuoChess_new_depth_12, HuoChess_new_depth_14, HuoChess_new_depth_16, 
                    HuoChess_new_depth_18, HuoChess_new_depth_20)
  huo.DoGame
end

