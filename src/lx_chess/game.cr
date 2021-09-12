require "./player"
require "./board"
require "./notation"
require "./move_set"
require "./error"

module LxChess
  class Game
    class SanError < Error; end

    property turn : Int8, board : Board
    property move_clock : Int16

    def initialize(@board : Board = Board.new, @players = [] of Player)
      @turn = 0
      @move_clock = 0
    end

    def next_turn
      @turn = (@turn == 0 ? 1 : 0).to_i8
      @move_clock += 1
    end

    def full_moves
      (@move_clock / 2).to_i16
    end

    # Parse standard algebraic notation
    def parse_san(notation : Notation)
      index = @board.index(notation.square)
      fen_symbol = notation.fen_symbol(@turn == 0 ? "w" : "b")
      pieces = @board.select do |piece|
        next if piece.nil?
        next unless piece.fen_symbol == fen_symbol
        if move_set = moves(piece.index.as(Int16))
          move_set.moves.includes?(index)
        end
      end

      if pieces.size > 1
        pieces = disambiguate_candidates(notation, pieces)
      end
      raise SanError.new("#{notation.to_s} is ambiguous") if pieces.size > 1
      if piece = pieces.first?
        # from, to
        [piece.index, index]
      else
        raise SanError.new("#{notation.to_s} is an illegal move")
      end
    end

    # Attempt to reduce ambiguities in candidate moves
    def disambiguate_candidates(notation : Notation, pieces : Array(Piece | Nil))
      return pieces unless origin = notation.origin
      case origin
      when /[a-z]\d/
        piece = @board[origin]
        pieces.select { |c| c == piece }
      when /[a-z]/
        file = Board::LETTERS.index(origin[0].downcase) || 0
        pieces.select do |c|
          next unless c
          next unless index = c.index
          @board.file(index) == file
        end
      when /\d/
        rank = origin.to_i16
        pieces.select do |c|
          next unless c
          next unless index = c.index
          @board.rank(index) == rank
        end
      else
        pieces
      end
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
          set.add_vector(x: -1, y: 1, limit: 1) if @board.from(index, x: -1, y: 1)
          set.add_vector(x: 1, y: 1, limit: 1) if @board.from(index, x: 1, y: 1)
        when 'p' # Black pawn
          set.add_vector(x: 0, y: -1, limit: (@board.rank(index) == @board.height - 2 ? 2 : 1).to_i16)
          set.add_vector(x: -1, y: -1, limit: 1) if @board.from(index, x: -1, y: -1)
          set.add_vector(x: 1, y: -1, limit: 1) if @board.from(index, x: 1, y: -1)
        when 'B', 'b' # Bishop
          set.add_vector(x: -1, y: 1, limit: 8)
          set.add_vector(x: 1, y: 1, limit: 8)
          set.add_vector(x: 1, y: -1, limit: 8)
          set.add_vector(x: -1, y: -1, limit: 8)
        when 'R', 'r' # Rook
          set.add_vector(x: -1, y: 0, limit: 8)
          set.add_vector(x: 0, y: 1, limit: 8)
          set.add_vector(x: 1, y: 0, limit: 8)
          set.add_vector(x: 0, y: -1, limit: 8)
        when 'Q', 'q' # Queen
          set.add_vector(x: -1, y: 1, limit: 8)
          set.add_vector(x: 1, y: 1, limit: 8)
          set.add_vector(x: 1, y: -1, limit: 8)
          set.add_vector(x: -1, y: -1, limit: 8)
          set.add_vector(x: -1, y: 0, limit: 8)
          set.add_vector(x: 0, y: 1, limit: 8)
          set.add_vector(x: 1, y: 0, limit: 8)
          set.add_vector(x: 0, y: -1, limit: 8)
        when 'N', 'n' # Knight
          set.add_offsets([
            {x: -2, y: 1}, {x: -1, y: 2},   # up left
            {x: 1, y: 2}, {x: 2, y: 1},     # up right
            {x: 2, y: -1}, {x: 1, y: -2},   # down right
            {x: -1, y: -2}, {x: -2, y: -1}, # down left
          ])
        when 'K', 'k' # King
          set.add_offsets([
            {x: -1, y: 0},  # left
            {x: -1, y: 1},  # left up
            {x: 0, y: 1},   # up
            {x: 1, y: 1},   # up right
            {x: 1, y: 0},   # right
            {x: 1, y: -1},  # down right
            {x: 0, y: -1},  # down
            {x: -1, y: -1}, # down left
          ])
        end
        set
      end
    end
  end
end
