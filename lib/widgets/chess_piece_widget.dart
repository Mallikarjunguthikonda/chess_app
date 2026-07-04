import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// Renders a single chess piece with shadows and animations.
class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;
  final bool isSelected;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 48,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = piece.isWhite ? Colors.white : Colors.black;
    final shadowColor = piece.isWhite ? Colors.black26 : Colors.black54;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.yellow.withOpacity(0.6) : shadowColor,
            blurRadius: isSelected ? 8 : 3,
            spreadRadius: isSelected ? 3 : 0,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(size * 0.08),
          child: Text(
            piece.unicode,
            style: TextStyle(
              fontSize: size * 0.8,
              color: color,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
