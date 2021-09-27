require "./fen"
require "./game"
require "./player"
require "./terminal"
require "./term_board"
require "./pgn"
require "./change"

module LxChess
  # Represents a chess game played through the terminal
  class TermGame
    property gb : TermBoard
    getter log = [] of String
    property pgn : PGN = PGN.new
    property game : Game
    property term : Terminal = Terminal.new
    property changes = [] of Array(Change)

    def initialize(@pgn = PGN.new)
      @game = @pgn.game
      @fen = Fen.new(board: @game.board)
      @gb = TermBoard.new(@game.board)
      @changes = @pgn.changes
    end

    def initialize(@fen : Fen, players = [Player.new, Player.new])
      @game = Game.new(board: @fen.board, players: players)
      @game.set_fen_attributes(fen)
      @gb = TermBoard.new(@game.board)
    end

    def tick
      draw
      update
    end

    def update
      input = gets || ""

      case input
      when /help/i
        msg = <<-HELP
          Commands:
            flip - Flip the board
            moves [SQUARE] - Show the moves (optionally for a given square)
            [SAN] - Standard algebraic notation (make a move)
            [FROM] [TO] - specify move by coordinates
        HELP
        msg.lines.reverse.each { |l| @log.unshift(l) }
      when /flip/i
        @gb.flip!
      when /(undo|back)/i
        if last_change = @changes.pop?
          @game.undo(last_change)
          @pgn.history.pop
        end
      when /moves\s+([a-z]\d)/i
        if matches = input.match(/[a-z]\d/i)
          if square = matches[0]?
            if index = @game.board.index_of(square)
              if set = @game.moves(index)
                @gb.highlight(set.moves, "blue")
                from = "#{set.piece.fen_symbol}#{@game.board.cord(index)}: "
                to = set.moves.map { |m| @game.board.cord(m) }.join(", ")
                @log.unshift from + to
              end
            end
          end
        end
      when /moves/i
        pieces = @game.board.select do |piece|
          next if piece.nil?
          @game.turn == 0 ? piece.white? : piece.black?
        end

        move_sets = pieces.map do |piece|
          next unless piece
          if s = @game.moves(piece.index.as(Int16))
            @game.remove_illegal_moves(s)
          end
        end

        move_string = move_sets.map do |set|
          next unless set
          next if set.moves.empty?
          @gb.highlight(set.moves, "blue")
          from = "#{set.piece.fen_symbol}#{@game.board.cord(set.origin)}: "
          to = set.moves.map { |m| @game.board.cord(m) }.join(", ")
          from + to
        end.compact.join(" | ")
        @log.unshift move_string
      when /\s*([a-z]\d)\s*([a-z]\d)\s*(?:=\s*)?([RNBQ])?/i
        if input
          if matches = input.downcase.match(/\s*([a-z]\d)\s*([a-z]\d)\s*(?:=\s*)?([RNBQ])?/i)
            from = matches[1]
            to = matches[2]
            promo = if matches[3]?
                      matches[3][0]
                    end
            if from && to
              @gb.clear
              san = @game.move_to_san(from, to, promo)
              @changes << @game.make_move(from, to, promo)
              @pgn.history << san
              @gb.highlight([@game.board.index_of(from), @game.board.index_of(to)])
              @log.unshift "#{san.to_s}: #{from} => #{to}"
            end
          end
        end
      when nil
      else
        if input
          notation = Notation.new(input)
          from, to = @game.parse_san(notation)
          if from && to
            @gb.clear
            san = @game.move_to_san(from, to, notation.promotion)
            @changes << @game.make_move(from, to, notation.promotion)
            @pgn.history << san
            @gb.highlight([from.to_i16, to.to_i16])
            @log.unshift "#{san.to_s}: #{@game.board.cord(from)} => #{@game.board.cord(to)}"
          end
        end
      end

      @fen.update(@game)
    rescue e : LxChess::Notation::InvalidNotation | LxChess::Game::SanError | LxChess::Game::IllegalMove
      if msg = e.message
        @log.unshift msg
      end
    ensure
      until log.size < 8
        log.pop
      end
    end

    def draw
      draw_fen
      draw_board
      draw_pgn
      draw_log
      draw_prompt
    end

    def clear_screen
      @term.clear
      @term.clear_scroll
    end

    # ===================
    # = Drawing methods =
    # ===================

    private def draw_fen
      @term.move 0, 0
      print @fen.to_s
      @term.trunc
    end

    private def draw_board
      @term.move x: 0, y: 3
      @gb.draw
    end

    private def draw_pgn(height = 9, width = 18)
      base_offset_x = @game.board.width * 2 + 10
      @pgn.strings.each_with_index do |m, i|
        @term.move x: base_offset_x + ((i / height).to_i * width), y: 3 + (i % height)
        print m
        @term.trunc
      end
    end

    private def draw_log
      @term.move x: 0, y: @game.board.height + 7
      @log.each { |l| print l; @term.trunc; puts }
    end

    private def draw_prompt
      @term.move x: 0, y: @game.board.height + 5
      if @game.turn == 0
        print " #{@game.full_moves + 1}. "
      else
        print " #{@game.full_moves + 1}. ... "
      end
      @term.trunc
    end
  end
end
