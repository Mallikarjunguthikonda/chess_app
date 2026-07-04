import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/move.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../models/game_state.dart';
import '../services/chess_engine.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';

/// Represents the state of the game screen.
class GameStateData {
  final ChessEngine engine;
  final GameMode gameMode;
  final AIDifficulty aiDifficulty;
  final bool isAIThinking;
  final Position? selectedPosition;
  final List<Position> legalMoveTargets;
  final Move? lastMove;
  final String statusMessage;
  final bool showPromotionDialog;
  final Position? promotionPosition;
  final List<Move>? promotionMoves;

  const GameStateData({
    required this.engine,
    required this.gameMode,
    required this.aiDifficulty,
    this.isAIThinking = false,
    this.selectedPosition,
    this.legalMoveTargets = const [],
    this.lastMove,
    this.statusMessage = '',
    this.showPromotionDialog = false,
    this.promotionPosition,
    this.promotionMoves,
  });

  GameStateData copyWith({
    ChessEngine? engine,
    GameMode? gameMode,
    AIDifficulty? aiDifficulty,
    bool? isAIThinking,
    Position? selectedPosition,
    List<Position>? legalMoveTargets,
    Move? lastMove,
    String? statusMessage,
    bool? showPromotionDialog,
    Position? promotionPosition,
    List<Move>? promotionMoves,
    bool clearSelection = false,
    bool clearLastMove = false,
  }) {
    return GameStateData(
      engine: engine ?? this.engine,
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      isAIThinking: isAIThinking ?? this.isAIThinking,
      selectedPosition: clearSelection ? null : (selectedPosition ?? this.selectedPosition),
      legalMoveTargets: legalMoveTargets ?? this.legalMoveTargets,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      statusMessage: statusMessage ?? this.statusMessage,
      showPromotionDialog: showPromotionDialog ?? this.showPromotionDialog,
      promotionPosition: promotionPosition ?? this.promotionPosition,
      promotionMoves: promotionMoves ?? this.promotionMoves,
    );
  }
}

/// Notifier managing the complete game lifecycle.
class GameNotifier extends StateNotifier<GameStateData> {
  final AIService _aiService;
  final SoundService _soundService;
  final StorageService _storageService;

  GameNotifier({
    required AIService aiService,
    required SoundService soundService,
    required StorageService storageService,
    required GameMode gameMode,
    required AIDifficulty aiDifficulty,
    bool resume = false,
  })  : _aiService = aiService,
        _soundService = soundService,
        _storageService = storageService,
        super(GameStateData(
          engine: ChessEngine(),
          gameMode: gameMode,
          aiDifficulty: aiDifficulty,
        )) {
    if (resume) {
      _resumeGame();
    }
    _updateStatusMessage();
  }

  /// Tries to resume a saved game.
  void _resumeGame() {
    final savedData = _storageService.loadSavedGame();
    if (savedData == null) return;

    final board = savedData['board'] as List<List<ChessPiece?>>;
    final engine = ChessEngine.fromBoard(
      board: board,
      currentPlayer: savedData['currentPlayer'] as Player,
      whiteKingSideCastle: savedData['whiteKingSideCastle'] as bool,
      whiteQueenSideCastle: savedData['whiteQueenSideCastle'] as bool,
      blackKingSideCastle: savedData['blackKingSideCastle'] as bool,
      blackQueenSideCastle: savedData['blackQueenSideCastle'] as bool,
      enPassantTarget: savedData['enPassantTarget'] as Position?,
      halfMoveClock: savedData['halfMoveClock'] as int,
      fullMoveCount: savedData['fullMoveCount'] as int,
    );

    final moveHistory = savedData['moveHistory'] as List<Move>;
    engine.moveHistory.addAll(moveHistory);

    final gameMode = savedData['gameMode'] as GameMode;
    final aiDifficulty = savedData['aiDifficulty'] as AIDifficulty;

    // Re-validate game status after loading saved state
    engine.status = GameStatus.playing;
    engine.updateGameStatus();

    state = GameStateData(
      engine: engine,
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
    );
    _updateStatusMessage();
  }

