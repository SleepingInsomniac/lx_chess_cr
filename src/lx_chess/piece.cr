module LxChess
  class Piece
    NAMES       = ["Pawn", "King", "Queen", "Rook", "Bishop", "Knight"]
    SYMBOLS     = "♙♔♕♖♗♘--♟♚♛♜♝♞"
    FEN_SYMBOLS = "PKQRBN--pkqrbn"

    PAWN   = 0
    KING   = 1
    QUEEN  = 2
    ROOK   = 3
    BISHOP = 4
    KNIGHT = 5

    def self.from_fen(fen : Char)
      id = FEN_SYMBOLS.index(fen).as(Int32).to_i8
      Piece.new(id)
    end

    property index : (Nil | Int16)

    def initialize(@id : Int8 = 0)
    end

    def white?
      @id & 0b1000 == 0
    end

    def black?
      @id & 0b1000 == 0b1000
    end

    def color
      white? ? :white : :black
    end

    def name
      NAMES[@id & 0b1000]
    end

    def symbol(force_black = false)
      if force_black
        SYMBOLS[@id | 0b1000]
      else
        SYMBOLS[@id]
      end
    end

    def fen_symbol
      FEN_SYMBOLS[@id]
    end

    def pawn?
      @id & 0b0111 == PAWN
    end

    def king?
      @id & 0b0111 == KING
    end

    def rook?
      @id & 0b0111 == ROOK
    end
  end
end
