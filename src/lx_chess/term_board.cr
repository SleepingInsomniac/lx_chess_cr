require "colorize"

module LxChess
  class TermBoard
    LETTERS = ('a'..'z').to_a

    THEMES = {
      "yellow"  => {light: :light_yellow, dark: :yellow},
      "blue"    => {light: :light_blue, dark: :blue},
      "green"   => {light: :light_green, dark: :green},
      "cyan"    => {light: :light_cyan, dark: :cyan},
      "red"     => {light: :light_red, dark: :red},
      "magenta" => {light: :light_magenta, dark: :magenta},
      "gray"    => {light: :light_gray, dark: :dark_gray},
    }

    property :bg_dark, :bg_light, :fg_dark, :fg_light

    property show_symbols : Bool = true
    property show_color : Bool = true
    property flipped : Bool = false

    def initialize(@board : Board)
      @highlights = {} of Int16 => String

      @bg_dark = :green
      @bg_light = :light_green
      @fg_dark = :black
      @fg_light = :white
    end

    def board_theme=(theme : String)
      @bg_dark = THEMES[theme][:dark]
      @bg_light = THEMES[theme][:light]
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

    def highlight(indicies : Array(Int16), theme : String = "yellow")
      indicies.each do |index|
        @highlights[index] = theme
      end
    end

    def clear
      @highlights = {} of Int16 => String
    end

    def draw(io = STDOUT)
      ranks.each do |y|
        io << (y + 1).to_s.rjust(3) << ": "

        files.each do |x|
          index = @board.index_of(x, y)
          piece = @board[index]

          tint =
            if width.odd?
              (index) % 2 == 0 ? :light : :dark
            else
              (index + y) % 2 == 0 ? :light : :dark
            end

          background =
            if @highlights[index]?
              THEMES[@highlights[index]][tint]
            else
              tint == :light ? @bg_light : @bg_dark
            end

          if piece
            foreground = piece.white? ? @fg_light : @fg_dark
            piece_string = (@show_symbols ? piece.symbol(true) : piece.fen_symbol) + " "
            if @show_color
              io << piece_string.colorize.back(background).fore(foreground)
            else
              io << piece_string
            end
          else
            if @show_color
              io << "  ".colorize.back(background)
            else
              io << "  "
            end
          end
        end

        io << "\n"
      end

      io << "     "

      files.each do |x|
        io << LETTERS[x] << " "
      end

      io
    end
  end
end
