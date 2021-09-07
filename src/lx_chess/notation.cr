require "./error"

module LxChess
  class Notation
    class InvalidNotation < LxChess::Error; end

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

    getter notation : String
    @match : Regex::MatchData?

    def initialize(@notation)
      raise InvalidNotation.new("Notation cannot be blank") if @notation =~ /^\s*$/
      raise InvalidNotation.new("'#{notation}` is not valid notation") if @notation !~ NOTATION_REGEX
      @match = @notation.match(NOTATION_REGEX)
      raise InvalidNotation.new("Unable to determine destination") unless castles? || square
    end

    def castles?
      castles_k? || castles_q?
    end

    def castles_k?
      match? 1
    end

    def castles_q?
      match? 2
    end

    def piece_abbr
      if _piece_abbr = match 3
        _piece_abbr.upcase
      end
    end

    def origin
      if _origin = match 4
        _origin.downcase
      end
    end

    def takes?
      match? 5
    end

    def square
      if _square = match 6
        _square.downcase
      end
    end

    def promotion
      if _promo = match 7
        _promo[-1].upcase
      end
    end

    def check?
      match? 8
    end

    def checkmate?
      match? 9
    end

    def en_passant?
      match? 10
    end

    # ~~~~~~~~~~~~~~~~~~~

    def pawn?
      piece_abbr == 'P' || piece_abbr.nil?
    end

    # ~~~~~~~~~~~~~~~~~~~

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
      }
    end

    private def match?(n : Int)
      match(n) ? true : false
    end

    private def match(n : Int)
      return nil unless @match
      match = @match.as(Regex::MatchData)
      match[n]?
    end
  end
end
