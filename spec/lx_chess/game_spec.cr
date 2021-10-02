require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"
require "../../src/lx_chess/move_set"
require "../../src/lx_chess/game"
require "../../src/lx_chess/term_board"
require "../../src/lx_chess/player"

include LxChess

describe Game do
  describe "#remove_illegal_moves" do
    it "removes illegal moves" do
      game = Game.new players: [Player.new, Player.new]
      game.board["e8"] = rook = Piece.from_fen('r')
      game.board["e4"] = pawn = Piece.from_fen('R')
      game.board["e1"] = king = Piece.from_fen('K')

      if move_set = game.moves("e4")
        move_set = game.remove_illegal_moves(move_set)
        debug_board(game.board, move_set.moves)
        move_set.moves.should eq([36, 44, 52, 60, 20, 12])
      else
        raise "move set was nil"
      end
    end
  end

  describe "#tmp_move" do
    it "makes a temporary move" do
      game = Game.new players: [Player.new, Player.new]
      game.board["c8"] = rook = Piece.from_fen('r')
      game.board["e8"] = pawn = Piece.from_fen('P')
      game.tmp_move("c8", "e8") do
        game.board["e8"].should eq(rook)
      end
      game.board["c8"].should eq(rook)
      game.board["e8"].should eq(pawn)
    end

    it "detects check within a tmp_move" do
      game = Game.new players: [Player.new, Player.new]
      game.board["c8"] = rook = Piece.from_fen('r')
      game.board["e1"] = king = Piece.from_fen('K')
      game.tmp_move("c8", "e8") do
        game.board["e8"].should eq(rook)
        game.in_check?(0).should eq(true)
      end
      game.in_check?(0).should eq(false)
    end

    it "can be nested" do
      game = Game.new players: [Player.new, Player.new]
      game.board["c8"] = rook = Piece.from_fen('r')
      game.board["e1"] = king = Piece.from_fen('K')
      game.tmp_move("c8", "e8") do
        game.board["e8"].should eq(rook)
        game.in_check?(0).should eq(true)
        game.tmp_move("e1", "d1") do
          game.in_check?(0).should eq(false)
        end
      end
      game.board["c8"].should eq(rook)
      game.board["e1"].should eq(king)
    end
  end

  describe "#in_check?" do
    it "detects if the player is in check" do
      game = Game.new players: [Player.new, Player.new]
      game.board["e1"] = Piece.from_fen('K')
      game.board["e8"] = Piece.from_fen('r')
      debug_board(game.board)
      game.in_check?(0).should eq(true)
    end
  end

  describe "#next_turn" do
    it "returns the next turn number" do
      game = Game.new players: [Player.new, Player.new]
      game.turn.should eq(0)
      game.next_turn.should eq(1)
    end

    it "returns the relative next turn number" do
      game = Game.new players: [Player.new, Player.new]
      game.turn.should eq(0)
      game.next_turn(1).should eq(0)
    end
  end

  describe "#castling=" do
    it "sets the castling from a string" do
      player_white = Player.new
      player_black = Player.new
      game = Game.new(players: [player_white, player_black])
      game.castling = "kQ"
      player_white.castle_king.should be_true
      player_white.castle_queen.should be_false
      player_black.castle_king.should be_false
      player_black.castle_queen.should be_true
    end
  end

  describe "#find_king" do
    it "finds the black king" do
      game = Game.new
      place(game.board, {"e1" => 'K', "e8" => 'k'})
      black_king = game.find_king(1)
      black_king.should_not be(nil)
      black_king.try { |k| k.fen_symbol.should eq('k') }
    end

    it "finds the white king" do
      game = Game.new
      place(game.board, {"e1" => 'K', "e8" => 'k'})
      white_king = game.find_king(0)
      white_king.should_not be(nil)
      white_king.try { |k| k.fen_symbol.should eq('K') }
    end
  end

  describe "#moves" do
    it "correctly generates white pawn moves from the initial rank" do
      game = Game.new
      game.board["e2"] = Piece.from_fen('P')
      if move_set = game.moves("e2")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e3 e4])
      else
        raise "no moves"
      end
    end

    it "correctly generates black pawn moves from the initial rank" do
      game = Game.new
      game.board["e7"] = Piece.from_fen('p')
      if move_set = game.moves("e7")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e6 e5])
      else
        raise "no moves"
      end
    end

    it "correctly generates single white pawn moves" do
      game = Game.new
      game.board["e3"] = Piece.from_fen('P')
      if move_set = game.moves("e3")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e4])
      else
        raise "no moves"
      end
    end

    it "correctly generates black pawn moves" do
      game = Game.new
      game.board["e6"] = Piece.from_fen('p')
      if move_set = game.moves("e6")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5])
      else
        raise "no moves"
      end
    end

    it "generates captures for white pawns" do
      game = Game.new
      game.board["e4"] = Piece.from_fen('P')
      game.board["f5"] = Piece.from_fen('p')
      game.board["d5"] = Piece.from_fen('p')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5 d5 f5])
      else
        raise "no moves"
      end
    end

    it "does not generates captures pawns capturing own pieces" do
      game = Game.new
      game.board["e4"] = Piece.from_fen('P')
      game.board["f5"] = Piece.from_fen('P')
      game.board["d5"] = Piece.from_fen('P')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e5])
      else
        raise "no moves"
      end
    end

    it "generates captures for en passant targets" do
      game = Game.new
      game.board["e5"] = Piece.from_fen('P')
      game.board["d5"] = Piece.from_fen('p')
      game.en_passant_target = "d6"
      if move_set = game.moves("e5")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[e6 d6])
      else
        raise "no moves"
      end
    end

    it "correctly generates knight moves" do
      game = Game.new
      game.board["c3"] = Piece.from_fen('N')
      if move_set = game.moves("c3")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[a4 b5 d5 e4 e2 d1 b1 a2])
      else
        raise "no moves"
      end
    end

    it "does not generate knight moves that cross the left border edge" do
      game = Game.new
      game.board["a1"] = Piece.from_fen('N')
      if move_set = game.moves("a1")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[b3 c2])
      else
        raise "no moves"
      end
    end

    it "does not generate knight moves that cross the right border edge" do
      game = Game.new
      game.board["h1"] = Piece.from_fen('N')
      if move_set = game.moves("h1")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[f2 g3])
      else
        raise "no moves"
      end
    end

    it "correctly generates rook moves" do
      game = Game.new
      game.board["e4"] = Piece.from_fen('R')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
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
      game = Game.new
      game.board["e4"] = Piece.from_fen('B')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
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
      game = Game.new
      game.board["e4"] = Piece.from_fen('K')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          d4 d5 e5 f5 f4 f3 e3 d3
        ])
      else
        raise "no moves"
      end
    end

    it "does not generate king moves crossing the right border" do
      game = Game.new
      game.board["h4"] = Piece.from_fen('K')
      if move_set = game.moves("h4")
        debug_board(game.board, move_set.moves)
        move_set.moves.map { |m| game.board.cord(m) }.should eq(%w[
          g4 g5 h5 h3 g3
        ])
      else
        raise "no moves"
      end
    end

    it "correctly generates queen moves" do
      game = Game.new
      game.board["e4"] = Piece.from_fen('Q')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
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
      game = Game.new
      game.board["e4"] = Piece.from_fen('B')
      game.board["f5"] = Piece.from_fen('P')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
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
      game = Game.new
      game.board["e4"] = Piece.from_fen('B')
      game.board["f5"] = Piece.from_fen('p')
      if move_set = game.moves("e4")
        debug_board(game.board, move_set.moves)
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
