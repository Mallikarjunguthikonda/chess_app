/// Represents a position on the chess board.
///
/// [row] ranges from 0 (rank 8 / black's back rank) to 7 (rank 1 / white's back rank).
/// [col] ranges from 0 (a-file) to 7 (h-file).
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  /// Creates a position from algebraic notation (e.g., "e4").
  factory Position.fromAlgebraic(String notation) {
    final col = notation.codeUnitAt(0) - 97; // 'a' = 97
    final row = 8 - int.parse(notation[1]);
    return Position(row, col);
  }

  /// Converts to algebraic notation (e.g., "e4").
  String get algebraic {
    final file = String.fromCharCode(col + 97);
    final rank = 8 - row;
    return '$file$rank';
  }

  /// Checks if the position is within the 8x8 board.
  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  @override
  bool operator ==(Object other) =>
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row * 8 + col;

  Position operator +(Position other) => Position(row + other.row, col + other.col);

  Position operator -(Position other) => Position(row - other.row, col - other.col);

  @override
  String toString() => 'Position($algebraic)';
}
