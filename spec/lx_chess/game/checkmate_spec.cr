require "../../spec_helper"
require "../../../src/lx_chess/board"
require "../../../src/lx_chess/piece"
require "../../../src/lx_chess/move_set"
require "../../../src/lx_chess/game"
require "../../../src/lx_chess/fen"

include LxChess

describe Game do
  describe "#checkmate?" do
    context "when white has checkmate" do
      it "returns true" do
        fen = Fen.parse("r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4")
        game = Game.new(board: fen.board, players: [Player.new, Player.new])
        game.checkmate?(1).should eq(false)
        san = game.make_move("h5", "f7")
        debug_board(game, ["h5", "f7"])
        game.checkmate?(1).should eq(true)
      end
    end
  end
end
