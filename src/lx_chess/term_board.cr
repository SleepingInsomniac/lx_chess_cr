require "colorize"

module LxChess
  class TermBoard
    LETTERS = ('a'..'z').to_a

    property :bg_dark, :bg_light, :fg_dark, :fg_light

    def initialize(@board : Board)
      @flipped = false
      @highlights = {} of Int16 => Tuple(Symbol, Symbol)

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

    def highlight(indicies : Array(Int16), color = {:light_yellow, :yellow})
      indicies.each do |index|
        @highlights[index] = color
      end
    end

    def clear
      @highlights = {} of Int16 => Tuple(Symbol, Symbol)
    end

    def draw(io = STDOUT)
      ranks.each do |y|
        io << (y + 1) << ": "

        files.each do |x|
          index = @board.index(x, y)
          piece = @board[index]

          tint = (index + y) % 2 == 0 ? :light : :dark

          background =
            if @highlights[index]?
              @highlights[index][tint == :light ? 0 : 1]
            else
              tint == :light ? @bg_light : @bg_dark
            end

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
