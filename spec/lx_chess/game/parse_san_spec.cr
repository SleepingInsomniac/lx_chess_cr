require "../../spec_helper"
require "../../../src/lx_chess/board"
require "../../../src/lx_chess/piece"
require "../../../src/lx_chess/move_set"
require "../../../src/lx_chess/game"

include LxChess

describe Game do
  describe "#parse_san" do
    context "when SAN is a pawn move" do
      it "returns a correct from and to square" do
        game = Game.new
        game.board["e2"] = Piece.from_fen('P')
        from, to = game.parse_san("e4")
        from.should eq(game.board.index_of("e2"))
        to.should eq(game.board.index_of("e4"))
      end

      it "disambiguates the move correctly" do
        game = Game.new
        place(game.board, {
          "d4" => 'P',
          "f4" => 'P',
          "e5" => 'p',
        })

        moves = game.parse_san("dxe5")
        debug_board(game, moves)
        moves.should eq(["d4", "e5"].map { |s| game.board.index_of(s) })
      end
    end
  end
end
