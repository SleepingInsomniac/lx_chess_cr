require "./player"
require "./board"
require "./notation"

module LxChess
  class Game
    property turn : Int8, board : Board

    def initialize(@board : Board, @players = [] of Player)
      @turn = 0
    end

    # TODO
    def parse_san(notation : Notation)
      raise "Not implemented yet"
    end

    # Generate the psuedo-legal moves for a given *square*
    # TODO: Create move class, add captures, add en passant, add boundaries, remove illegal moves
    def moves(square : (String | Int))
      moves = [] of Int16
      if piece = @board[square]
        raise "Expected piece at #{square} to have an index, but it was nil" unless piece.index
        index = piece.index.as(Int16)
        case piece.fen_symbol
        when 'P' # White pawn
          square_up = index + @board.width
          if @board[square_up].nil?
            moves.push(square_up)
            if @board.rank(index) == 1
              square_up_up = square_up + @board.width
              moves.push(square_up_up) if @board[square_up_up].nil?
            end
          end
        when 'p' # Black pawn
          square_up = index - @board.width
          if @board[square_up].nil?
            moves.push(square_up)
            if @board.rank(index) == @board.height - 2
              square_up_up = square_up - @board.width
              moves.push(square_up_up) if @board[square_up_up].nil?
            end
          end
        end
      end
      moves
    end
  end
end
