require "../spec_helper"
require "../../src/lx_chess/board"
require "../../src/lx_chess/piece"

describe LxChess::Board do
  describe "#border_left" do
    it "returns the boarder to the left of an index in rank 0" do
      board = LxChess::Board.new
      board.border_left(4).should eq(0)
    end

    it "returns the boarder to the left of an index in rank 1" do
      board = LxChess::Board.new
      board.border_left(12).should eq(8)
    end
  end

  describe "#border_right" do
    it "returns the boarder to the right of an index in rank 0" do
      board = LxChess::Board.new
      board.border_right(4).should eq(7)
    end

    it "returns the boarder to the left of an index" do
      board = LxChess::Board.new
      board.border_right(12).should eq(15)
    end
  end

  describe "#index" do
    it "returns the index of a coordinate" do
      board = LxChess::Board.new
      board.index_of("e2").should eq(12)
    end
  end
end
