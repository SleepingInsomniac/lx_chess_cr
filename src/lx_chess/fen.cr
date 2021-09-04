require "./board"
require "./piece"

module LxChess
  class Fen
    class Error < Exception
    end

    def self.parse(fen : String)
      raise "Invalid FEN" unless fen =~ /[rnbqkp\d\/]+\s+[a-z]+\s[a-z\-]+\s+[a-z\-]+\s\d+\s\d+/i
      placement, turn, castling, en_passant, halfmove_clock, fullmove_counter = fen.split(/\s+/)

      board = self.parse_placement(placement)

      Fen.new(
        board: board,
        turn: turn,
        castling: castling,
        en_passant: en_passant,
        halfmove_clock: halfmove_clock.to_i16,
        fullmove_counter: fullmove_counter.to_i16
      )
    end

    def self.parse_placement(placement)
      ranks = placement.split('/')
      width = ranks.first.size
      height = ranks.size
      rank = height - 1

      board = Board.new(width, height)
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

    property board : Board
    property turn : String
    property castling : String
    property en_passant : String
    property halfmove_clock : Int16
    property fullmove_counter : Int16

    def initialize(
      @board : Board,
      @turn : String,
      @castling : String,
      @en_passant : String,
      @halfmove_clock : Int16,
      @fullmove_counter : Int16
    )
    end
  end
end
