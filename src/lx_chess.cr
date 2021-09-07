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

fen = LxChess::Fen.parse(options["fen_string"])
game = LxChess::Game.new(board: fen.board)
gb = LxChess::TermBoard.new(game.board)

gb.draw
puts

loop do
  print " > "
  input = gets
  if input
    puts input.chomp
    notation = LxChess::Notation.new(input)
    puts notation.to_h
  end
end

# gb.flip!
# gb.draw
# puts
