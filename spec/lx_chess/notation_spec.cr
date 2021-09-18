require "../spec_helper"
require "../../src/lx_chess/notation"

include LxChess

describe Notation do
  describe "#new" do
    it "parses castling kingside" do
      notation = Notation.new("O-O")
      notation.castles_k?.should eq(true)
    end

    it "parses pawn moves" do
      notation = Notation.new("e4")
      notation.square.should eq("e4")
    end

    it "parses pawn moves that specify pawn" do
      notation = Notation.new("Pe4")
      notation.square.should eq("e4")
      notation.piece_abbr.should eq('P')
    end

    it "parses pawn moves that specify captures" do
      notation = Notation.new("Pxe4")
      notation.square.should eq("e4")
      notation.piece_abbr.should eq('P')
      notation.takes.should be_true
    end

    it "parses weird moves from larger boards" do
      notation = Notation.new("Pwxr32")
      notation.square.should eq("r32")
      notation.piece_abbr.should eq('P')
      notation.origin.should eq("w")
      notation.takes.should be_true
    end

    it "parses file disambiguation" do
      notation = Notation.new("exd5")
      notation.origin.should eq("e")
      notation.takes.should be_true
      notation.square.should eq("d5")
    end

    it "parses rank disambiguation" do
      notation = Notation.new("4xd5")
      notation.origin.should eq("4")
      notation.takes.should be_true
      notation.square.should eq("d5")
    end

    it "parses bxe5 as a pawn move" do
      notation = Notation.new("bxe5")
      notation.origin.should eq("b")
      notation.takes.should be_true
      notation.square.should eq("e5")
    end

    it "parses Bxe5 as a bishop move" do
      notation = Notation.new("Bxe5")
      notation.piece_abbr.should eq('B')
      notation.takes.should be_true
      notation.square.should eq("e5")
    end

    it "parses promotions" do
      notation = Notation.new("dxe8=Q")
      notation.takes.should be_true
      notation.square.should eq("e8")
      notation.promotion.should eq('Q')
    end
  end
end
