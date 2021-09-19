require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"
require "../../src/lx_chess/move_set"
require "../../src/lx_chess/game"
require "../../src/lx_chess/fen"

include LxChess

describe "Castling" do
  describe "white" do
    it "moves the king and the rook when castling kingside" do
      fen = Fen.parse("8/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
      game = Game.new(board: fen.board, players: [Player.new, Player.new])

      game.make_move(from: "e1", to: "g1")
      debug_board(game, ["e1", "g1"])
      fen.update(game)
      fen.to_s.should eq("8/8/8/8/8/8/8/R4RK1 b kq - 1 1")
    end

    it "moves the king and the rook when castling queenside" do
      fen = Fen.parse("8/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
      game = Game.new(board: fen.board, players: [Player.new, Player.new])

      game.make_move(from: "e1", to: "c1")
      debug_board(game, ["e1", "c1"])
      fen.update(game)
      fen.to_s.should eq("8/8/8/8/8/8/8/2KR3R b kq - 1 1")
    end
  end

  describe "black" do
    it "moves the king and the rook when castling kingside" do
      fen = Fen.parse("r3k2r/8/8/8/8/8/8/8 w KQkq - 0 1")
      game = Game.new(board: fen.board, players: [Player.new, Player.new])

      game.make_move(from: "e8", to: "g8")
      debug_board(game, ["e8", "g8"])
      fen.update(game)
      fen.to_s.should eq("r4rk1/8/8/8/8/8/8/8 b kq - 1 1")
    end

    it "moves the king and the rook when castling queenside" do
      fen = Fen.parse("r3k2r/8/8/8/8/8/8/8 w KQkq - 0 1")
      game = Game.new(board: fen.board, players: [Player.new, Player.new])

      game.make_move(from: "e8", to: "c8")
      debug_board(game, ["e8", "c8"])
      fen.update(game)
      fen.to_s.should eq("2kr3r/8/8/8/8/8/8/8 b kq - 1 1")
    end
  end

  it "castles from non-standard positions" do
    # For non-standard chess games
    fen = Fen.parse("8/8/8/8/8/8/8/R1K4R w KQkq - 0 1")
    game = Game.new(board: fen.board, players: [Player.new, Player.new])

    game.make_move(from: "c1", to: "e1")
    debug_board(game, ["c1", "e1"])
    fen.update(game)
    fen.to_s.should eq("8/8/8/8/8/8/8/R2RK3 b kq - 1 1")
  end

  it "does not allow castling after the king has moved" do
    fen = Fen.parse("8/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    game = Game.new(board: fen.board, players: [Player.new, Player.new])
    game.make_move(from: "e1", to: "d1")
    fen.update(game)
    fen.to_s.should eq("8/8/8/8/8/8/8/R2K3R b kq - 1 1")
    game.next_turn
    expect_raises(Game::IllegalMove) do
      game.make_move(from: "d1", to: "f1")
    end
  end
end
