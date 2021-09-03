require "./piece"

module LxChess
  class Board
    LETTERS = ('a'..'z').to_a

    property :width, :height, :squares

    def initialize(@width : Int = 8, @height : Int = 8)
      @squares = Array(Piece | Nil).new(@width * @height) { nil }
    end

    def [](index : Int)
      @squares[index]
    end

    def [](cord : String)
      @squares[cord_index(cord)]
    end

    def at(x : Int, y : Int)
      @squares[index(x, y)]
    end

    def []=(index : Int, value : Piece | Nil)
      @squares[index] = value
    end

    def []=(cord : String, value : Piece | Nil)
      @squares[cord_index(cord)] = value
    end

    def index(x : Int, y : Int)
      (y * @width) + x
    end

    def cord_index(cord : String)
      x = LETTERS.index(cord[0]) || 0
      y = cord[1].to_i - 1
      index(x, y)
    end
  end
end
