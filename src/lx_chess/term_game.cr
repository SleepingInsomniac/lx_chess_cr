require "./fen"
require "./game"
require "./player"
require "./terminal"
require "./term_board"

module LxChess
  # Represents a chess game played through the terminal
  class TermGame
    property gb : TermBoard
    getter log

    def initialize(@fen : Fen, players = [Player.new, Player.new])
      @term = Terminal.new
      @game = Game.new(board: @fen.board, players: players)
      @game.set_fen_attributes(fen)
      @gb = TermBoard.new(@game.board)
      @log = [] of String
      clear_screen
    end

    def tick
      draw
      update
    end

    def update
      input = gets || ""

      case input
      when /moves\s+([a-z]\d)/i
        if matches = input.match(/[a-z]\d/i)
          if square = matches[0]?
            if index = @game.board.index(square)
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
          @game.moves(piece.index.as(Int16))
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
              san = @game.make_move(from, to, promo)
              @gb.highlight([@game.board.index(from), @game.board.index(to)])
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
            san = @game.make_move(from, to, notation.promotion)
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

    # ===================
    # = Drawing methods =
    # ===================

    private def clear_screen
      @term.clear
      @term.clear_scroll
    end

    private def draw_fen
      @term.move 0, 0
      print @fen.to_s
      @term.trunc
    end

    private def draw_board
      @term.move x: 0, y: 3
      @gb.draw
    end

    private def draw_pgn
      @game.pgn.strings.each_with_index do |m, i|
        @term.move @game.board.width * 2 + 10, y: 3 + i
        print m
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