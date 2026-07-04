import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// Displays captured pieces for both players.
///
/// Shows captured pieces by white (black pieces taken by white) on the left,
/// and captured pieces by black (white pieces taken by black) on the right.
///
/// [whiteCaptured] = pieces captured BY white (i.e. black pieces removed).
/// [blackCaptured] = pieces captured BY black (i.e. white pieces removed).
class CapturedPiecesWidget extends StatelessWidget {
  final List<ChessPiece> capturedByWhite;
  final List<ChessPiece> capturedByBlack;

  const CapturedPiecesWidget({
    super.key,
    required this.capturedByWhite,
    required this.capturedByBlack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Pieces captured by White (black pieces)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Captured by White',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 0,
                runSpacing: 0,
                children: _buildCapturedPieces(capturedByWhite, false),
              ),
            ],
          ),
        ),
        // Pieces captured by Black (white pieces)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Captured by Black',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 0,
                runSpacing: 0,
                alignment: WrapAlignment.end,
                children: _buildCapturedPieces(capturedByBlack, true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCapturedPieces(List<ChessPiece> pieces, bool isWhite) {
    // Sort by material value descending
    final sorted = List<ChessPiece>.from(pieces)
      ..sort((a, b) => b.type.value.compareTo(a.type.value));

    return sorted.map((piece) {
      return Padding(
        padding: const EdgeInsets.all(1),
        child: Text(
          piece.unicode,
          style: TextStyle(
            fontSize: isWhite ? 18 : 18,
            color: isWhite ? Colors.white : Colors.black,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 1,
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
