require "./board"
require "./piece"
require "./error"
require "./player"

module LxChess
  # Forsyth-Edwards Notation parser and converter
  class Fen
    class InvalidFen < Error; end

    FEN_REGEX = %r{
      (?<placement>(?:[PKQRBN\d\/]+)+)\s+
      (?<turn>[a-z])\s+
      (?<castling>[a-z\-]+)\s+
      (?<en_passant>[a-z\d\-]+)\s+
      (?<half_clock>\d+)\s+
      (?<full_clock>\d+)
    }xi
    STANDARD = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    def self.parse(fen : String)
      raise InvalidFen.new("#{fen} is not valid") unless fen =~ FEN_REGEX
      placement, turn, castling, en_passant, halfmove_clock, fullmove_counter = fen.split(/\s+/)

      board = self.parse_placement(placement)

      Fen.new(
        board: board,
        turn: turn,
        castling: castling,
        en_passant: en_passant,
        halfmove_clock: halfmove_clock.to_i8,
        fullmove_counter: fullmove_counter.to_i16
      )
    end

    def self.parse_placement(placement)
      ranks = placement.split('/')
      width = ranks.reduce(0) do |max, rank|
        w = rank.chars.map { |s| s.number? ? s.to_i : 1 }.reduce(0) { |t, n| t + n }
        w > max ? w : max
      end
      height = ranks.size
      rank = height - 1

      board = Board.new(width.to_i16, height.to_i16)
      ranks.map { |r| r.chars }.each do |pieces|
        file = 0

        pieces.each do |symbol|
          case symbol
          when .in_set? "PKQRBNpkqrbn"
            piece = Piece.from_fen(symbol)
            index = rank * width + file
            board[index] = piece
            file += 1
          when .number?
            file += symbol.to_i
          else
            raise "#{symbol} is not a valid fen symbol"
          end
        end

        rank -= 1
      end
      board
    end

    def self.standard
      self.parse "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    end

    property board : Board
    property turn : String
    property castling : String
    property en_passant : String
    property halfmove_clock : Int8
    property fullmove_counter : Int16

    def initialize(
      @board,
      @turn = "w",
      @castling = "KQkq",
      @en_passant = "-",
      @halfmove_clock : Int8 = 0,
      @fullmove_counter : Int16 = 1
    )
    end

    def update(game : Game)
      if index = game.en_passant_target
        @en_passant = @board.cord(index)
      else
        @en_passant = "-"
      end

      @turn = game.turn == 0 ? "w" : "b"
      @castling = game.castling
      @halfmove_clock = game.fifty_move_rule
      @fullmove_counter = game.full_moves + 1
    end

    def placement
      rows = @board.map { |piece| piece ? piece.fen_symbol : nil }
        .each_slice(@board.width)
        .map { |row| row.chunks { |r| r.nil? }.map { |chunked, values| chunked ? values.size : values.join }.join }
        .to_a.reverse.join('/')
    end

    def to_s
      [placement, @turn, @castling, @en_passant, @halfmove_clock, @fullmove_counter].join(' ')
    end
  end
end
