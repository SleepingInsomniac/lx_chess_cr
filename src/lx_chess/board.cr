require "./piece"

module LxChess
  class Board
    include Enumerable(Piece | Nil)

    LETTERS = ('a'..'z').to_a

    property :width, :height, :squares

    def initialize(@width : Int = 8, @height : Int = 8)
      @squares = Array(Piece | Nil).new(@width * @height) { nil }
    end

    def each
      @squares.each { |piece| yield piece }
    end

    # Select pieces from the board by specifying an option *color*
    def pieces(color : (Nil | Symbol) = nil)
      self.select do |piece|
        if piece
          color ? piece.color == color : true
        else
          false
        end
      end
    end

    # Retrieve a piece at an index
    def [](index : Int)
      @squares[index]
    end

    # Retrieve a piece at a human cord ex: `A1`
    def [](cord : String)
      self[index(cord)]
    end

    # Retrieve a piece at an *x* and *y* cord
    def at(x : Int, y : Int)
      self[index(x, y)]
    end

    # Set a piece an the board at a certain *index*
    def []=(index : Int, piece : Piece | Nil)
      piece.index = index.to_i16
      @squares[index] = piece
    end

    # Set a piece an the board at a certain human readable *cord*
    def []=(cord : String, piece : Piece | Nil)
      self[index(cord)] = piece
    end

    # Convert an *x* and *y* position into an index.
    # Ex: `4, 4` => `36`
    def index(x : Int, y : Int)
      (y * @width) + x
    end

    # Convert human *cord* into an index on the board.
    # Ex: `A1` => `0`
    def index(cord : String)
      x = LETTERS.index(cord[0]) || 0
      y = cord[1].to_i - 1
      index(x, y)
    end

    def cord(index : Int)
      y, x = index.divmod(@width)
      "#{LETTERS[x]}#{y + 1}"
    end

    # Distance to the left border from an *index*
    def dist_left(index)
      _, dist_left = index.divmod(@width)
      dist_left
    end

    # Distance to the right border from an *index*
    def dist_right(index)
      _, dist_left = index.divmod(@width)
      (@width - dist_left) - 1
    end

    # Border to the left of a given *index*
    def border_left(index)
      rank, dist_left = index.divmod(@width)
      index - dist_left
    end

    # Border to the right of a given *index*
    def border_right(index)
      rank, dist_left = index.divmod(@width)
      index + (@width - dist_left) - 1
    end

    def rank(index)
      rank, _ = index.divmod(@width)
      rank
    end
  end
end
