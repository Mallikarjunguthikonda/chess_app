/// The type of a chess piece.
enum PieceType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king;

  /// Returns the FEN character for this piece type.
  String fenChar(bool isWhite) =>
      isWhite ? _whiteFen : _blackFen;

  String get _whiteFen {
    switch (this) {
      case PieceType.pawn:
        return 'P';
      case PieceType.rook:
        return 'R';
      case PieceType.knight:
        return 'N';
      case PieceType.bishop:
        return 'B';
      case PieceType.queen:
        return 'Q';
      case PieceType.king:
        return 'K';
    }
  }

  String get _blackFen {
    switch (this) {
      case PieceType.pawn:
        return 'p';
      case PieceType.rook:
        return 'r';
      case PieceType.knight:
        return 'n';
      case PieceType.bishop:
        return 'b';
      case PieceType.queen:
        return 'q';
      case PieceType.king:
        return 'k';
    }
  }

  /// Material value for AI evaluation.
  int get value {
    switch (this) {
      case PieceType.pawn:
        return 100;
      case PieceType.rook:
        return 500;
      case PieceType.knight:
        return 320;
      case PieceType.bishop:
        return 330;
      case PieceType.queen:
        return 900;
      case PieceType.king:
        return 20000;
    }
  }
}

/// A chess piece with a type and color.
class ChessPiece {
  final PieceType type;
  final bool isWhite;
  bool hasMoved;

  ChessPiece({
    required this.type,
    required this.isWhite,
    this.hasMoved = false,
  });

  /// Creates a deep copy of this piece.
  ChessPiece copy() => ChessPiece(
        type: type,
        isWhite: isWhite,
        hasMoved: hasMoved,
      );

  /// Unicode character for displaying the piece.
  String get unicode {
    if (isWhite) {
      switch (type) {
        case PieceType.king:
          return '\u2654';
        case PieceType.queen:
          return '\u2655';
        case PieceType.rook:
          return '\u2656';
        case PieceType.bishop:
          return '\u2657';
        case PieceType.knight:
          return '\u2658';
        case PieceType.pawn:
          return '\u2659';
      }
    } else {
      switch (type) {
        case PieceType.king:
          return '\u265A';
        case PieceType.queen:
          return '\u265B';
        case PieceType.rook:
          return '\u265C';
        case PieceType.bishop:
          return '\u265D';
        case PieceType.knight:
          return '\u265E';
        case PieceType.pawn:
          return '\u265F';
      }
    }
  }

  @override
  String toString() => '${isWhite ? "W" : "B"} ${type.name}';
}
