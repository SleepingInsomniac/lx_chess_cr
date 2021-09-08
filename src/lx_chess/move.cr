require "./error"
require "./piece"
require "./notation"

module LxChess
  class Move
    class InvalidMove < Error; end

    property square : String?,
      castles_k : Bool,
      castles_q : Bool,
      en_passant : Bool,
      check : Bool,
      checkmate : Bool,
      takes : Bool,
      piece_abbr : String?,
      origin : String?,
      promotion : Char?,
      from : String?,
      to : String?

    def initialize(
      @square = nil,
      @castles_k = false,
      @castles_q = false,
      @en_passant = false,
      @check = false,
      @checkmate = false,
      @takes = false,
      @piece_abbr = nil,
      @origin = nil,
      @promotion = nil,
      @from = nil,
      @to = nil
    )
      @piece_abbr = "K" if @castles_q || @castles_k

      raise InvalidMove.new("Cannot castle and promote") if castles? && promotion
      raise InvalidMove.new("Cannot take while castling") if castles? && takes?
    end

    def en_passant?
      @en_passant
    end

    def castles_q?
      @castles_q
    end

    def castles_k?
      @castles_k
    end

    def castles?
      @castles_k || @castles_q
    end

    def en_passant?
      @en_passant
    end

    def check?
      @check
    end

    def checkmate?
      @checkmate
    end

    def takes?
      @takes
    end

    def piece_id(turn = "w")
      Piece.fen_id(fen_symbol(turn))
    end

    def fen_symbol(turn)
      pa = @piece_abbr || "p"
      turn == "w" ? pa.upcase : pa.downcase
    end

    def symbol
      Piece.symbol(piece_id)
    end

    def to_s
      buffer = IO::Memory.new

      buffer << case
      when castles_k?
        "O-O"
      when castles_q?
        "O-O-O"
      else
        @piece_abbr
      end

      if @en_passant
        if @from
          buffer << @from.as(String)[0]
        end
      else
        buffer << @origin if @origin
      end

      buffer << 'x' if @takes
      buffer << @square
      buffer << '+' if @check
      buffer << '#' if @checkmate
      buffer << " e.p." if @en_passant
      buffer << '=' << @promotion if @promotion
      buffer.to_s
    end
  end
end
