require "./error"
require "./piece"
require "./board"

module LxChess
  # Parses Standard Algebraic Notation
  # ex: `Pbxc8=Q` pawn on the b file takes c8 and promotes to Queen
  class Notation
    class InvalidNotation < Error; end

    class InvalidMove < Error; end

    NOTATION_REGEX = %r{
      \A\s*
      (?<castle_k>   ^[Oo0]-[Oo0]                                 )?\s*
      (?<castle_q>   ^[Oo0]-[Oo0]-[Oo0]                           )?\s*
      (?<piece_abbr> ^[RNBQKP](?!\d$)                             )?\s*
      (?<origin>     (?:[a-wyz]|\d+|[a-z]\d+)(?=\s*x?\s*[a-z]\d+) )?\s*
      (?<takes>      x                                            )?\s*
      (?<dest>       [a-z]\d+                                     )?\s*
      (?<promo>      \=\s*[RNBQrnbq]                              )?\s*
      (?<check>      \+                                           )?\s*
      (?<checkmate>  \#                                           )?\s*
      (?<en_passent> e\.?p\.?                                     )?\s*
      \z
    }x

    @match : Regex::MatchData?

    property square : String?
    property castles_k : Bool
    property castles_q : Bool
    property en_passant : Bool
    property check : Bool
    property checkmate : Bool
    property takes : Bool
    getter piece_abbr : Char?
    property origin : String?
    property promotion : Char?
    property from : String?
    property to : String?

    def initialize(notation : String)
      unless match = notation.match(NOTATION_REGEX)
        raise InvalidNotation.new("Invalid notation.")
      end

      if _square = match[6]?
        @square = _square.downcase
      end

      @castles_k = match["castle_k"]? ? true : false
      @castles_q = match["castle_q"]? ? true : false
      @en_passant = match["en_passant"]? ? true : false
      @check = match["check"]? ? true : false
      @checkmate = match["checkmate"]? ? true : false
      @takes = match["takes"]? ? true : false

      match["piece_abbr"]?.try do |abbr|
        @piece_abbr = abbr[0].upcase
      end

      match["origin"]?.try do |origin|
        @origin = origin.downcase
      end

      match["promo"]?.try do |promo|
        @promotion = promo[-1].upcase
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
      @piece_abbr = 'K' if @castles_q || @castles_k
      validate
    end

    def validate
      raise InvalidMove.new("Cannot castle and promote") if castles? && promotion
      raise InvalidMove.new("Cannot capture while castling") if castles? && takes?
    end

    def piece_abbr
      if abbr = @piece_abbr
        abbr.upcase
      end
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
      pa = (castles? ? 'k' : @piece_abbr) || 'p'
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
        piece_abbr unless piece_abbr == 'P'
      end

      if @en_passant
        if @from
          buffer << @from.as(String)[0]
        end
      else
        buffer << @origin if @origin
      end

      buffer << 'x' if @takes
      buffer << @square unless castles?
      buffer << '+' if @check
      buffer << '#' if @checkmate
      buffer << " e.p." if @en_passant
      buffer << '=' << @promotion if @promotion
      buffer.to_s
    end

    def to_h
      {
        "square"     => square,
        "castles_k"  => castles_k?,
        "castles_q"  => castles_q?,
        "en_passant" => en_passant?,
        "check"      => check?,
        "checkmate"  => checkmate?,
        "takes"      => takes?,
        "piece_abbr" => piece_abbr,
        "origin"     => origin,
        "promotion"  => promotion,
        "from"       => from,
        "to"         => to,
      }
    end
  end
end
