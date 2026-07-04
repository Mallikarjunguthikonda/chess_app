import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/player.dart';

/// Displays the current game status including whose turn it is,
/// check/checkmate/stalemate warnings, and game over state.
class GameStatusBar extends StatelessWidget {
  final GameStatus status;
  final Player currentPlayer;
  final Player? winner;
  final int moveCount;

  const GameStatusBar({
    super.key,
    required this.status,
    required this.currentPlayer,
    this.winner,
    required this.moveCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    IconData icon;
    String text;

    switch (status) {
      case GameStatus.playing:
        backgroundColor = theme.colorScheme.primaryContainer;
        icon = currentPlayer == Player.white
            ? Icons.light_mode
            : Icons.dark_mode;
        text = '${currentPlayer.label}\'s Turn';
        break;
      case GameStatus.check:
        backgroundColor = Colors.orange.shade700;
        icon = Icons.warning_amber;
        text = '${currentPlayer.label} is in Check!';
        break;
      case GameStatus.checkmate:
        backgroundColor = Colors.red.shade700;
        icon = Icons.emoji_events;
        text = 'Checkmate! ${winner?.label ?? ""} Wins!';
        break;
      case GameStatus.stalemate:
        backgroundColor = Colors.grey.shade700;
        icon = Icons.handshake;
        text = 'Stalemate - Draw';
        break;
      case GameStatus.drawThreefoldRepetition:
        backgroundColor = Colors.grey.shade700;
        icon = Icons.repeat;
        text = 'Draw (Threefold Repetition)';
        break;
      case GameStatus.drawFiftyMoveRule:
        backgroundColor = Colors.grey.shade700;
        icon = Icons.timer_off;
        text = 'Draw (50-Move Rule)';
        break;
      case GameStatus.drawInsufficientMaterial:
        backgroundColor = Colors.grey.shade700;
        icon = Icons.block;
        text = 'Draw (Insufficient Material)';
        break;
      case GameStatus.drawAgreement:
        backgroundColor = Colors.grey.shade700;
        icon = Icons.handshake;
        text = 'Draw';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Move $moveCount',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
