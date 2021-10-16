require "./board"
require "./game"
require "./player"
require "./piece"
require "./move_tree"

module LxChess
  class Computer < Player
    def ai?
      true
    end

    def get_move(game : Game, turn : Int8? = nil)
      tree = best_moves(game, turn)

      Log.debug do
        "Best moves: #{tree.best_branches.map { |b| [game.board.cord(b[0]), game.board.cord(b[1])].join(" => ") + " : #{b[2].score}" }.join(", ")}"
      end
      move = tree.best_branches.sample
      from, to, _ = move

      raise "from is nil" unless from_piece = game.board[from]

      promotion =
        case game.turn
        when 0
          if from_piece.pawn?
            game.board.rank(to) == game.board.height - 1 ? 'Q' : nil
          end
        when 1
          if from_piece.pawn?
            game.board.rank(to) == 0 ? 'Q' : nil
          end
        end

      Log.debug { "Chose random best move: #{game.board.cord(from)} => #{game.board.cord(to)}" }
      {from, to, promotion}
    end

    # Evaluate the score of a given *board*
    # TODO: more positional analysis
    def board_score(game : Game, turn : Int8? = nil)
      turn = turn || game.turn

      score = 0

      if game.checkmate?
        score += game.turn == 0 ? 10_000 : -10_000
      end

      score += game.board.reduce(0) do |score, piece|
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

      return score if game.players.none?

      # If the player is black, a negative value is good
      if game.players[game.turn] == self
        score.abs
      else
        -score.abs
      end
    end

    def move_sets(game : Game, turn : Int8? = nil)
      turn = turn || game.turn

      move_sets = game.pieces_for(turn).map do |piece|
        move_set = game.moves(piece.index).try do |set|
          game.remove_illegal_moves(set)
        end
      end.compact
    end

    # Generate an array of moves (from => to) which result in an even or best score
    # TODO: promotion, pruning
    def best_moves(game : Game, turn : Int8? = nil, depth = 0, root_tree : MoveTree? = nil) # : Array(Array(Int16))
      Log.debug { "=================================== Best moves ===================================" }

      turn = turn || game.turn

      if root_tree.nil?
        root_tree = MoveTree.new score: board_score(game, turn), turn: turn
      end

      Log.debug { "Evaluating best moves for turn: #{turn}, depth: #{depth}, current score: #{root_tree.score} ..." }

      move_sets(game, turn).each do |set|
        origin = set.piece.index

        set.moves.each do |move|
          game.tmp_move(from: origin, to: move) do
            current_score = board_score(game, turn)

            tree = MoveTree.new(score: current_score, turn: game.next_turn(turn))
            root_tree << {origin, move, tree}
          end
        end
      end

      Log.debug { "\n" + root_tree.to_s(IO::Memory.new).to_s }

      Log.debug { "Found #{root_tree.branches.size} moves" }
      Log.debug do
        current_bests = root_tree.best_branches.map { |b| [b[0], b[1]].map { |c| game.board.cord(c) }.join(" => ") }.join(", ")
        "current best branches: #{current_bests}"
      end

      if depth < 2
        root_tree.branches.each do |branch|
          from, to, tree = branch
          Log.debug do
            "Considering branch: #{game.board.cord(from)} => #{game.board.cord(to)} ..."
          end

          game.tmp_move(from: from, to: to) do
            best_moves(game, turn, depth + 1, tree)

            if tree.score > root_tree.score
              Log.debug { "Found better branch: #{game.board.cord(from)} => #{game.board.cord(to)} : #{root_tree.score} => #{tree.score}" }

              root_tree.score = tree.score
              root_tree.best_branches.truncate(0, 0)
            end

            if tree.score == root_tree.score
              root_tree.best_branches << branch
            end
          end
        end
      end

      root_tree
    end
  end
end
