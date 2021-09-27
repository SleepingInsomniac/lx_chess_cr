require "./board"

module LxChess
  class Change
    property index : Int16
    property from : Piece?
    property to : Piece?

    def initialize(@index, @from, @to)
    end
  end
end
