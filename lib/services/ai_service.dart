import 'dart:math';
import '../models/move.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import 'chess_engine.dart';

/// AI service implementing the Minimax algorithm with Alpha-Beta pruning.
///
/// The AI evaluates board positions using material counting and positional
/// heuristics (piece-square tables) to select the best move.
class AIService {
  final Random _random = Random();
  int _nodesSearched = 0;

  /// Returns the best move for the given [engine] state at [difficulty].
  Move? findBestMove(ChessEngine engine, AIDifficulty difficulty) {
    _nodesSearched = 0;
    final legalMoves = engine.getLegalMoves();
    if (legalMoves.isEmpty) return null;
    if (legalMoves.length == 1) return legalMoves.first;

    final depth = difficulty.searchDepth;
    final player = engine.currentPlayer;

    Move? bestMove;
    int bestScore = -999999;

    // Sort moves for better alpha-beta pruning (captures first)
    final sortedMoves = _sortMoves(legalMoves, engine);

    for (final move in sortedMoves) {
      // Make move on a copy
      final childEngine = _copyEngine(engine);
      childEngine.makeMove(move);

      final score = -_minimax(childEngine, depth - 1, -999999, 999999,
          player.opponent, difficulty.addRandomness);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    // For easy difficulty, occasionally pick a suboptimal move
    if (difficulty.addRandomness && _random.nextDouble() < 0.2) {
      final randomIndex = _random.nextInt(legalMoves.length);
      return legalMoves[randomIndex];
    }

    return bestMove;
  }

  /// Minimax with Alpha-Beta pruning.
  int _minimax(
    ChessEngine engine,
    int depth,
    int alpha,
    int beta,
    Player player,
    bool addRandomness,
  ) {
    _nodesSearched++;

    // Terminal node evaluation
    if (depth == 0 || engine.status.isGameOver) {
      return engine.evaluate(player);
    }

    final legalMoves = engine.getLegalMoves();
    if (legalMoves.isEmpty) {
      return engine.evaluate(player);
    }

    final sortedMoves = _sortMoves(legalMoves, engine);

    // Add small randomness to scores for variety
    final randomBonus = addRandomness ? _random.nextInt(10) - 5 : 0;

    int bestScore = -999999;
    for (final move in sortedMoves) {
      final childEngine = _copyEngine(engine);
      childEngine.makeMove(move);

      final score = -_minimax(
              childEngine, depth - 1, -beta, -alpha, player, addRandomness) +
          randomBonus;

      bestScore = max(bestScore, score);
      alpha = max(alpha, score);

      if (alpha >= beta) break; // Beta cutoff
    }

    return bestScore;
  }

  /// Sorts moves putting captures first for better pruning.
  List<Move> _sortMoves(List<Move> moves, ChessEngine engine) {
    final sorted = List<Move>.from(moves);

    // Assign scores to each move for sorting
    Map<Move, int> scores = {};
    for (final move in sorted) {
      int score = 0;
      if (move.capturedPiece != null) {
        // MVV-LVA: Most Valuable Victim - Least Valuable Attacker
        score += move.capturedPiece!.type.value * 10 - move.piece.type.value;
      }
      if (move.promotionType != null) {
        score += move.promotionType!.value;
      }
      scores[move] = score;
    }

    sorted.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
    return sorted;
  }

  /// Creates a deep copy of the engine for analysis without mutation.
  ChessEngine _copyEngine(ChessEngine engine) {
    final newBoard = List.generate(8, (row) {
      return List.generate(8, (col) {
        final piece = engine.board[row][col];
        return piece?.copy();
      });
    });

    final copy = ChessEngine.fromBoard(
      board: newBoard,
      currentPlayer: engine.currentPlayer,
      whiteKingSideCastle: engine.whiteKingSideCastle,
      whiteQueenSideCastle: engine.whiteQueenSideCastle,
      blackKingSideCastle: engine.blackKingSideCastle,
      blackQueenSideCastle: engine.blackQueenSideCastle,
      enPassantTarget: engine.enPassantTarget,
      halfMoveClock: engine.halfMoveClock,
      fullMoveCount: engine.fullMoveCount,
    );

    copy.moveHistory.addAll(engine.moveHistory);
    copy.positionHistory.addAll(engine.positionHistory);
    copy.status = engine.status;
    copy.winner = engine.winner;
    return copy;
  }

  /// Returns nodes searched for performance debugging.
  int get nodesSearched => _nodesSearched;
}