  /// Handles a tap on a board square.
  void onSquareTap(Position position) {
    if (state.isAIThinking || state.showPromotionDialog) return;
    if (state.engine.status.isGameOver) return;

    // If in AI mode and it's AI's turn, ignore input
    if (state.gameMode == GameMode.pve &&
        state.engine.currentPlayer == Player.black) {
      return;
    }

    final tappedPiece = state.engine.pieceAt(position);

    // If a piece is already selected
    if (state.selectedPosition != null) {
      // Check if tapping on one of the legal move targets
      final isLegalTarget = state.legalMoveTargets.contains(position);

      if (isLegalTarget) {
        _executeMove(state.selectedPosition!, position);
        return;
      }

      // If tapping on own piece, select it instead
      if (tappedPiece != null &&
          tappedPiece.isWhite ==
              (state.engine.currentPlayer == Player.white)) {
        _selectPiece(position);
        return;
      }

      // Deselect
      state = state.copyWith(clearSelection: true);
      return;
    }

    // Select a piece
    if (tappedPiece != null &&
        tappedPiece.isWhite ==
            (state.engine.currentPlayer == Player.white)) {
      _selectPiece(position);
    }
  }

  /// Selects a piece and shows legal moves.
  void _selectPiece(Position position) {
    final engine = state.engine;
    final legalMoves = engine.getLegalMoves();
    final pieceMoves = legalMoves.where((m) => m.from == position).toList();
    final targets = pieceMoves.map((m) => m.to).toList();

    state = state.copyWith(
      selectedPosition: position,
      legalMoveTargets: targets,
    );
  }

  /// Executes a move from [from] to [to].
  void _executeMove(Position from, Position to) {
    final engine = state.engine;
    final legalMoves = engine.getLegalMoves();
    final matchingMoves =
        legalMoves.where((m) => m.from == from && m.to == to).toList();

    if (matchingMoves.isEmpty) return;

    // Check for promotion
    final promotions =
        matchingMoves.where((m) => m.promotionType != null).toList();
    if (promotions.isNotEmpty) {
      state = state.copyWith(
        showPromotionDialog: true,
        promotionPosition: to,
        promotionMoves: promotions,
        clearSelection: true,
      );
      return;
    }

    _applyMove(matchingMoves.first);
  }

  /// Applies a move and triggers AI response if needed.
  void _applyMove(Move move) {
    final engine = state.engine;

    // Sound effects
    if (move.isCastling) {
      // Castling sound is same as move
    }
    if (move.capturedPiece != null) {
      _soundService.playCapture();
    } else {
      _soundService.playMove();
    }

    engine.makeMove(move);

    // Save game automatically
    _autoSaveGame();

    // Update state
    state = state.copyWith(
      engine: engine,
      lastMove: move,
      clearSelection: true,
      legalMoveTargets: [],
    );

    _updateStatusMessage();

    // Check for game over
    if (engine.status.isGameOver) {
      _soundService.playGameOver();
      _updateStatistics();
      _storageService.clearSavedGame();
      return;
    }

    // Play check sound
    if (engine.status == GameStatus.check) {
      _soundService.playCheck();
    }

    // Trigger AI move
    if (state.gameMode == GameMode.pve &&
        engine.currentPlayer == Player.black &&
        !engine.status.isGameOver) {
      _triggerAIMove();
    }
  }

  /// Triggers the AI to make a move asynchronously.
  Future<void> _triggerAIMove() async {
    state = state.copyWith(isAIThinking: true);

    // Small delay for realism
    await Future.delayed(const Duration(milliseconds: 500));

    final bestMove = _aiService.findBestMove(
      state.engine,
      state.aiDifficulty,
    );

    if (bestMove != null && !state.engine.status.isGameOver) {
      // Need to find the legal move matching AI's choice
      final legalMoves = state.engine.getLegalMoves();
      final matchingMove = legalMoves.firstWhere(
        (m) =>
            m.from == bestMove.from &&
            m.to == bestMove.to &&
            m.promotionType == bestMove.promotionType,
        orElse: () => bestMove,
      );

      if (matchingMove.capturedPiece != null) {
        _soundService.playCapture();
      } else {
        _soundService.playMove();
      }

      state.engine.makeMove(matchingMove);

      _autoSaveGame();

      state = state.copyWith(
        engine: state.engine,
        lastMove: matchingMove,
        isAIThinking: false,
      );

      _updateStatusMessage();

      if (state.engine.status.isGameOver) {
        _soundService.playGameOver();
        _updateStatistics();
        _storageService.clearSavedGame();
      } else if (state.engine.status == GameStatus.check) {
        _soundService.playCheck();
      }
    } else {
      state = state.copyWith(isAIThinking: false);
    }
  }

  /// Handles pawn promotion selection.
  void onPromotionSelected(PieceType type) {
    if (state.promotionMoves == null) return;

    final move = state.promotionMoves!
        .firstWhere((m) => m.promotionType == type);

    state = state.copyWith(
      showPromotionDialog: false,
      promotionPosition: null,
      promotionMoves: null,
    );

    _applyMove(move);
  }

