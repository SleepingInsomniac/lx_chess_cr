require "../../spec_helper"

include LxChess

describe Game do
  describe "#move_to_san" do
    it "converts pawn captures" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {
        "e4" => 'P',
        "d5" => 'p',
      })
      debug_board(game.board, ["e4", "d5"])
      san = game.move_to_san(from: "e4", to: "d5", turn: 0)
      puts san.to_s
      san.to_s.should eq("exd5")
    end

    it "converts pawn moves" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {"e2" => 'P'})
      debug_board(game.board, ["e2", "e4"])
      san = game.move_to_san(from: "e2", to: "e4", turn: 0)
      puts san.to_s
      san.to_s.should eq("e4")
    end

    it "disambiguates pawn captures" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {
        "c4" => 'P',
        "e4" => 'P',
        "d5" => 'p',
      })
      debug_board(game.board, ["e4", "d5"])
      san = game.move_to_san(from: "e4", to: "d5", turn: 0)
      puts san.to_s
      san.to_s.should eq("exd5")
      debug_board(game.board, ["c4", "d5"])
      san = game.move_to_san(from: "c4", to: "d5", turn: 0)
      puts san.to_s
      san.to_s.should eq("cxd5")
    end

    it "disambiguates rook moves" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {
        "e4" => 'R',
        "d5" => 'R',
      })
      debug_board(game.board, ["e4", "e5"])
      san = game.move_to_san(from: "e4", to: "e5", turn: 0)
      puts san.to_s
      san.to_s.should eq("Ree5")
    end

    it "disambiguates knight moves" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {
        "f3" => 'N',
        "e2" => 'N',
      })
      debug_board(game.board, ["e2", "d4"])
      san = game.move_to_san(from: "e2", to: "d4", turn: 0)
      puts san.to_s
      san.to_s.should eq("Ned4")
    end

    it "disambiguates knight moves on the same file" do
      game = Game.new players: [Player.new, Player.new]
      place(game.board, {
        "e4" => 'N',
        "e2" => 'N',
      })
      debug_board(game.board, ["e2", "c3"])
      san = game.move_to_san(from: "e2", to: "c3", turn: 0)
      puts san.to_s
      san.to_s.should eq("Ne2c3")
    end

    it "detects check" do
      game = Game.new players: [Player.new, Player.new]
      game.board["e1"] = Piece.from_fen('K')
      game.board["c8"] = Piece.from_fen('r')
      debug_board(game.board, ["c8", "e8"])
      san = game.move_to_san(from: "c8", to: "e8", turn: 1)
      puts san.to_s
      san.to_s.should eq("Re8+")
    end

    it "detects checkmate" do
      fen = Fen.parse("r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4")
      game = Game.new(board: fen.board, players: [Player.new, Player.new])
      san = game.move_to_san(from: "h5", to: "f7", turn: 0)
      debug_board(game.board, ["h5", "f7"])
      puts san.to_s
      san.to_s.should eq("Qxf7#")
    end
  end
end
