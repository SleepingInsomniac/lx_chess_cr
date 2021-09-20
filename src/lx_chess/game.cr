require "./player"
require "./board"
require "./notation"
require "./move_set"
require "./error"
require "./pgn"
require "./fen"

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
    property pgn : PGN = PGN.new

    def initialize(@board : Board = Board.new, @players = [] of Player)
    end

    def castling
      io = IO::Memory.new
      @players.map_with_index do |p, i|
        io << (i == 0 ? 'K' : 'k') if p.castle_king
        io << (i == 0 ? 'Q' : 'q') if p.castle_queen
      end
      c_stirng = io.to_s
      c_stirng.size == 0 ? "-" : c_stirng
    end

    def castling=(string : String)
      chars = string.chars
      return false unless @players.size == 2
      player_white, player_black = @players
      player_white.castle_king = chars.includes?('k')
      player_white.castle_queen = chars.includes?('q')
      player_black.castle_king = chars.includes?('K')
      player_black.castle_queen = chars.includes?('Q')
    end

    def set_fen_attributes(fen : Fen)
      @turn = (fen.turn == "w" ? 0 : 1).to_i8
      castling = fen.castling
      en_passant_target = fen.en_passant
      @fifty_move_rule = fen.halfmove_clock
      @move_clock = fen.fullmove_counter * 2
      @move_clock += 1 if fen.turn == "b"
    end

    def en_passant_target=(cord : String)
      if cord =~ /[a-z]+\d+/
        @en_passant_target = @board.index(cord)
      else
        @en_passant_target = nil
      end
    end

    def current_player
      @players[@turn]
    end

    def en_passant_target=(cord : String)
      @en_passant_target = @board.index(cord)
    end

    def full_moves
      (@move_clock / 2).to_i16
    end

    # Find the king, optionally specifying *turn*
    def find_king(turn = @turn)
      @board.find do |piece|
        next unless piece
        piece.king? && (turn == 0 ? piece.white? : piece.black?)
      end
    end

    # Parse SAN from a string
    def parse_san(notation : String)
      parse_san(Notation.new(notation))
    end

    # Parse standard algebraic notation
    def parse_san(notation : Notation)
      index = @board.index(notation.square)

      if notation.castles?
        raise "expected to find a king, but couldn't!" unless king = find_king

        if king_index = king.index
          if notation.castles_k
            index = (king_index + 2)
          else
            index = (king_index - 2)
          end
        end

        if index
          notation.square = @board.cord(index)
        end
      end

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
        raise SanError.new("no pieces can move to #{notation.square}")
      end
    end

    # TODO: checkmate
    def move_to_san(from : Int, to : Int, promotion : String? = nil, turn = @turn)
      raise "No piece at #{@board.cord(from)}" unless piece = @board[from]
      en_passant = piece.pawn? && to == @en_passant_target

      check = tmp_move(from, to) do
        in_check?(turn)
      end

      Notation.new(
        square: @board.cord(to),
        promotion: promotion,
        piece_abbr: piece.fen_symbol,
        from: @board.cord(from),
        to: @board.cord(to),
        takes: en_passant || !@board[to].nil?,
        en_passant: en_passant,
        check: check
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
    def moves(square : (String | Int))
      if piece = @board[square]
        raise "Expected piece at #{square} to have an index, but it was nil" unless piece.index
        set = MoveSet.new(piece, @board)
        index = piece.index.as(Int16)
        case piece.fen_symbol
        when 'P' # White pawn
          set.add_vector(x: 0, y: 1, limit: (@board.rank(index) == 1 ? 2 : 1).to_i16, captures: false)
          capture_left = @board.rel_index(index, x: -1, y: 1)
          capture_right = @board.rel_index(index, x: 1, y: 1)
          set.add_vector(x: -1, y: 1, limit: 1) if @board[capture_left] || capture_left == @en_passant_target
          set.add_vector(x: 1, y: 1, limit: 1) if @board[capture_right] || capture_right == @en_passant_target
        when 'p' # Black pawn
          set.add_vector(x: 0, y: -1, limit: (@board.rank(index) == @board.height - 2 ? 2 : 1).to_i16, captures: false)
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
          # TODO: castling
          if can_castle_king?(piece)
            set.add_offset(x: 2, y: 0)
          end
          if can_castle_queen?(piece)
            set.add_offset(x: -2, y: 0)
          end
        end
        set
      end
    end

    def can_castle_king?(piece)
      return false if @players.empty?
      player = piece.white? ? @players[0] : @players[1]
      return false unless player.castle_king
      return false unless index = piece.index
      return false unless (index - @board.border_left(index)).abs >= 2
      # TODO: figure out if castling crosses checks
      @board[index + 1].nil? && @board[index + 2].nil?
    end

    def can_castle_queen?(piece)
      return false if @players.empty?
      player = piece.white? ? @players[0] : @players[1]
      return false unless player.castle_queen
      return false unless index = piece.index
      return false unless (index - @board.border_left(index)).abs >= 2
      # TODO: figure out if castling crosses checks
      @board[index - 1].nil? && @board[index - 2].nil?
    end

    # Temporarily make a move
    def tmp_move(from : Int16, to : Int16)
      from_piece = @board[from]
      to_piece = @board[to]
      @board[from] = nil
      @board[to] = from_piece
      return_val = yield
    ensure
      @board[from] = from_piece
      @board[to] = to_piece
      return_val
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

      # Test if the move will expose check
      tmp_move(from, to) do
        if in_check?
          raise IllegalMove.new("Cannot move into check")
        end
      end

      san = move_to_san(from, to, promotion, next_turn)

      # Castling
      if piece.king?
        dist = to - from
        current_player.no_castling!

        if dist.abs == 2
          if dist.positive?
            san.castles_k = true
            rook = @board.find do |p|
              p && p.color == piece.color && p.rook? && p.index.as(Int16) > piece.index.as(Int16)
            end
            if rook
              @board.move(from: rook.index.as(Int16), to: to - 1)
            end
          else
            san.castles_q = true
            rook = @board.find do |p|
              p && p.color == piece.color && p.rook? && p.index.as(Int16) < piece.index.as(Int16)
            end
            if rook
              @board.move(from: rook.index.as(Int16), to: to + 1)
            end
          end
        end
      end

      if piece.rook?
        king_index = find_king.try { |k| k.index } || 0
        piece_index = piece.index

        if piece_index > king_index
          current_player.castle_king = false
        else
          current_player.castle_queen = false
        end
      end

      if capture = @board[to]
        if capture.rook?
          king_index = find_king.try { |k| k.index } || 0
          capture_index = capture.index

          if capture_index > king_index
            current_player.castle_king = false
          else
            current_player.castle_queen = false
          end
        end
      end

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
        else
          if to == @en_passant_target
            capture = distance > 0 ? to + @board.width : to - @board.width
            @board[capture] = nil
          end

          @en_passant_target = nil
        end
      else
        @en_passant_target = nil
      end

      @board.move(from, to)
      next_turn!
      @pgn.history << san
      san
    end

    def in_check?(turn = @turn)
      if king = find_king(turn)
        opponent_pieces = @board.select do |square|
          square.try do |piece|
            piece.color != king.color
          end
        end

        in_check = false
        moves = opponent_pieces.each do |piece|
          piece.try do |piece|
            moves(piece.index).try do |move_set|
              if move_set.moves.includes?(king.index)
                in_check = true
                break
              end
            end
          end
        end

        in_check
      else
        false
      end
    end

    # Increment the turn index
    def next_turn!
      @turn = next_turn
      @move_clock += 1
    end

    # Get the next turn index
    def next_turn
      (@turn + 1) % @players.size
    end
  end
end
