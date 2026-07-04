import 'chess_piece.dart';
import 'position.dart';

/// Represents a move in a chess game.
///
/// Contains all information needed to make, unmake, and display a move,
/// including special moves like castling, en passant, and promotion.
class Move {
  final Position from;
  final Position to;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final bool isCastling;
  final bool isEnPassant;
  final PieceType? promotionType;
  final Position? enPassantTarget;

  /// For castling, tracks which rook moved and from/to where.
  final Position? rookFrom;
  final Position? rookTo;

  const Move({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.isCastling = false,
    this.isEnPassant = false,
    this.promotionType,
    this.enPassantTarget,
    this.rookFrom,
    this.rookTo,
  });

  /// Creates a standard non-special move.
  factory Move.normal({
    required Position from,
    required Position to,
    required ChessPiece piece,
    ChessPiece? capturedPiece,
  }) {
    return Move(from: from, to: to, piece: piece, capturedPiece: capturedPiece);
  }

  /// Creates a castling move.
  factory Move.castling({
    required Position kingFrom,
    required Position kingTo,
    required ChessPiece king,
    required Position rookFrom,
    required Position rookTo,
    required ChessPiece rook,
  }) {
    return Move(
      from: kingFrom,
      to: kingTo,
      piece: king,
      isCastling: true,
      rookFrom: rookFrom,
      rookTo: rookTo,
    );
  }

  /// Creates an en passant move.
  factory Move.enPassant({
    required Position from,
    required Position to,
    required ChessPiece pawn,
    required ChessPiece capturedPawn,
    required Position capturedPawnPosition,
  }) {
    return Move(
      from: from,
      to: to,
      piece: pawn,
      capturedPiece: capturedPawn,
      isEnPassant: true,
      enPassantTarget: capturedPawnPosition,
    );
  }

  /// Creates a promotion move.
  factory Move.promotion({
    required Position from,
    required Position to,
    required ChessPiece pawn,
    required ChessPiece? capturedPiece,
    required PieceType promoteTo,
  }) {
    return Move(
      from: from,
      to: to,
      piece: pawn,
      capturedPiece: capturedPiece,
      promotionType: promoteTo,
    );
  }

  /// Standard algebraic notation letter for this piece type.
  /// Knight is "N" (not "K", which is King).
  static String _notationLetter(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return '';
      case PieceType.knight:
        return 'N';
      case PieceType.bishop:
        return 'B';
      case PieceType.rook:
        return 'R';
      case PieceType.queen:
        return 'Q';
      case PieceType.king:
        return 'K';
    }
  }

  /// Returns algebraic notation for this move (simplified).
  String get notation {
    final pieceChar = piece.type == PieceType.pawn
        ? ''
        : _notationLetter(piece.type);
    final capture = capturedPiece != null ? 'x' : '';
    final promotion = promotionType != null
        ? '=${_notationLetter(promotionType!)}'
        : '';
    final base = '$pieceChar$capture${to.algebraic}$promotion';

    if (isCastling) {
      return to.col > from.col ? 'O-O' : 'O-O-O';
    }

    return base;
  }

  @override
  String toString() => 'Move: ${from.algebraic} -> ${to.algebraic}';
}
