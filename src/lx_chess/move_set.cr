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

    def origin
      @piece.index.as(Int16)
    end

    def add_vector(x : Int16, y : Int16, limit : Int16, captures : Bool = true)
      dist_edge = @board.dist_left(origin) if x.negative?
      dist_edge = @board.dist_right(origin) if x.positive?
      limit = dist_edge if dist_edge && dist_edge < limit

      offset = y * @board.width + x
      step = offset
      limit.times do
        info = add_offset(offset, captures)
        offset += step
        break if info[:stop]
      end
    end

    def add_offsets(offsets : Array(NamedTuple(x: Int32, y: Int32)))
      offsets.each do |cord|
        # Check if the offset crosses the border
        next if cord[:x].negative? && origin + cord[:x] < @board.border_left(origin)
        next if cord[:x].positive? && origin + cord[:x] > @board.border_right(origin)
        offset = cord[:y] * @board.width + cord[:x]
        add_offset(offset.to_i16)
      end
    end

    def add_offset(x : Int16, y : Int16)
      add_offset(y * @board.width + x)
    end

    # Does not check for crossing border edges
    def add_offset(offset : Int16, captures : Bool = true)
      added = false; stop = false
      location = origin + offset
      if location < 0 || location >= @board.squares.size
        # Beyond top or bottom
        stop = true
      else
        if capture = @board[location]
          if captures && capture.color != @piece.color
            @moves.push(location)
            added = true
          end
          stop = true
        else
          @moves.push(location)
          added = true
        end
      end
      {added: added, stop: stop, location: location}
    end
  end
end
