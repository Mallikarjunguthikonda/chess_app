/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Board dimensions.
  static const int boardSize = 8;

  /// App name.
  static const String appName = 'Chess';

  /// File names for sound assets.
  static const String soundMove = 'sounds/move.wav';
  static const String soundCapture = 'sounds/capture.wav';
  static const String soundCheck = 'sounds/check.wav';
  static const String soundGameOver = 'sounds/game_over.wav';

  /// Default AI delay in milliseconds (for realism).
  static const int aiThinkingDelayMs = 500;

  /// Maximum moves to display in history without scrolling.
  static const int maxVisibleMoves = 30;

  /// Box names for Hive storage.
  static const String hiveSettingsBox = 'chess_settings';
  static const String hiveStatsBox = 'chess_stats';
  static const String hiveGameBox = 'chess_saved_game';
}

/// Board colors for light and dark squares.
class BoardColors {
  BoardColors._();

  static const Color lightSquare = Color(0xFFF0D9B5);
  static const Color darkSquare = Color(0xFFB58863);
  static const Color selectedSquare = Color(0x4464FFDA);
  static const Color lastMoveHighlight = Color(0x44FFFF00);
  static const Color legalMoveDot = Color(0x44000000);
  static const Color captureHighlight = Color(0x44FF0000);
  static const Color checkHighlight = Color(0x66FF0000);
}

/// Material values for pieces (used in AI evaluation).
class PieceValues {
  PieceValues._();

  static const int pawn = 100;
  static const int knight = 320;
  static const int bishop = 330;
  static const int rook = 500;
  static const int queen = 900;
  static const int king = 20000;
}
