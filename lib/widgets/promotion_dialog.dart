import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/player.dart';

/// Dialog shown when a pawn reaches the promotion rank.
///
/// Allows the player to choose which piece to promote to:
/// Queen, Rook, Bishop, or Knight.
class PromotionDialog extends StatelessWidget {
  final bool isWhite;
  final void Function(PieceType type) onSelected;

  const PromotionDialog({
    super.key,
    required this.isWhite,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Promote Pawn',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a piece for promotion:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PromotionButton(
                  type: PieceType.queen,
                  isWhite: isWhite,
                  onTap: () => onSelected(PieceType.queen),
                ),
                _PromotionButton(
                  type: PieceType.rook,
                  isWhite: isWhite,
                  onTap: () => onSelected(PieceType.rook),
                ),
                _PromotionButton(
                  type: PieceType.bishop,
                  isWhite: isWhite,
                  onTap: () => onSelected(PieceType.bishop),
                ),
                _PromotionButton(
                  type: PieceType.knight,
                  isWhite: isWhite,
                  onTap: () => onSelected(PieceType.knight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A button showing a chess piece for promotion selection.
class _PromotionButton extends StatelessWidget {
  final PieceType type;
  final bool isWhite;
  final VoidCallback onTap;

  const _PromotionButton({
    required this.type,
    required this.isWhite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final piece = ChessPiece(type: type, isWhite: isWhite);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              piece.unicode,
              style: TextStyle(
                fontSize: 36,
                color: isWhite ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
