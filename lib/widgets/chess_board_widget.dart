import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/position.dart';
import '../models/move.dart';
import 'chess_piece_widget.dart';

/// Interactive chess board that renders squares, pieces, and highlights.
///
/// Features:
///   - Standard 8x8 board with alternating colors
///   - Highlights legal moves with dots
///   - Highlights the last move squares
///   - Shows check warning on the king
///   - Smooth piece animations
class ChessBoardWidget extends StatelessWidget {
  final List<List<ChessPiece?>> board;
  final Position? selectedPosition;
  final List<Position> legalMoveTargets;
  final Move? lastMove;
  final bool isInCheck;
  final Position? kingInCheckPosition;
  final bool isAIThinking;
  final void Function(Position position)? onSquareTap;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.selectedPosition,
    this.legalMoveTargets = const [],
    this.lastMove,
    this.isInCheck = false,
    this.kingInCheckPosition,
    this.isAIThinking = false,
    this.onSquareTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final squareSize = constraints.maxWidth / 8;
            return GestureDetector(
              onTapUp: isAIThinking
                  ? null
                  : (details) {
                      final col = (details.localPosition.dx / squareSize)
                          .floor()
                          .clamp(0, 7);
                      final row = (details.localPosition.dy / squareSize)
                          .floor()
                          .clamp(0, 7);
                      onSquareTap?.call(Position(row, col));
                    },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.brown.shade700,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: _BoardPainter(
                      board: board,
                      squareSize: squareSize,
                      selectedPosition: selectedPosition,
                      legalMoveTargets: legalMoveTargets,
                      lastMove: lastMove,
                      isInCheck: isInCheck,
                      kingInCheckPosition: kingInCheckPosition,
                    ),
                    child: Stack(
                      children: [
                        // Render pieces
                        ...List.generate(8, (row) {
                          return ...List.generate(8, (col) {
                            final piece = board[row][col];
                            if (piece == null) {
                              return const SizedBox.shrink();
                            }

                            final isSelected = selectedPosition != null &&
                                selectedPosition!.row == row &&
                                selectedPosition!.col == col;

                            return Positioned(
                              left: col * squareSize,
                              top: row * squareSize,
                              width: squareSize,
                              height: squareSize,
                              child: AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: ChessPieceWidget(
                                  piece: piece,
                                  size: squareSize,
                                  isSelected: isSelected,
                                ),
                              ),
                            );
                          });
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the board background (squares and highlights).
class _BoardPainter extends CustomPainter {
  final List<List<ChessPiece?>> board;
  final double squareSize;
  final Position? selectedPosition;
  final List<Position> legalMoveTargets;
  final Move? lastMove;
  final bool isInCheck;
  final Position? kingInCheckPosition;

  _BoardPainter({
    required this.board,
    required this.squareSize,
    this.selectedPosition,
    this.legalMoveTargets = const [],
    this.lastMove,
    this.isInCheck = false,
    this.kingInCheckPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw squares
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );

        final paint = Paint()
          ..color = isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
        canvas.drawRect(rect, paint);
      }
    }

    // Highlight last move
    if (lastMove != null) {
      _highlightSquare(canvas, lastMove!.from, const Color(0x44FFFF00));
      _highlightSquare(canvas, lastMove!.to, const Color(0x44FFFF00));
    }

    // Highlight selected square
    if (selectedPosition != null) {
      _highlightSquare(
          canvas, selectedPosition!, const Color(0x4464FFDA));
    }

    // Highlight legal move targets
    for (final target in legalMoveTargets) {
      final piece = board[target.row][target.col];
      if (piece != null) {
        // Capture highlight (ring around square)
        _highlightCaptureSquare(canvas, target);
      } else {
        // Empty square highlight (dot)
        _highlightDot(canvas, target);
      }
    }

    // Highlight king in check
    if (isInCheck && kingInCheckPosition != null) {
      _highlightSquare(canvas, kingInCheckPosition!, const Color(0x66FF0000));
    }
  }

  void _highlightSquare(Canvas canvas, Position pos, Color color) {
    final rect = Rect.fromLTWH(
      pos.col * squareSize,
      pos.row * squareSize,
      squareSize,
      squareSize,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _highlightDot(Canvas canvas, Position pos) {
    final center = Offset(
      pos.col * squareSize + squareSize / 2,
      pos.row * squareSize + squareSize / 2,
    );
    canvas.drawCircle(
      center,
      squareSize * 0.15,
      Paint()
        ..color = const Color(0x44000000)
        ..style = PaintingStyle.fill,
    );
  }

  void _highlightCaptureSquare(Canvas canvas, Position pos) {
    final rect = Rect.fromLTWH(
      pos.col * squareSize,
      pos.row * squareSize,
      squareSize,
      squareSize,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0x44FF0000)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0x88FF0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}
