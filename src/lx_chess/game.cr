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

    # Parse standard algebraic notation
    def parse_san(notation : Notation)
      index = @board.index(notation.square)
      fen_symbol = notation.fen_symbol(@turn == 0 ? "w" : "b")
      pieces = @board.select { |piece| piece && piece.fen_symbol == fen_symbol }
      pieces = pieces.select { |piece| piece && moves(piece.index.as(Int16)).includes?(index) }

      raise "Ambiguous SAN" if pieces.size > 1
      raise "Illegal move" if pieces.size == 0
      piece = pieces.first

      # from, to
      [piece.as(Piece).index, index]
    end

    # Generate the psuedo-legal moves for a given *square*
    # TODO: add en passant, add boundaries, remove illegal moves
    def moves(square : (String | Int))
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
      else
        [] of Int16
      end
    end
  end
end
