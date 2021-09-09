require "./player"
require "./board"
require "./notation"
require "./move_set"

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
    # TODO: Add captures, add en passant, add boundaries, remove illegal moves
    def moves(square : (String | Int))
      # moves = [] of Int16
      if piece = @board[square]
        raise "Expected piece at #{square} to have an index, but it was nil" unless piece.index
        set = MoveSet.new(piece, @board)
        index = piece.index.as(Int16)
        case piece.fen_symbol
        when 'P' # White pawn
          set.add_vector(x: 0, y: 1, limit: (@board.rank(index) == 1 ? 2 : 1).to_i16)
        when 'p' # Black pawn
          set.add_vector(x: 0, y: -1, limit: (@board.rank(index) == @board.height - 2 ? 2 : 1).to_i16)
        end
        set.moves
      end
    end
  end
end
