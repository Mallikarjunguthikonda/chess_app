import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_state.dart';
import '../models/settings.dart';
import '../models/move.dart';
import '../models/chess_piece.dart';
import '../models/position.dart';
import '../models/player.dart';

/// Service for persisting game state, settings, and statistics
/// using Hive local storage.
class StorageService {
  static const String _settingsBox = 'chess_settings';
  static const String _statsBox = 'chess_stats';
  static const String _gameBox = 'chess_saved_game';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_statsBox);
    await Hive.openBox(_gameBox);
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Saves app settings.
  Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box(_settingsBox);
    await box.putAll(settings.toMap());
  }

  /// Loads app settings, returning defaults if none saved.
  AppSettings loadSettings() {
    final box = Hive.box(_settingsBox);
    if (box.isEmpty) return const AppSettings();
    return AppSettings.fromMap(box.toMap().cast<String, dynamic>());
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  /// Saves game statistics.
  Future<void> saveStatistics(GameStatistics stats) async {
    final box = Hive.box(_statsBox);
    await box.putAll(stats.toMap());
  }

  /// Loads game statistics.
  GameStatistics loadStatistics() {
    final box = Hive.box(_statsBox);
    if (box.isEmpty) return GameStatistics();
    return GameStatistics.fromMap(box.toMap().cast<String, dynamic>());
  }

  // ---------------------------------------------------------------------------
  // Saved Game
  // ---------------------------------------------------------------------------

  /// Saves the current game state for resume functionality.
  Future<void> saveGame({
    required List<List<ChessPiece?>> board,
    required Player currentPlayer,
    required bool whiteKingSideCastle,
    required bool whiteQueenSideCastle,
    required bool blackKingSideCastle,
    required bool blackQueenSideCastle,
    required Position? enPassantTarget,
    required int halfMoveClock,
    required int fullMoveCount,
    required List<Move> moveHistory,
    required GameMode gameMode,
    required AIDifficulty aiDifficulty,
  }) async {
    final box = Hive.box(_gameBox);

    final boardData = board.map((row) {
      return row.map((piece) {
        if (piece == null) return null;
        return {
          'type': piece.type.index,
          'isWhite': piece.isWhite,
          'hasMoved': piece.hasMoved,
        };
      }).toList();
    }).toList();

    final movesData = moveHistory.map((move) {
      return {
        'fromRow': move.from.row,
        'fromCol': move.from.col,
        'toRow': move.to.row,
        'toCol': move.to.col,
        'pieceType': move.piece.type.index,
        'pieceIsWhite': move.piece.isWhite,
        'pieceHasMoved': move.piece.hasMoved,
        'capturedPieceType': move.capturedPiece?.type.index,
        'capturedPieceIsWhite': move.capturedPiece?.isWhite,
        'capturedPieceHasMoved': move.capturedPiece?.hasMoved,
        'isCastling': move.isCastling,
        'isEnPassant': move.isEnPassant,
        'promotionType': move.promotionType?.index,
        'enPassantTargetRow': move.enPassantTarget?.row,
        'enPassantTargetCol': move.enPassantTarget?.col,
        'rookFromRow': move.rookFrom?.row,
        'rookFromCol': move.rookFrom?.col,
        'rookToRow': move.rookTo?.row,
        'rookToCol': move.rookTo?.col,
      };
    }).toList();

    await box.putAll({
      'board': boardData,
      'currentPlayer': currentPlayer.index,
      'whiteKingSideCastle': whiteKingSideCastle,
      'whiteQueenSideCastle': whiteQueenSideCastle,
      'blackKingSideCastle': blackKingSideCastle,
      'blackQueenSideCastle': blackQueenSideCastle,
      'enPassantTargetRow': enPassantTarget?.row,
      'enPassantTargetCol': enPassantTarget?.col,
      'halfMoveClock': halfMoveClock,
      'fullMoveCount': fullMoveCount,
      'moveHistory': movesData,
      'gameMode': gameMode.index,
      'aiDifficulty': aiDifficulty.index,
      'hasSavedGame': true,
    });
  }

  /// Checks if a saved game exists.
  bool hasSavedGame() {
    final box = Hive.box(_gameBox);
    return box.get('hasSavedGame', defaultValue: false) as bool;
  }

  /// Clears saved game data.
  Future<void> clearSavedGame() async {
    final box = Hive.box(_gameBox);
    await box.clear();
  }

  /// Restores a saved game, returning null if none exists.
  Map<String, dynamic>? loadSavedGame() {
    final box = Hive.box(_gameBox);
    if (!hasSavedGame()) return null;

    final boardData = box.get('board') as List<dynamic>?;
    if (boardData == null) return null;

    final board = boardData.map<List<ChessPiece?>>((rowData) {
      return (rowData as List<dynamic>).map<ChessPiece?>((pieceData) {
        if (pieceData == null) return null;
        final p = pieceData as Map<dynamic, dynamic>;
        return ChessPiece(
          type: PieceType.values[p['type'] as int],
          isWhite: p['isWhite'] as bool,
          hasMoved: p['hasMoved'] as bool,
        );
      }).toList();
    }).toList();

    final moveHistoryData = box.get('moveHistory') as List<dynamic>? ?? [];
    final moveHistory = moveHistoryData.map<Move>((m) {
      final data = m as Map<dynamic, dynamic>;

      ChessPiece? capturedPiece;
      if (data['capturedPieceType'] != null) {
        capturedPiece = ChessPiece(
          type: PieceType.values[data['capturedPieceType'] as int],
          isWhite: data['capturedPieceIsWhite'] as bool,
          hasMoved: data['capturedPieceHasMoved'] as bool? ?? false,
        );
      }

      return Move(
        from: Position(data['fromRow'] as int, data['fromCol'] as int),
        to: Position(data['toRow'] as int, data['toCol'] as int),
        piece: ChessPiece(
          type: PieceType.values[data['pieceType'] as int],
          isWhite: data['pieceIsWhite'] as bool,
          hasMoved: data['pieceHasMoved'] as bool? ?? false,
        ),
        capturedPiece: capturedPiece,
        isCastling: data['isCastling'] as bool? ?? false,
        isEnPassant: data['isEnPassant'] as bool? ?? false,
        promotionType: data['promotionType'] != null
            ? PieceType.values[data['promotionType'] as int]
            : null,
        enPassantTarget: data['enPassantTargetRow'] != null
            ? Position(
                data['enPassantTargetRow'] as int,
                data['enPassantTargetCol'] as int)
            : null,
        rookFrom: data['rookFromRow'] != null
            ? Position(data['rookFromRow'] as int, data['rookFromCol'] as int)
            : null,
        rookTo: data['rookToRow'] != null
            ? Position(data['rookToRow'] as int, data['rookToCol'] as int)
            : null,
      );
    }).toList();

    Position? enPassantTarget;
    if (box.get('enPassantTargetRow') != null) {
      enPassantTarget = Position(
        box.get('enPassantTargetRow') as int,
        box.get('enPassantTargetCol') as int,
      );
    }

    return {
      'board': board,
      'currentPlayer':
          Player.values[box.get('currentPlayer', defaultValue: 0) as int],
      'whiteKingSideCastle':
          box.get('whiteKingSideCastle', defaultValue: true) as bool,
      'whiteQueenSideCastle':
          box.get('whiteQueenSideCastle', defaultValue: true) as bool,
      'blackKingSideCastle':
          box.get('blackKingSideCastle', defaultValue: true) as bool,
      'blackQueenSideCastle':
          box.get('blackQueenSideCastle', defaultValue: true) as bool,
      'enPassantTarget': enPassantTarget,
      'halfMoveClock': box.get('halfMoveClock', defaultValue: 0) as int,
      'fullMoveCount': box.get('fullMoveCount', defaultValue: 1) as int,
      'moveHistory': moveHistory,
      'gameMode':
          GameMode.values[box.get('gameMode', defaultValue: 0) as int],
      'aiDifficulty': AIDifficulty
          .values[box.get('aiDifficulty', defaultValue: 1) as int],
    };
  }
}
