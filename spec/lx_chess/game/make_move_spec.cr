require "../../spec_helper"
require "../../../src/lx_chess/board"
require "../../../src/lx_chess/piece"
require "../../../src/lx_chess/move_set"
require "../../../src/lx_chess/game"

include LxChess

describe Game do
  describe "#make_move" do
    context "when a move will promote" do
      it "raises an exception when promotion is not specified" do
        game = Game.new
        game.board["e7"] = Piece.from_fen('P')
        expect_raises(Game::IllegalMove) do
          game.make_move("e7", "e8")
        end
      end

      it "raises an exception when promotion is not specified" do
        game = Game.new
        game.board["e7"] = Piece.from_fen('P')
        game.make_move("e7", "e8", 'Q')
        piece = game.board["e8"]
        from = game.board["e7"]
        from.should be_nil
        raise "e8 is empty" unless piece
        piece.fen_symbol.should eq('Q')
      end
    end
  end
end
