require "./board"
require "./game"
require "./player"
require "./piece"

module LxChess
  class Computer < Player
    def ai?
      true
    end

    def get_move(game : Game, turn : Int8? = nil)
      moves = best_moves(game, turn)
      moves.any? ? moves.sample : nil
    end

    # Evaluate the score of a given *board*
    # TODO: more positional analysis
    def board_score(game : Game)
      score = 0
      if game.checkmate?
        score += game.turn == 0 ? 10_000 : -10_000
      end

      score + game.board.reduce(0) do |score, piece|
        next score unless piece
        val =
          case piece.id
          when Piece::PAWN   then 100
          when Piece::QUEEN  then 900
          when Piece::ROOK   then 500
          when Piece::BISHOP then 300
          when Piece::KNIGHT then 300
          else
            0
          end
        piece.black? ? score - val : score + val
      end
    end

    # Generate an array of moves (from => to) which result in an even or best score
    # TODO: promotion, depth, pruning
    def best_moves(game : Game, turn : Int8? = nil) : Array(Array(Int16))
      turn = turn || game.turn

      move_sets = game.pieces_for(turn).map do |piece|
        move_set = game.moves(piece.index).try do |set|
          game.remove_illegal_moves(set)
        end
      end.compact

      _best_moves = [] of Array(Int16)
      best_score = 0

      move_sets.each do |set|
        origin = set.piece.index

        set.moves.each do |move|
          game.tmp_move(from: origin, to: move) do
            current_score = board_score(game)

            if current_score > best_score
              best_score = current_score
              _best_moves = [] of Array(Int16)
              _best_moves << [origin, move]
            elsif current_score == best_score
              _best_moves << [origin, move]
            end
          end
        end
      end

      _best_moves
    end
  end
end
