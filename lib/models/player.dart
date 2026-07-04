/// Represents the two players in a chess game.
enum Player {
  white,
  black;

  /// Returns the opponent of this player.
  Player get opponent => this == white ? black : white;

  /// Returns the index for board arrays (0 for white, 1 for black).
  int get index => this == white ? 0 : 1;

  /// Returns the display name.
  String get label => this == white ? 'White' : 'Black';

  /// Returns the initial for notation.
  String get initial => this == white ? 'w' : 'b';
}
