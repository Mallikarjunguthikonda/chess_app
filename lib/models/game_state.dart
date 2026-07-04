/// Represents the current status of a chess game.
enum GameStatus {
  playing,
  check,
  checkmate,
  stalemate,
  drawThreefoldRepetition,
  drawFiftyMoveRule,
  drawInsufficientMaterial,
  drawAgreement;

  bool get isGameOver => this != playing && this != check;

  String get label {
    switch (this) {
      case GameStatus.playing:
        return 'Playing';
      case GameStatus.check:
        return 'Check!';
      case GameStatus.checkmate:
        return 'Checkmate!';
      case GameStatus.stalemate:
        return 'Stalemate';
      case GameStatus.drawThreefoldRepetition:
        return 'Draw (Threefold Repetition)';
      case GameStatus.drawFiftyMoveRule:
        return 'Draw (50-Move Rule)';
      case GameStatus.drawInsufficientMaterial:
        return 'Draw (Insufficient Material)';
      case GameStatus.drawAgreement:
        return 'Draw';
    }
  }

  String get resultLabel {
    switch (this) {
      case GameStatus.checkmate:
        return 'Checkmate';
      case GameStatus.stalemate:
        return 'Stalemate';
      case GameStatus.drawThreefoldRepetition:
        return 'Draw by Repetition';
      case GameStatus.drawFiftyMoveRule:
        return 'Draw by 50-Move Rule';
      case GameStatus.drawInsufficientMaterial:
        return 'Draw - Insufficient Material';
      case GameStatus.drawAgreement:
        return 'Draw';
      default:
        return '';
    }
  }
}

/// The game mode.
enum GameMode {
  pvp,
  pve;

  String get label => this == pvp ? 'Player vs Player' : 'Player vs AI';
}

/// AI difficulty level.
enum AIDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case AIDifficulty.easy:
        return 'Easy';
      case AIDifficulty.medium:
        return 'Medium';
      case AIDifficulty.hard:
        return 'Hard';
    }
  }

  /// Search depth for minimax.
  int get searchDepth {
    switch (this) {
      case AIDifficulty.easy:
        return 2;
      case AIDifficulty.medium:
        return 3;
      case AIDifficulty.hard:
        return 4;
    }
  }

  /// Whether to add randomness to moves (for easier difficulty).
  bool get addRandomness {
    switch (this) {
      case AIDifficulty.easy:
        return true;
      case AIDifficulty.medium:
        return false;
      case AIDifficulty.hard:
        return false;
    }
  }
}

/// Represents a snapshot of the board for threefold repetition detection.
class BoardState {
  final String fen;

  const BoardState(this.fen);

  @override
  bool operator ==(Object other) =>
      other is BoardState && fen == other.fen;

  @override
  int get hashCode => fen.hashCode;
}

/// Statistics for a completed game.
class GameStatistics {
  int wins;
  int losses;
  int draws;
  int totalGames;

  GameStatistics({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalGames = 0,
  });

  factory GameStatistics.fromMap(Map<String, dynamic> map) {
    return GameStatistics(
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      draws: map['draws'] as int? ?? 0,
      totalGames: map['totalGames'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'totalGames': totalGames,
      };
}
