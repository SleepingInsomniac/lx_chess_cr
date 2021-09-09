require "./piece"
require "./board"

module LxChess
  class MoveSet
    property moves : Array(Int16)
    property piece : Piece
    property board : Board

    def initialize(@piece, @board)
      @moves = [] of Int16
    end

    def add_vector(x : Int16, y : Int16, limit : Int16)
      offset = y * @board.width + x
      location = @piece.index.as(Int16)
      limit.times do
        location = location + offset
        if capture = @board[location]
          unless capture.color == @piece.color
            @moves.push(location)
          end
          break
        end
        @moves.push(location)
      end
    end
  end
end
