import 'package:flutter/material.dart';
import '../models/move.dart';

/// Displays the move history in a scrollable list with move numbers.
///
/// Shows moves in standard chess notation format (e.g., "1. e4 e5 2. Nf3 Nc6").
class MoveHistoryPanel extends StatelessWidget {
  final List<Move> moves;

  const MoveHistoryPanel({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              'Moves',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: moves.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No moves yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: (moves.length + 1) ~/ 2,
                    itemBuilder: (context, index) {
                      final moveNumber = index + 1;
                      final whiteMove = index * 2 < moves.length
                          ? moves[index * 2]
                          : null;
                      final blackMove = index * 2 + 1 < moves.length
                          ? moves[index * 2 + 1]
                          : null;

                      return _MoveRow(
                        moveNumber: moveNumber,
                        whiteMove: whiteMove,
                        blackMove: blackMove,
                        isLastRow:
                            index == (moves.length + 1) ~/ 2 - 1,
                        movesLength: moves.length,
                        theme: theme,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the move history showing move number, white's move, black's move.
class _MoveRow extends StatelessWidget {
  final int moveNumber;
  final Move? whiteMove;
  final Move? blackMove;
  final bool isLastRow;
  final int movesLength;
  final ThemeData theme;

  const _MoveRow({
    required this.moveNumber,
    this.whiteMove,
    this.blackMove,
    required this.isLastRow,
    required this.movesLength,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final whiteIndex = (moveNumber - 1) * 2;
    final blackIndex = whiteIndex + 1;
    final isWhiteLatest = whiteMove != null && whiteIndex == movesLength - 1;
    final isBlackLatest = blackMove != null && blackIndex == movesLength - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$moveNumber.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: _MoveCell(
              move: whiteMove,
              isLatest: isWhiteLatest,
              theme: theme,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _MoveCell(
              move: blackMove,
              isLatest: isBlackLatest,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single move cell with optional highlighting for the latest move.
class _MoveCell extends StatelessWidget {
  final Move? move;
  final bool isLatest;
  final ThemeData theme;

  const _MoveCell({
    required this.move,
    required this.isLatest,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (move == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isLatest
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        move!.notation,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: isLatest ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
