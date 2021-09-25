require "./lx_chess/*"
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

  parser.on("--open=PGN", "open a pgn file") do |path|
    options["pgn_path"] = path
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

fen = LxChess::Fen.parse(options["fen_string"]? || "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
term_game = LxChess::TermGame.new(fen: fen)

if path = options["pgn_path"]?
  game = LxChess::Game.new
  pgn_file = File.read(path)
  pgn = LxChess::PGN.new(pgn_file)

  term_game = LxChess::TermGame.new(pgn: pgn)
end

if theme = options["theme"]?
  if LxChess::TermBoard::THEMES[theme]?
    term_game.gb.board_theme = theme
  else
    STDERR.puts "No theme #{theme}"
    exit 1
  end
end

term_game.clear_screen
loop do
  term_game.tick
end
