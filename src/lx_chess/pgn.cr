require "string_scanner"
require "./notation"
require "./game"
require "./player"

module LxChess
  class PGN
    TAG_REGEX  = /\[(?<key>[a-z]+)\s+(?<value>[^\]]+)\]/i
    TURN_REGEX = /\d+\.+\s*/
    SAN_REGEX  = %r{
      ([A-Z])?             # piece
      ([a-z])?(\d)?        # disambiguation
      x?                   # takes
      ([a-z]\d|O-O(?:-O)?) # destination
      (\=\s*[A-Z])?        # promotion
      ([\+\#])?            # check/checkmate
      (\s*e\.?\s*p\.?)?    # en passant
    }x
    COMMENT_REGEX   = /\s*\{[^\}]+\}\s*/i
    VARIATION_REGEX = /\s*\([^\)]+\)\s*/i

    property tags = {} of String => String
    property history = [] of Notation
    property game : Game

    def initialize(pgn : String)
      scanner = StringScanner.new(pgn)

      while tag = scanner.scan_until(TAG_REGEX)
        tag.strip.match(TAG_REGEX).try do |match|
          @tags[match["key"]] = match["value"]
        end
      end

      fen_string = @tags["FEN"]? || "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      fen = Fen.parse(fen_string)
      @game = Game.new(board: fen.board, players: [Player.new, Player.new])
      moves = [] of String

      while turn = scanner.scan_until(TURN_REGEX)
        while san = scanner.scan(SAN_REGEX)
          scanner.scan(/[\?\!]+/) # some moves may have been evaluated as blunders, mistakes, etc.
          moves.push(san)
          while comment = scanner.scan(COMMENT_REGEX); end
          while variation = scanner.scan(VARIATION_REGEX); end
          scanner.scan(/\s*/)
        end
      end

      moves.each do |move|
        notation = Notation.new(move)
        from, to = @game.parse_san(notation)
        if from && to
          san = @game.move_to_san(from, to, notation.promotion)
          @game.make_move(from, to, notation.promotion)
          @history << san
        end
      end
    end

    def initialize(@game = Game.new)
    end

    def strings
      history.each_slice(2).map_with_index do |moves, i|
        "#{i + 1}. #{moves.map { |m| m.to_s }.join(' ')}"
      end
    end

    def to_s
      strings.join(' ')
    end
  end
end