  /// Undoes the last move (and AI's move in PvE mode).
  void undoMove() {
    if (state.moveHistory.isEmpty || state.isAIThinking) return;

    // In PvE mode, undo both AI move and player's last move
    if (state.gameMode == GameMode.pve && state.engine.moveHistory.length >= 2) {
      state.engine.undoLastMove(); // Undo AI move
      state.engine.undoLastMove(); // Undo player move
    } else {
      state.engine.undoLastMove();
    }

    _autoSaveGame();

    state = state.copyWith(
      engine: state.engine,
      clearSelection: true,
      lastMove: state.engine.moveHistory.isNotEmpty
          ? state.engine.moveHistory.last
          : null,
      legalMoveTargets: [],
      isAIThinking: false,
    );

    _updateStatusMessage();
  }

  /// Restarts the game.
  void restartGame() {
    state.engine.reset();

    state = state.copyWith(
      engine: state.engine,
      clearSelection: true,
      clearLastMove: true,
      legalMoveTargets: [],
      isAIThinking: false,
    );

    _updateStatusMessage();
    _storageService.clearSavedGame();

    // If in PvE mode, trigger AI for first move (unlikely but possible)
  }

  /// Updates the status message based on game state.
  void _updateStatusMessage() {
    final engine = state.engine;
    String message;

    switch (engine.status) {
      case GameStatus.playing:
        message = '${engine.currentPlayer.label}\'s turn';
        break;
      case GameStatus.check:
        message = '${engine.currentPlayer.label} is in check!';
        break;
      case GameStatus.checkmate:
        message = 'Checkmate! ${engine.winner?.label ?? ""} wins!';
        break;
      case GameStatus.stalemate:
        message = 'Stalemate - Draw';
        break;
      case GameStatus.drawThreefoldRepetition:
        message = 'Draw by threefold repetition';
        break;
      case GameStatus.drawFiftyMoveRule:
        message = 'Draw by 50-move rule';
        break;
      case GameStatus.drawInsufficientMaterial:
        message = 'Draw - insufficient material';
        break;
      case GameStatus.drawAgreement:
        message = 'Draw';
        break;
    }

    state = state.copyWith(statusMessage: message);
  }

  /// Updates game statistics after a game ends.
  void _updateStatistics() {
    final stats = _storageService.loadStatistics();
    stats.totalGames++;

    switch (state.engine.status) {
      case GameStatus.checkmate:
        if (state.gameMode == GameMode.pvp) {
          stats.wins++;
        } else {
          // Player is the one who isn't the current player (since turn switched)
          if (state.engine.winner == Player.white) {
            stats.wins++;
          } else {
            stats.losses++;
          }
        }
        break;
      case GameStatus.stalemate:
      case GameStatus.drawThreefoldRepetition:
      case GameStatus.drawFiftyMoveRule:
      case GameStatus.drawInsufficientMaterial:
        stats.draws++;
        break;
      default:
        break;
    }

    _storageService.saveStatistics(stats);
  }

  /// Auto-saves the current game.
  void _autoSaveGame() {
    final engine = state.engine;
    if (engine.status.isGameOver) return;

    _storageService.saveGame(
      board: engine.board,
      currentPlayer: engine.currentPlayer,
      whiteKingSideCastle: engine.whiteKingSideCastle,
      whiteQueenSideCastle: engine.whiteQueenSideCastle,
      blackKingSideCastle: engine.blackKingSideCastle,
      blackQueenSideCastle: engine.blackQueenSideCastle,
      enPassantTarget: engine.enPassantTarget,
      halfMoveClock: engine.halfMoveClock,
      fullMoveCount: engine.fullMoveCount,
      moveHistory: engine.moveHistory,
      gameMode: state.gameMode,
      aiDifficulty: state.aiDifficulty,
    );
  }
}

/// Provider for the game state.
final gameProvider =
    StateNotifierProvider.autoDispose<GameNotifier, GameStateData>((ref) {
  throw UnimplementedError('Game provider must be created with parameters');
});

/// Creates a game provider with specific parameters.
/// Use this when navigating to the game screen.
GameNotifier createGameNotifier(
  Ref ref, {
  required GameMode gameMode,
  required AIDifficulty aiDifficulty,
  bool resume = false,
}) {
  return GameNotifier(
    aiService: AIService(),
    soundService: SoundService(),
    storageService: StorageService(),
    gameMode: gameMode,
    aiDifficulty: aiDifficulty,
    resume: resume,
  );
}
