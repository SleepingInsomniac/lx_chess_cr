require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"
require "../../src/lx_chess/move_set"
require "../../src/lx_chess/game"

describe LxChess::Game do
  describe "#moves" do
    it "correctly generates white pawn moves from the initial rank" do
      game = LxChess::Game.new
      game.board["e2"] = LxChess::Piece.from_fen('P')
      moves = game.moves("e2")
      moves.map { |m| game.board.cord(m) }.should eq(["e3", "e4"])
    end

    it "correctly generates black pawn moves from the initial rank" do
      game = LxChess::Game.new
      game.board["e7"] = LxChess::Piece.from_fen('p')
      moves = game.moves("e7")
      moves.map { |m| game.board.cord(m) }.should eq(["e6", "e5"])
    end

    it "correctly generates single white pawn moves" do
      game = LxChess::Game.new
      game.board["e3"] = LxChess::Piece.from_fen('P')
      moves = game.moves("e3")
      moves.map { |m| game.board.cord(m) }.should eq(["e4"])
    end

    it "correctly generates black white pawn moves" do
      game = LxChess::Game.new
      game.board["e6"] = LxChess::Piece.from_fen('p')
      moves = game.moves("e6")
      moves.map { |m| game.board.cord(m) }.should eq(["e5"])
    end

    it "correctly generates knight moves" do
      game = LxChess::Game.new
      game.board["c3"] = LxChess::Piece.from_fen('N')
      moves = game.moves("c3")
      moves.map { |m| game.board.cord(m) }.should eq(["a4", "b5", "d5", "e4", "e2", "d1", "b1", "a2"])
    end

    it "correctly generates rook moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('R')
      moves = game.moves("e4")
      moves.map { |m| game.board.cord(m) }.should eq([
        "d4", "c4", "b4", "a4",
        "e5", "e6", "e7", "e8",
        "f4", "g4", "h4",
        "e3", "e2", "e1",
      ])
    end

    it "correctly generates bishop moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('B')
      moves = game.moves("e4")
      moves.map { |m| game.board.cord(m) }.should eq([
        "d5", "c6", "b7", "a8",
        "f5", "g6", "h7",
        "f3", "g2", "h1",
        "d3", "c2", "b1",
      ])
    end
  end
end
