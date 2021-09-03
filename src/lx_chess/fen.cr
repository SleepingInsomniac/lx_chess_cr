require "./board"
require "./piece"

module LxChess
  class Fen
    def self.parse(fen : String)
      placement, turn, castling, en_passant, halfmove_clock, fullmove_counter = fen.split(/\s+/)

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

      Fen.new(board: board)
    end

    property board : Board

    def initialize(
      @board : Board
      # @turn : Int,
      # @castling : String,
      # @en_passant : String,
      # @halfmove_clock : Int,
      # @fullmove_counter : Int
    )
    end
  end
end
