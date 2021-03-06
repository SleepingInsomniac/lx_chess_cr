require "./player"
require "./board"
require "./notation"
require "./move_set"
require "./error"
require "./fen"
require "./change"

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
    getter players : Array(Player)

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
      @move_clock = (fen.fullmove_counter - 1) * 2
      @move_clock += 1 if fen.turn == "b"
    end

    def en_passant_target=(cord : String)
      if cord =~ /[a-z]+\d+/
        @en_passant_target = @board.index_of(cord)
      else
        @en_passant_target = nil
      end
    end

    def current_player
      @players[@turn]
    end

    def en_passant_target=(cord : String)
      @en_passant_target = @board.index_of(cord)
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
      index = nil

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

      if square = notation.square
        index = @board.index_of(square)
      end

      raise "Missing index" unless index

      fen_symbol = notation.fen_symbol(@turn == 0 ? "w" : "b")

      move_sets = @board.map do |piece|
        next if piece.nil?
        next unless piece.fen_symbol == fen_symbol
        piece.index.try do |idx|
          moves(idx)
        end
      end.compact

      move_sets = move_sets.select do |set|
        set.moves.includes?(index)
      end

      move_sets = disambiguate_candidates(notation, move_sets)

      # If there is still more than 1 move_set, remove illegal moves
      # and select sets that still include the destination
      if move_sets.size > 1
        move_sets = move_sets.map do |set|
          remove_illegal_moves(set)
        end

        move_sets = move_sets.select do |set|
          set.moves.includes?(index)
        end
      end

      raise SanError.new("#{notation.to_s} is ambiguous") if move_sets.size > 1
      if set = move_sets.first?
        # from, to
        [set.piece.index, index]
      else
        raise SanError.new("no moves matching `#{notation.to_s}`")
      end
    end

    def move_to_san(from : String, to : String, promotion : Char? = nil, turn = @turn)
      move_to_san(@board.index_of(from), @board.index_of(to), promotion, turn)
    end

    def move_to_san(from : Int, to : Int, promotion : Char? = nil, turn = @turn)
      raise "No piece at #{@board.cord(from)}" unless piece = @board[from]
      en_passant = piece.pawn? && to == @en_passant_target

      check = tmp_move(from, to) do
        in_check?(next_turn(turn))
      end

      checkmate = check ? tmp_move(from, to) { checkmate?(next_turn(turn)) } : false

      castles_k = false
      castles_q = false

      if piece.king?
        dist = (to - from)
        if dist.abs == 2
          if dist.positive?
            castles_k = true
          else
            castles_q = true
          end
        end
      end

      candidate_move_sets = @board.select do |candidate|
        next unless candidate
        next if candidate == piece
        candidate.fen_symbol == piece.fen_symbol
      end.compact.map do |candidate|
        moves(candidate.index)
      end.compact.select do |move_set|
        move_set.moves.includes?(to)
      end

      origin = nil
      takes = en_passant || !@board[to].nil?

      if candidate_move_sets.any?
        origin ||= ""
        origin += @board.cord(from)[0]
      end

      if candidate_move_sets.any? { |set| @board.cord(set.piece.index)[0] == @board.cord(from)[0] }
        origin ||= ""
        origin += @board.cord(from)[1]
      end

      if origin.nil? && piece.pawn? && takes
        origin = @board.cord(from)[0].to_s
      end

      Notation.new(
        square: @board.cord(to),
        promotion: promotion,
        piece_abbr: piece.fen_symbol,
        from: @board.cord(from),
        to: @board.cord(to),
        takes: takes,
        en_passant: en_passant,
        check: check && !checkmate,
        checkmate: checkmate,
        castles_k: castles_k,
        castles_q: castles_q,
        origin: origin
      )
    end

    # Attempt to reduce ambiguities in candidate moves
    def disambiguate_candidates(notation : Notation, move_sets : Array(MoveSet))
      return move_sets if move_sets.size <= 1
      case notation.origin
      when /[a-z]\d/
        raise "error" unless origin = notation.origin
        piece = @board[origin]
        move_sets.select { |s| s.piece == piece }
      when /[a-z]/
        raise "error" unless origin = notation.origin
        file = Board::LETTERS.index(origin[0].downcase) || 0
        move_sets.select do |s|
          next unless s
          next unless index = s.piece.index
          @board.file(index) == file
        end
      when /\d/
        raise "error" unless origin = notation.origin
        rank = origin.to_i16 - 1
        move_sets.select do |s|
          next unless s
          next unless index = s.piece.index
          @board.rank(index) == rank
        end
      else
        move_sets
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

    # Removes moves that reveal check from a *MoveSet*
    # TODO: optimize this? Maybe don't generate illegal moves and stop early for sliding pieces
    def remove_illegal_moves(move_set : MoveSet)
      move_set.moves = move_set.moves.reject do |move|
        tmp_move(move_set.piece.index, move) do
          in_check?(move_set.piece.white? ? 0 : 1)
        end
      end
      move_set
    end

    def can_castle_king?(piece)
      return false if @players.empty?
      player = piece.white? ? @players[0] : @players[1]
      return false unless player.castle_king
      return false unless index = piece.index
      return false unless (index - @board.border_left(index)).abs >= 2
      @board[index + 1].nil? && @board[index + 2].nil?
    end

    def can_castle_queen?(piece)
      return false if @players.empty?
      player = piece.white? ? @players[0] : @players[1]
      return false unless player.castle_queen
      return false unless index = piece.index
      return false unless (index - @board.border_left(index)).abs >= 2
      @board[index - 1].nil? && @board[index - 2].nil?
    end

    def tmp_move(from : String, to : String, promotion : Char? = nil)
      tmp_move(@board.index_of(from), @board.index_of(to), promotion) do
        yield
      end
    end

    # Temporarily make a move
    def tmp_move(from : Int16, to : Int16, promotion : Char? = nil)
      from_piece = @board[from]
      to_piece = @board[to]
      @board[from] = nil
      if promotion
        @board[to] = Piece.from_fen(promotion)
      else
        @board[to] = from_piece
      end
      return_val = yield
    ensure
      @board[from] = from_piece
      @board[to] = to_piece
      return_val
    end

    def make_move(from : String, to : String, promotion : Char? = nil)
      make_move(from: @board.index_of(from), to: @board.index_of(to), promotion: promotion)
    end

    # Make a move given a set of coordinates
    def make_move(from : Int16, to : Int16, promotion : Char? = nil)
      raise IllegalMove.new("#{@board.cord(from)} is empty") unless piece = @board[from]
      if move_set = moves(from)
        raise IllegalMove.new("#{@board.cord(to)} is not available for #{@board.cord(from)}") unless move_set.moves.includes?(to)
      else
        raise IllegalMove.new("#{@board.cord(from)} has no moves")
      end

      # Test if the move will expose check
      tmp_move(from, to) do
        raise IllegalMove.new("Cannot move into check") if in_check?
      end

      changes = [] of Change

      # Castling
      if piece.king?
        dist = to - from
        current_player.no_castling!

        if dist.abs == 2
          raise IllegalMove.new("Cannot castle out of check") if in_check?

          if dist.positive?
            tmp_move(from, to - 1) do
              raise IllegalMove.new("Cannot castle through check") if in_check?
            end

            rook = @board.find do |p|
              p && p.color == piece.color && p.rook? && p.index.as(Int16) > piece.index.as(Int16)
            end
            if rook
              changes << Change.new(index: rook.index, from: rook, to: nil)
              changes << Change.new(index: to - 1, from: nil, to: rook)
              @board.move(from: rook.index, to: to - 1)
            end
          else
            tmp_move(from, to + 1) do
              raise IllegalMove.new("Cannot castle through check") if in_check?
            end

            rook = @board.find do |p|
              p && p.color == piece.color && p.rook? && p.index.as(Int16) < piece.index.as(Int16)
            end
            if rook
              changes << Change.new(index: rook.index, from: rook, to: nil)
              changes << Change.new(index: to + 1, from: nil, to: rook)
              @board.move(from: rook.index, to: to + 1)
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
          # Double pawn push, set en passant target
          @en_passant_target = distance > 0 ? to + @board.width : to - @board.width
        else
          if to == @en_passant_target
            capture = distance > 0 ? to + @board.width : to - @board.width
            changes << Change.new(index: capture, from: @board[capture], to: nil)
            @board[capture] = nil
          end
          @en_passant_target = nil
        end
      else
        @en_passant_target = nil
      end

      # Promotion
      if piece.pawn?
        rank = @board.rank(to)
        if rank == 0 || rank == @board.height - 1
          if promotion
            raise IllegalMove.new("Cannot promote to #{promotion}") unless "RNBQ".chars.includes?(promotion.upcase)
            promotion = piece.white? ? promotion.upcase : promotion.downcase
            promo_piece = Piece.from_fen(promotion)
            changes << Change.new(index: from, from: @board[from], to: promo_piece)
            @board[from] = promo_piece
          else
            raise IllegalMove.new("Pawns must promote on the last rank")
          end
        elsif promotion
          raise IllegalMove.new("Cannot promote on #{@board.cord(to)}")
        end
      end

      changes << Change.new(index: from, from: @board[from], to: nil)
      changes << Change.new(index: to, from: @board[to], to: @board[from])
      @board.move(from, to)

      next_turn!
      changes
    end

    # Undo a move
    def undo(changes : Array(Change))
      changes.each do |change|
        @board[change.index] = change.from
      end
      @turn = @turn - 1
      @turn = (@players.size - 1).to_i8 if @turn < 0
      @move_clock -= 1
    end

    # Return the pieces for a specified player
    def pieces_for(turn = @turn)
      color = turn == 0 ? :black : :white
      @board.select do |square|
        square.try { |piece| piece.color != color }
      end.compact
    end

    def in_check?(turn = @turn)
      return false unless king = find_king(turn)
      in_check = false
      moves = pieces_for(next_turn(turn)).each do |piece|
        moves(piece.index).try do |move_set|
          if move_set.moves.includes?(king.index)
            in_check = true
            break
          end
        end
      end

      in_check
    end

    # TODO: Optimize
    # Make every move and test for check, if any move results in check=false,
    # stop checking and return false
    def checkmate?(turn = @turn)
      return false unless king = find_king(turn)

      checkmate = true

      pieces_for(turn).each do |piece|
        moves(piece.index).try do |move_set|
          move_set.moves.each do |move|
            tmp_move(move_set.piece.index, move) do
              checkmate = in_check?(turn)
            end
            break unless checkmate
          end
        end
        break unless checkmate
      end

      checkmate
    end

    # Increment the turn index
    def next_turn!
      @turn = next_turn
      @move_clock += 1
    end

    # Get the next turn index
    def next_turn(turn = @turn)
      return 0.to_i8 if @players.size == 0
      (turn + 1) % @players.size
    end
  end
end
