require "./lx_chess/version"
require "./lx_chess/board"
require "./lx_chess/terminal"
require "./lx_chess/term_board"
require "./lx_chess/game"
require "./lx_chess/fen"
require "./lx_chess/notation"

require "option_parser"

options = {} of String => String | Nil

OptionParser.parse do |parser|
  parser.banner = "Usage: lx_chess [fen]"

  parser.on("--fen=FEN", "use fen string for board") do |fen_string|
    options["fen_string"] = fen_string
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.on("-v", "--version", "show version information") do
    puts "lx_chess version #{LxChess::VERSION}"
    exit
  end

  parser.on("--board-theme=COLOR", "Set the board theme") do |color|
    options["theme"] = color
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

log = [] of String
fen = LxChess::Fen.parse(options["fen_string"]? || "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
player_white = LxChess::Player.new
player_black = LxChess::Player.new
game = LxChess::Game.new(board: fen.board, players: [player_white, player_black])
gb = LxChess::TermBoard.new(game.board)
if theme = options["theme"]?
  if LxChess::TermBoard::THEMES[theme]?
    gb.board_theme = theme
  else
    STDERR.puts "No theme #{theme}"
    exit 1
  end
end
term = LxChess::Terminal.new

term.clear
term.clear_scroll

loop do
  term.move 0, 0
  print fen.placement
  term.trunc
  puts
  puts
  gb.draw
  puts
  puts
  if game.turn == 0
    print " #{game.full_moves + 1}. "
  else
    print " #{game.full_moves + 1}. ... "
  end
  term.trunc
  input = gets
  case input
  when /moves\s+([a-z]\d)/i
    next unless input
    if matches = input.match(/[a-z]\d/i)
      if square = matches[0]?
        if index = game.board.index(square)
          if set = game.moves(index)
            gb.highlight(set.moves, "blue")
            from = "#{set.piece.fen_symbol}#{game.board.cord(index)}: "
            to = set.moves.map { |m| game.board.cord(m) }.join(", ")
            log.unshift from + to
          end
        end
      end
    end
  when /moves/i
    pieces = game.board.select do |piece|
      next if piece.nil?
      game.turn == 0 ? piece.white? : piece.black?
    end

    move_sets = pieces.map do |piece|
      next unless piece
      game.moves(piece.index.as(Int16))
    end

    move_string = move_sets.map do |set|
      next unless set
      next if set.moves.empty?
      gb.highlight(set.moves, "blue")
      from = "#{set.piece.fen_symbol}#{game.board.cord(set.origin)}: "
      to = set.moves.map { |m| game.board.cord(m) }.join(", ")
      from + to
    end.compact.join(" | ")
    log.unshift move_string
  when /\s*([a-z]\d)\s*([a-z]\d)\s*(?:=\s*)?([RNBQ])?/i
    if input
      if matches = input.downcase.match(/\s*([a-z]\d)\s*([a-z]\d)\s*(?:=\s*)?([RNBQ])?/i)
        from = matches[1]
        to = matches[2]
        promo = if matches[3]?
                  matches[3][0]
                end
        if from && to
          gb.clear
          san = game.make_move(from, to)
          gb.highlight([game.board.index(from), game.board.index(to)])
          log.unshift "#{san.to_s}: #{from} => #{to}"
        end
      end
    end
  when nil
  else
    if input
      notation = LxChess::Notation.new(input)
      from, to = game.parse_san(notation)
      if from && to
        gb.clear
        san = game.make_move(from, to)
        gb.highlight([from.to_i16, to.to_i16])
        log.unshift "#{san.to_s}: #{game.board.cord(from)} => #{game.board.cord(to)}"
      end
    end
  end
rescue e : LxChess::Notation::InvalidNotation | LxChess::Game::SanError | LxChess::Game::IllegalMove
  if msg = e.message
    log.unshift msg
  end
ensure
  puts
  log.each { |l| print l; term.trunc; puts }
  until log.size < 8
    log.pop
  end
end

# gb.flip!
# gb.draw
# puts
