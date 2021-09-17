require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"
require "../../src/lx_chess/move_set"
require "../../src/lx_chess/game"
require "../../src/lx_chess/term_board"

describe LxChess::Game do
  describe "#moves" do
    it "correctly generates white pawn moves from the initial rank" do
      game = LxChess::Game.new
      game.board["e2"] = LxChess::Piece.from_fen('P')
      if move_set = game.moves("e2")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e3 e4])
      else
        raise "no moves"
      end
    end

    it "correctly generates black pawn moves from the initial rank" do
      game = LxChess::Game.new
      game.board["e7"] = LxChess::Piece.from_fen('p')
      if move_set = game.moves("e7")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e6 e5])
      else
        raise "no moves"
      end
    end

    it "correctly generates single white pawn moves" do
      game = LxChess::Game.new
      game.board["e3"] = LxChess::Piece.from_fen('P')
      if move_set = game.moves("e3")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e4])
      else
        raise "no moves"
      end
    end

    it "correctly generates black pawn moves" do
      game = LxChess::Game.new
      game.board["e6"] = LxChess::Piece.from_fen('p')
      if move_set = game.moves("e6")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5])
      else
        raise "no moves"
      end
    end

    it "generates captures for white pawns" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('P')
      game.board["f5"] = LxChess::Piece.from_fen('p')
      game.board["d5"] = LxChess::Piece.from_fen('p')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5 d5 f5])
      else
        raise "no moves"
      end
    end

    it "does not generates captures pawns capturing own pieces" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('P')
      game.board["f5"] = LxChess::Piece.from_fen('P')
      game.board["d5"] = LxChess::Piece.from_fen('P')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5])
      else
        raise "no moves"
      end
    end

    it "generates captures for en passant targets" do
      game = LxChess::Game.new
      game.board["e5"] = LxChess::Piece.from_fen('P')
      game.board["d5"] = LxChess::Piece.from_fen('p')
      game.en_passant_target = "d6"
      if move_set = game.moves("e5")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e6 d6])
      else
        raise "no moves"
      end
    end

    it "correctly generates knight moves" do
      game = LxChess::Game.new
      game.board["c3"] = LxChess::Piece.from_fen('N')
      if move_set = game.moves("c3")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[a4 b5 d5 e4 e2 d1 b1 a2])
      else
        raise "no moves"
      end
    end

    it "does not generate knight moves that cross the left border edge" do
      game = LxChess::Game.new
      game.board["a1"] = LxChess::Piece.from_fen('N')
      if move_set = game.moves("a1")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[b3 c2])
      else
        raise "no moves"
      end
    end

    it "does not generate knight moves that cross the right border edge" do
      game = LxChess::Game.new
      game.board["h1"] = LxChess::Piece.from_fen('N')
      if move_set = game.moves("h1")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[f2 g3])
      else
        raise "no moves"
      end
    end

    it "correctly generates rook moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('R')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d4 c4 b4 a4
          e5 e6 e7 e8
          f4 g4 h4
          e3 e2 e1
        ])
      else
        raise "no moves"
      end
    end

    it "correctly generates bishop moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('B')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d5 c6 b7 a8
          f5 g6 h7
          f3 g2 h1
          d3 c2 b1
        ])
      else
        raise "no moves"
      end
    end

    it "correctly generates king moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('K')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d4 d5 e5 f5 f4 f3 e3 d3
        ])
      else
        raise "no moves"
      end
    end

    it "does not generate king moves crossing the right border" do
      game = LxChess::Game.new
      game.board["h4"] = LxChess::Piece.from_fen('K')
      if move_set = game.moves("h4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          g4 g5 h5 h3 g3
        ])
      else
        raise "no moves"
      end
    end

    it "correctly generates queen moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('Q')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d5 c6 b7 a8
          f5 g6 h7
          f3 g2 h1
          d3 c2 b1
          d4 c4 b4 a4
          e5 e6 e7 e8
          f4 g4 h4
          e3 e2 e1
        ])
      else
        raise "no moves"
      end
    end

    it "blocks moves when a piece is in the way" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('B')
      game.board["f5"] = LxChess::Piece.from_fen('P')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d5 c6 b7 a8
          f3 g2 h1
          d3 c2 b1
        ])
      else
        raise "no moves"
      end
    end

    it "adds captures before blocking further moves" do
      game = LxChess::Game.new
      game.board["e4"] = LxChess::Piece.from_fen('B')
      game.board["f5"] = LxChess::Piece.from_fen('p')
      if move_set = game.moves("e4")
        debug_board(game, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d5 c6 b7 a8
          f5
          f3 g2 h1
          d3 c2 b1
        ])
      else
        raise "no moves"
      end
    end
  end
end
