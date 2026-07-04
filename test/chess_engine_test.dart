import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/position.dart';
import 'package:chess_app/models/move.dart';
import 'package:chess_app/models/player.dart';
import 'package:chess_app/models/game_state.dart';
import 'package:chess_app/services/chess_engine.dart';

void main() {
  group('ChessEngine - Initial Position', () {
    late ChessEngine engine;

    setUp(() {
      engine = ChessEngine();
    });

    test('board has 32 pieces in starting position', () {
      int pieceCount = 0;
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
          if (engine.board[row][col] != null) pieceCount++;
        }
      }
      expect(pieceCount, equals(32));
    });

    test('white pawns are on rank 6', () {
      for (var col = 0; col < 8; col++) {
        final piece = engine.board[6][col];
        expect(piece, isNotNull);
        expect(piece!.type, equals(PieceType.pawn));
        expect(piece.isWhite, isTrue);
      }
    });

    test('black pawns are on rank 1', () {
      for (var col = 0; col < 8; col++) {
        final piece = engine.board[1][col];
        expect(piece, isNotNull);
        expect(piece!.type, equals(PieceType.pawn));
        expect(piece.isWhite, isFalse);
      }
    });

    test('kings are in correct starting positions', () {
      expect(engine.board[7][4]!.type, equals(PieceType.king));
      expect(engine.board[7][4]!.isWhite, isTrue);
      expect(engine.board[0][4]!.type, equals(PieceType.king));
      expect(engine.board[0][4]!.isWhite, isFalse);
    });

    test('white starts first', () {
      expect(engine.currentPlayer, equals(Player.white));
    });

    test('status is playing at start', () {
      expect(engine.status, equals(GameStatus.playing));
    });
  });

  group('ChessEngine - Move Generation', () {
    test('white has 20 legal moves from starting position', () {
      final engine = ChessEngine();
      final moves = engine.getLegalMoves();
      expect(moves.length, equals(20));
    });

    test('pawn can move forward one or two squares from start', () {
      final engine = ChessEngine();
      // e2 pawn at Position(6, 4)
      final pawnMoves = engine.getLegalMoves()
          .where((m) => m.from == const Position(6, 4))
          .toList();
      expect(pawnMoves.length, equals(2)); // e3 and e4
    });

    test('knight has 2 moves from starting position', () {
      final engine = ChessEngine();
      // g1 knight at Position(7, 6)
      final knightMoves = engine.getLegalMoves()
          .where((m) => m.from == const Position(7, 6))
          .toList();
      expect(knightMoves.length, equals(2)); // f3 and h3
    });
  });

  group('ChessEngine - Check Detection', () {
    test('detects check', () {
      // Fool's mate setup
      final engine = ChessEngine();
      // 1. f3
      engine.makeMove(Move.normal(
        from: const Position(6, 5),
        to: const Position(5, 5),
        piece: engine.board[6][5]!,
      ));
      // 1... e5
      engine.makeMove(Move.normal(
        from: const Position(1, 4),
        to: const Position(3, 4),
        piece: engine.board[1][4]!,
      ));
      // 2. g4
      engine.makeMove(Move.normal(
        from: const Position(6, 6),
        to: const Position(4, 6),
        piece: engine.board[6][6]!,
      ));
      // 2... Qh4#
      engine.makeMove(Move.normal(
        from: const Position(0, 3),
        to: const Position(4, 7),
        piece: engine.board[0][3]!,
        capturedPiece: engine.board[4][7],
      ));

      expect(engine.status, equals(GameStatus.checkmate));
      expect(engine.winner, equals(Player.black));
    });

    test('king moves out of check', () {
      final engine = ChessEngine();
      // Set up a simple check scenario
      // Clear board except kings
      for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
          engine.board[row][col] = null;
        }
      }
      // White king at e1
      engine.board[7][4] = ChessPiece(type: PieceType.king, isWhite: true);
      engine.whiteKingPos = const Position(7, 4);
      // Black queen at e2 (giving check)
      engine.board[6][4] = ChessPiece(type: PieceType.queen, isWhite: false);
      engine.currentPlayer = Player.white;
      engine.findKings();

      expect(engine.isInCheck(Player.white), isTrue);
      final moves = engine.getLegalMoves();
      expect(moves.isNotEmpty, isTrue);
      // King must move out of check
      final kingMoves = moves.where((m) => m.piece.type == PieceType.king);
      expect(kingMoves.isNotEmpty, isTrue);
    });
  });

  group('ChessEngine - Castling', () {
    test('king-side castling is available', () {
      final engine = ChessEngine();
      // Clear pieces between king and rook
      engine.board[7][5] = null;
      engine.board[7][6] = null;

      final moves = engine.getLegalMoves();
      final castleMoves = moves.where((m) => m.isCastling);
      expect(castleMoves.isNotEmpty, isTrue);
    });
  });

  group('Position', () {
    test('algebraic notation conversion', () {
      expect(const Position(7, 0).algebraic, equals('a1'));
      expect(const Position(7, 7).algebraic, equals('h1'));
      expect(const Position(0, 0).algebraic, equals('a8'));
      expect(const Position(0, 7).algebraic, equals('h8'));
      expect(const Position(4, 4).algebraic, equals('e4'));
    });

    test('from algebraic notation', () {
      expect(Position.fromAlgebraic('a1'), equals(const Position(7, 0)));
      expect(Position.fromAlgebraic('e4'), equals(const Position(4, 4)));
      expect(Position.fromAlgebraic('h8'), equals(const Position(0, 7)));
    });

    test('isValid returns true for valid positions', () {
      expect(const Position(0, 0).isValid, isTrue);
      expect(const Position(7, 7).isValid, isTrue);
      expect(const Position(3, 4).isValid, isTrue);
    });

    test('isValid returns false for invalid positions', () {
      expect(const Position(-1, 0).isValid, isFalse);
      expect(const Position(0, 8).isValid, isFalse);
      expect(const Position(8, 0).isValid, isFalse);
    });
  });
}
