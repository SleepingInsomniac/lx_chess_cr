require "spec"

require "../src/lx_chess/game"
require "../src/lx_chess/board"
require "../src/lx_chess/term_board"

def debug_board(board : LxChess::Board, moves : Array(String))
  moves = moves.map { |m| board.index_of(m) }
  debug_board(board, moves)
end

def debug_board(board : LxChess::Board, moves : Array(Int16) = [] of Int16)
  puts
  gb = LxChess::TermBoard.new(board)
  gb.highlight(moves)
  gb.draw
  puts
end

def place(board : LxChess::Board, squares : Hash(String, Char))
  squares.each do |cord, sym|
    board[cord] = LxChess::Piece.from_fen(sym)
  end
end
