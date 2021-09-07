require "colorize"

module LxChess
  class TermBoard
    LETTERS = ('a'..'z').to_a

    property :bg_dark, :bg_light, :fg_dark, :fg_light

    def initialize(@board : Board)
      @flipped = false

      @bg_dark = :green
      @bg_light = :light_green
      @fg_dark = :black
      @fg_light = :white
    end

    def set_scheme(bg_dark : Symbol, bg_light : Symbol, fg_dark : Symbol, fg_light : Symbol)
      @bg_dark = bg_dark
      @bg_light = bg_light
      @fg_dark = fg_dark
      @fg_light = fg_light
    end

    def flip!
      @flipped = !@flipped
    end

    def width
      @board.width
    end

    def height
      @board.height
    end

    def ranks
      @flipped ? 0.upto(height - 1) : (height - 1).downto(0)
    end

    def files
      @flipped ? (width - 1).downto(0) : 0.upto(width - 1)
    end

    def draw(io = STDOUT)
      ranks.each do |y|
        io << (y + 1) << ": "

        files.each do |x|
          index = @board.index(x, y)
          piece = @board[index]

          background = (index + y) % 2 == 0 ? @bg_dark : @bg_light

          if piece
            foreground = piece.white? ? @fg_light : @fg_dark
            io << piece.symbol(true).colorize.back(background).fore(foreground) << " ".colorize.back(background)
          else
            io << "  ".colorize.back(background)
          end
        end

        io << "\n"
      end

      io << "   "

      files.each do |x|
        io << LETTERS[x] << " "
      end

      io
    end
  end
end
