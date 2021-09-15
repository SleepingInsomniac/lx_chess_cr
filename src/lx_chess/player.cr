module LxChess
  class Player
    property castle_left : Bool = true
    property castle_right : Bool = true

    def no_castling!
      @castle_right = false
      @castle_left = false
    end
  end
end
