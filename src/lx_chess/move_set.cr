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
      add_vector(y * @board.width + x, limit)
    end

    def add_vector(offset : Int16, limit : Int16)
      step = offset
      location = @piece.index.as(Int16)
      limit.times do
        info = add_offset(offset)
        offset += step
        break if info[:stop]
      end
    end

    def add_offsets(offsets : Array(NamedTuple(x: Int32, y: Int32)))
      offsets.each do |cord|
        offset = cord[:y] * @board.width + cord[:x]
        add_offset(offset.to_i16)
      end
    end

    def add_offsets(offsets : Array(Int16))
      offsets.each do |offset|
        add_offset(offset)
      end
    end

    def add_offset(x : Int16, y : Int16)
      add_offset(y * @board.width + x)
    end

    # TODO: Stop at the board edges
    def add_offset(offset : Int16)
      added = false; stop = false
      location = @piece.index.as(Int16) + offset
      if location < 0 || location >= @board.squares.size
        # Beyond top or bottom
        stop = true
      else
        if capture = @board[location]
          unless capture.color == @piece.color
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
