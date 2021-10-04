require "./board"

module LxChess
  class MoveTree
    alias Branch = Tuple(Int16, Int16, MoveTree)

    property branches = [] of Branch
    property score : Int32
    property parent : MoveTree? = nil

    getter best_branches = [] of Branch
    getter turn : Int8

    def initialize(@score, @turn)
    end

    def <<(other : Branch)
      from, to, tree = other
      tree.parent = self

      # a position is only as good as its outcomes
      @score = tree.score if @branches.empty?

      if tree.score > @score
        Log.debug { "Found better move: #{Board.cord(from)} => #{Board.cord(to)} : #{tree.score}, truncating best branches" }
        @score = tree.score
        @best_branches.truncate(0, 0)
      end

      if tree.score == @score
        @best_branches << other
      end

      @branches << other
    end
  end
end
