require "./error"
require "./piece"

module LxChess
  class Notation
    class InvalidNotation < Error; end

    class InvalidMove < Error; end

    NOTATION_REGEX = %r{\A\s*
      (^[O0]-[O0])?\s*                           # 1.  castles kingside
      (^[O0]-[O0]-[O0])?\s*                      # 2.  castles queenside
      (^[RNBQKP](?!\d$))?\s*                     # 3.  piece abbreviation
      ((?:[a-z]|\d|[a-z]\d)(?=.*?[a-z]\d))?\s*   # 4.  origin square
      (x)?\s*                                    # 5.  takes
      ([a-z]\d)?\s*                              # 6.  destination square
      (\=\s*[RNBQ])?\s*                          # 7.  promotion
      (\+)?\s*                                   # 8.  check
      (\#)?\s*                                   # 9.  checkmate
      (e\.?p\.?)?\s*                             # 10. en passant
    \z}ix

    @match : Regex::MatchData?

    property square : String?,
      castles_k : Bool,
      castles_q : Bool,
      en_passant : Bool,
      check : Bool,
      checkmate : Bool,
      takes : Bool,
      piece_abbr : Char?,
      origin : String?,
      promotion : Char?,
      from : String?,
      to : String?

    def initialize(notation : String)
      unless match = notation.match(NOTATION_REGEX)
        raise InvalidNotation.new("Invalid notation.")
      end

      if _square = match[6]?
        @square = _square.downcase
      end

      @castles_k = match[1]? ? true : false
      @castles_q = match[2]? ? true : false
      @en_passant = match[10]? ? true : false
      @check = match[8]? ? true : false
      @checkmate = match[9]? ? true : false
      @takes = match[5]? ? true : false

      if _piece_abbr = match[3]?
        @piece_abbr = _piece_abbr[0].upcase
      end

      if _origin = match[4]?
        @origin = _origin.downcase
      end

      if _promo = match[7]?
        @promotion = _promo[-1].upcase
      end

      @from = nil
      @to = nil
      validate
    end

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
      validate
    end

    def validate
      raise InvalidMove.new("Cannot castle and promote") if castles? && promotion
      raise InvalidMove.new("Cannot capture while castling") if castles? && takes?
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
      pa = @piece_abbr || 'p'
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
