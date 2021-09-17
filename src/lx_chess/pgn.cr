require "./notation"

module LxChess
  class PGN
    property history = [] of Notation

    def strings
      history.each_slice(2).map_with_index do |moves, i|
        "#{i + 1}. #{moves.map { |m| m.to_s }.join(' ')}"
      end
    end

    def to_s
      strings.join(' ')
    end
  end
end
