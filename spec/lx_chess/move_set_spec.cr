require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"
require "../../src/lx_chess/move_set"

describe LxChess::MoveSet do
  describe "#add_vector" do
    it "generates moves to the right" do
      game = LxChess::Game.new
      piece = LxChess::Piece.from_fen('R')
      game.board["a1"] = piece
      move_set = LxChess::MoveSet.new(piece, game.board)
      move_set.add_vector(x: 1, y: 0, limit: 3)
      move_set.moves.size.should eq(3)
      move_set.moves.should eq([1, 2, 3])
    end
  end
end
