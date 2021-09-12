require "./lx_chess/version"
require "./lx_chess/board"
require "./lx_chess/terminal"
require "./lx_chess/term_board"
require "./lx_chess/game"
require "./lx_chess/fen"
require "./lx_chess/notation"

require "option_parser"

options = {
  "fen_string" => "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
}

OptionParser.parse do |parser|
  parser.banner = "Usage: lx_chess [fen]"

  parser.on("--fen=FEN", "use fen string for board") do |fen_string|
    options["fen_string"] = fen_string
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

log = [] of String
fen = LxChess::Fen.parse(options["fen_string"])
game = LxChess::Game.new(board: fen.board)
gb = LxChess::TermBoard.new(game.board)
term = LxChess::Terminal.new

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
  if input
    notation = LxChess::Notation.new(input)
    from, to = game.parse_san(notation)
    if from && to
      gb.clear
      piece = game.board.move(from, to)
      game.next_turn
      gb.highlight([from.to_i16, to.to_i16])
      log.unshift "#{notation.to_s}: #{game.board.cord(from)} => #{game.board.cord(to)}"
    end
  end
rescue e : LxChess::Notation::InvalidNotation | LxChess::Game::SanError
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
