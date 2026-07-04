import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../providers/game_provider.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/move_history_panel.dart';
import '../widgets/captured_pieces_widget.dart';
import '../widgets/promotion_dialog.dart';
import '../widgets/game_status_bar.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../services/ai_service.dart';
import '../services/sound_service.dart';
import '../services/chess_engine.dart';
import '../services/storage_service.dart';

/// Main game screen with the chess board, controls, and side panels.
///
/// Layout adapts responsively:
///   - Phone portrait: Board on top, controls and history below
///   - Landscape/Tablet: Board on left, panels on right
class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final AIDifficulty aiDifficulty;
  final bool resume;

  const GameScreen({
    super.key,
    required this.gameMode,
    required this.aiDifficulty,
    this.resume = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameNotifier _gameNotifier;
  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _gameNotifier = GameNotifier(
      aiService: AIService(),
      soundService: SoundService(),
      storageService: StorageService(),
      gameMode: widget.gameMode,
      aiDifficulty: widget.aiDifficulty,
      resume: widget.resume,
    );
    // Rebuild UI whenever game state changes
    _stateSubscription = _gameNotifier.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _gameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = _gameNotifier.state;
    final engine = gameState.engine;
    final theme = Theme.of(context);

    final kingInCheck = engine.status == GameStatus.check;
    final kingPos = engine.currentPlayer == Player.white
        ? engine.whiteKingPos
        : engine.blackKingPos;

    // Show promotion dialog when needed
    if (gameState.showPromotionDialog && gameState.promotionMoves != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_gameNotifier.state.showPromotionDialog) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PromotionDialog(
            isWhite: engine.currentPlayer == Player.white,
            onSelected: (type) => _gameNotifier.onPromotionSelected(type),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gameMode == GameMode.pvp ? 'Player vs Player' : 'Player vs AI',
        ),
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo move',
            onPressed: engine.moveHistory.isNotEmpty && !gameState.isAIThinking
                ? () => _gameNotifier.undoMove()
                : null,
          ),
          // Restart button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New game',
            onPressed: () => _confirmRestart(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                constraints.maxWidth > constraints.maxHeight;
            return isLandscape
                ? _buildLandscapeLayout(gameState, engine, kingInCheck, kingPos, theme)
                : _buildPortraitLayout(gameState, engine, kingInCheck, kingPos, theme);
          },
        ),
      ),
    );
  }

  /// Portrait layout: board and status on top, controls and history below.
  Widget _buildPortraitLayout(
    GameStateData gameState,
    ChessEngine engine,
    bool kingInCheck,
    Position kingPos,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Game status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: GameStatusBar(
            status: engine.status,
            currentPlayer: engine.currentPlayer,
            winner: engine.winner,
            moveCount: engine.fullMoveCount,
          ),
        ),
        // Board area
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                ChessBoardWidget(
                  board: engine.board,
                  selectedPosition: gameState.selectedPosition,
                  legalMoveTargets: gameState.legalMoveTargets,
                  lastMove: gameState.lastMove,
                  isInCheck: kingInCheck,
                  kingInCheckPosition: kingPos,
                  isAIThinking: gameState.isAIThinking,
                  onSquareTap: (pos) => _gameNotifier.onSquareTap(pos),
                ),
                // AI thinking overlay
                if (gameState.isAIThinking)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AIThinkingIndicator(),
                  ),
              ],
            ),
          ),
        ),
        // Captured pieces
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CapturedPiecesWidget(
            capturedByWhite: engine.getCapturedPieces(Player.white),
            capturedByBlack: engine.getCapturedPieces(Player.black),
          ),
        ),
        // Move history and controls
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                // Control buttons
                Row(
                  children: [
                    if (engine.status.isGameOver)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _gameNotifier.restartGame(),
                          child: const Text('Play Again'),
                        ),
                      ),
                    if (engine.status.isGameOver && widget.gameMode == GameMode.pvp)
                      const SizedBox(width: 8),
                    if (engine.status.isGameOver)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Main Menu'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MoveHistoryPanel(moves: engine.moveHistory),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Landscape layout: board on left, panels on right.
  Widget _buildLandscapeLayout(
    GameStateData gameState,
    ChessEngine engine,
    bool kingInCheck,
    Position kingPos,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // Left: Board and status
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                GameStatusBar(
                  status: engine.status,
                  currentPlayer: engine.currentPlayer,
                  winner: engine.winner,
                  moveCount: engine.fullMoveCount,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      ChessBoardWidget(
                        board: engine.board,
                        selectedPosition: gameState.selectedPosition,
                        legalMoveTargets: gameState.legalMoveTargets,
                        lastMove: gameState.lastMove,
                        isInCheck: kingInCheck,
                        kingInCheckPosition: kingPos,
                        isAIThinking: gameState.isAIThinking,
                        onSquareTap: (pos) =>
                            _gameNotifier.onSquareTap(pos),
                      ),
                      if (gameState.isAIThinking)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: AIThinkingIndicator(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                CapturedPiecesWidget(
                  capturedByWhite: engine.getCapturedPieces(Player.white),
                  capturedByBlack: engine.getCapturedPieces(Player.black),
                ),
              ],
            ),
          ),
        ),
        // Right: Controls and move history
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
            child: Column(
              children: [
                if (engine.status.isGameOver) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _gameNotifier.restartGame(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Play Again'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Menu'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: MoveHistoryPanel(moves: engine.moveHistory),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows a confirmation dialog before restarting.
  void _confirmRestart() {
    if (_gameNotifier.state.engine.moveHistory.isEmpty) {
      _gameNotifier.restartGame();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart Game?'),
        content: const Text(
            'Are you sure you want to start a new game? Current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _gameNotifier.restartGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}
