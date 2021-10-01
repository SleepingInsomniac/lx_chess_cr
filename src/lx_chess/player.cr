module LxChess
  class Player
    property castle_king : Bool = true
    property castle_queen : Bool = true

    def ai?
      false
    end

    def get_move(game)
    end

    def no_castling!
      @castle_king = false
      @castle_queen = false
    end
  end
end
