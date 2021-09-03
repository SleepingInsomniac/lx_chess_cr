require "./player"
require "./board"

module LxChess
  class Game
    property turn : Int8, board : Board

    def initialize(@board : Board, @players = [] of Player)
      @turn = 0
    end
  end
end
