require "spec"

require "../src/lx_chess/game"
require "../src/lx_chess/board"
require "../src/lx_chess/term_board"

def debug_board(game : LxChess::Game, moves : Array(String))
  moves = moves.map { |m| game.board.index(m) }
  debug_board(game, moves)
end

def debug_board(game : LxChess::Game, moves = [] of Int16)
  puts
  gb = LxChess::TermBoard.new(game.board)
  gb.highlight(moves)
  gb.draw
  puts
end

def place(board : LxChess::Board, squares : Hash(String, Char))
  squares.each do |cord, sym|
    game.board[cord] = LxChess::Piece.from_fen(sym)
  end
end
