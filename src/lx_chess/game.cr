require "./player"
require "./board"
require "./notation"
require "./move_set"
require "./error"

module LxChess
  # Represents a standard game of Chess
  class Game
    class SanError < Error; end

    class IllegalMove < Error; end

    property turn : Int8 = 0
    property board : Board
    property move_clock : Int16 = 0
    property en_passant_target : Int16?
    property fifty_move_rule : Int8 = 0

    def initialize(@board : Board = Board.new, @players = [] of Player)
    end

    def en_passant_target=(cord : String)
      @en_passant_target = @board.index(cord)
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

      pieces = disambiguate_candidates(notation, pieces)
      raise SanError.new("#{notation.to_s} is ambiguous") if pieces.size > 1
      if piece = pieces.first?
        # from, to
        [piece.index.as(Int16), index.as(Int16)]
      else
        raise SanError.new("no moves for #{notation.to_s}")
      end
    end

    # TODO: add check, checkmate, etc.
    def move_to_san(from : Int, to : Int, promotion : String? = nil)
      raise "No piece at #{@board.cord(from)}" unless piece = @board[from]
      en_passant = piece.pawn? && to == @en_passant_target

      Notation.new(
        square: @board.cord(to),
        promotion: promotion,
        piece_abbr: piece.fen_symbol,
        from: @board.cord(from),
        to: @board.cord(to),
        takes: en_passant || !@board[to].nil?,
        en_passant: en_passant
      )
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
    # TODO: remove illegal moves
    def moves(square : (String | Int))
      if piece = @board[square]
        raise "Expected piece at #{square} to have an index, but it was nil" unless piece.index
        set = MoveSet.new(piece, @board)
        index = piece.index.as(Int16)
        case piece.fen_symbol
        when 'P' # White pawn
          set.add_vector(x: 0, y: 1, limit: (@board.rank(index) == 1 ? 2 : 1).to_i16)
          capture_left = @board.rel_index(index, x: -1, y: 1)
          capture_right = @board.rel_index(index, x: 1, y: 1)
          set.add_vector(x: -1, y: 1, limit: 1) if @board[capture_left] || capture_left == @en_passant_target
          set.add_vector(x: 1, y: 1, limit: 1) if @board[capture_right] || capture_right == @en_passant_target
        when 'p' # Black pawn
          set.add_vector(x: 0, y: -1, limit: (@board.rank(index) == @board.height - 2 ? 2 : 1).to_i16)
          capture_left = @board.rel_index(index, x: -1, y: -1)
          capture_right = @board.rel_index(index, x: 1, y: -1)
          set.add_vector(x: -1, y: -1, limit: 1) if @board[capture_left] || capture_left == @en_passant_target
          set.add_vector(x: 1, y: -1, limit: 1) if @board[capture_right] || capture_right == @en_passant_target
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

    def make_move(from : String, to : String, promotion : Char? = nil)
      make_move(from: @board.index(from), to: @board.index(to), promotion: promotion)
    end

    def make_move(from : Int16, to : Int16, promotion : Char? = nil)
      raise IllegalMove.new("#{@board.cord(from)} is empty") unless piece = @board[from]
      if move_set = moves(from)
        raise IllegalMove.new("#{@board.cord(to)} is not available for #{@board.cord(from)}") unless move_set.moves.includes?(to)
      else
        raise IllegalMove.new("#{@board.cord(from)} has no moves")
      end

      san = move_to_san(from, to, promotion)

      # Reset the 50 move rule for captures and pawn moves
      if piece.pawn? || !@board[to].nil?
        @fifty_move_rule = 0
      else
        @fifty_move_rule += 1
      end

      # En passant
      if piece.pawn?
        distance = from - to
        if distance.abs == @board.width * 2
          @en_passant_target = distance > 0 ? to + @board.width : to - @board.width
        elsif to == @en_passant_target
          capture = distance > 0 ? to + @board.width : to - @board.width
          @board[capture] = nil
        end
      end

      @board.move(from, to)
      next_turn
      san
    end

    def next_turn
      @turn += 1
      @turn = @turn % @players.size
      @move_clock += 1
    end
  end
end
