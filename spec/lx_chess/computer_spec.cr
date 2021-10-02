require "../spec_helper"
require "../../src/lx_chess/computer"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"

include LxChess

describe Computer do
  describe "#board_score" do
    it "scores the board" do
      computer = Computer.new
      game = Game.new
      game.board["e4"] = Piece.from_fen('P')
      computer.board_score(game).should eq(100)
    end
  end
end
