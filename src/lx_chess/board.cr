require "./piece"

module LxChess
  class Board
    include Enumerable(Piece | Nil)

    LETTERS = ('a'..'z').to_a

    property :width, :height, :squares

    def initialize(@width : Int16 = 8, @height : Int16 = 8)
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
    rescue e : IndexError
      nil
    end

    # Retrieve a piece at a human cord ex: `a1`
    def [](cord : String)
      self[index(cord)]
    end

    # Retrieve a piece at an *x* and *y* cord
    def at(x : Int, y : Int)
      self[index(x, y)]
    end

    def rel_index(index : Int, x : Int, y : Int)
      (index + (y * @width) + x).to_i16
    end

    # Set a piece on the board at a certain *index*
    def []=(index : Int, piece : Piece | Nil)
      piece.index = index.to_i16 if piece
      @squares[index] = piece
    end

    # Set a piece on the board at a certain human readable *cord*
    def []=(cord : String, piece : Piece | Nil)
      self[index(cord)] = piece
    end

    # Convert an *x* and *y* position into an index.
    # Ex: `4, 4` => `36`
    def index(x : Int, y : Int)
      ((y * @width) + x).to_i16
    end

    # Convert human *cord* into an index on the board.
    # Ex: `a1` => `0`
    def index(cord : String)
      x = LETTERS.index(cord[0].downcase) || 0
      y = cord[1].to_i - 1
      index(x, y)
    end

    # Convert an *index* into a human coordinate (ex: `a1`)
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

    # The rank of a given index
    # `rank(4) # => 0`
    # `rank(8) # => 1`
    def rank(index : Int16)
      rank, _ = index.divmod(@width)
      rank
    end

    # The file of a given index
    # `file(4) # => 4`
    # `file(8) # => 0`
    def file(index : Int16)
      _, file = index.divmod(@width)
      file
    end

    # Move a piece *from* a position *to* a new position
    def move(from : (String | Int16), to : (String | Int16))
      piece = self[from]
      self[from] = nil
      self[to] = piece
    end
  end
end
