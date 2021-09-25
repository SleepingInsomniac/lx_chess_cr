require "string_scanner"
require "./notation"
require "./game"
require "./player"

module LxChess
  class PGN
    TAG_REGEX  = /\[(?<key>[a-z]+)\s+(?<value>[^\]]+)\]/i
    MOVE_REGEX = /\d+\.+\s*(?<white>[^\s]+)\s*(\{[^\}]+\})?\s+(\d\.+)?\s*(?<black>[^\s]+)\s*(\{[^\}]+\})?/i

    property tags = {} of String => String
    property history = [] of Notation

    def initialize(pgn : String)
      scanner = StringScanner.new(pgn)

      while tag = scanner.scan_until(TAG_REGEX)
        tag.strip.match(TAG_REGEX).try do |match|
          @tags[match["key"]] = match["value"]
        end
      end

      fen_string = @tags["FEN"]? || "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      fen = Fen.parse(fen_string)
      game = Game.new(board: fen.board, players: [Player.new, Player.new])
      gb = TermBoard.new(game.board)

      while move = scanner.scan_until(MOVE_REGEX)
        move.strip.match(MOVE_REGEX).try do |match|
          [match["white"], match["black"]].each do |input|
            puts input
            notation = Notation.new(input)
            from, to = game.parse_san(notation)
            if from && to
              san = game.move_to_san(from, to, notation.promotion)
              game.make_move(from, to, notation.promotion)
              gb.draw
              puts
              puts
              @history << san
            end
          end
        end
      end
    end

    def initialize
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
