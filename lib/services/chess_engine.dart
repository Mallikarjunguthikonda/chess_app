import '../models/chess_piece.dart';
import '../models/move.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../models/game_state.dart';

/// Core chess engine implementing all rules, move generation, and validation.
///
/// The board is represented as an 8x8 grid where:
///   - board[row][col] gives the piece at that position
///   - Row 0 = rank 8 (black's back rank)
///   - Row 7 = rank 1 (white's back rank)
///   - Col 0 = a-file, Col 7 = h-file
class ChessEngine {
  /// The current board state (8x8 grid).
  List<List<ChessPiece?>> board;

  /// Which player's turn it is.
  Player currentPlayer;

  /// All moves made in the game (for undo).
  final List<Move> moveHistory = [];

  /// Positions for threefold repetition detection.
  final List<String> positionHistory = [];

  /// Castling rights.
  bool whiteKingSideCastle = true;
  bool whiteQueenSideCastle = true;
  bool blackKingSideCastle = true;
  bool blackQueenSideCastle = true;

  /// En passant target square (set after a double pawn push).
  Position? enPassantTarget;

  /// Number of half-moves since last capture or pawn push (for 50-move rule).
  int halfMoveClock = 0;

  /// Full move counter.
  int fullMoveCount = 1;

  /// Kings' positions for quick lookup.
  Position whiteKingPos = const Position(7, 4);
  Position blackKingPos = const Position(0, 4);

  /// Game status.
  GameStatus status = GameStatus.playing;

  /// Who won (if checkmate).
  Player? winner;

  /// Creates a new game with pieces in starting position.
  ChessEngine() : board = List.generate(8, (_) => List.filled(8, null)) {
    _setupBoard();
    positionHistory.add(_boardToFen());
  }

  /// Creates a game from a given board state (for AI analysis).
  ChessEngine.fromBoard({
    required this.board,
    required this.currentPlayer,
    required this.whiteKingSideCastle,
    required this.whiteQueenSideCastle,
    required this.blackKingSideCastle,
    required this.blackQueenSideCastle,
    this.enPassantTarget,
    this.halfMoveClock = 0,
    this.fullMoveCount = 1,
  }) : moveHistory = [],
       positionHistory = [] {
    _findKings();
  }

  /// Sets up the standard starting position.
  void _setupBoard() {
    // Clear board
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        board[row][col] = null;
      }
    }

    // Pawns
    for (var col = 0; col < 8; col++) {
      board[1][col] = ChessPiece(type: PieceType.pawn, isWhite: false);
      board[6][col] = ChessPiece(type: PieceType.pawn, isWhite: true);
    }

    // Black back rank
    board[0][0] = ChessPiece(type: PieceType.rook, isWhite: false);
    board[0][1] = ChessPiece(type: PieceType.knight, isWhite: false);
    board[0][2] = ChessPiece(type: PieceType.bishop, isWhite: false);
    board[0][3] = ChessPiece(type: PieceType.queen, isWhite: false);
    board[0][4] = ChessPiece(type: PieceType.king, isWhite: false);
    board[0][5] = ChessPiece(type: PieceType.bishop, isWhite: false);
    board[0][6] = ChessPiece(type: PieceType.knight, isWhite: false);
    board[0][7] = ChessPiece(type: PieceType.rook, isWhite: false);

    // White back rank
    board[7][0] = ChessPiece(type: PieceType.rook, isWhite: true);
    board[7][1] = ChessPiece(type: PieceType.knight, isWhite: true);
    board[7][2] = ChessPiece(type: PieceType.bishop, isWhite: true);
    board[7][3] = ChessPiece(type: PieceType.queen, isWhite: true);
    board[7][4] = ChessPiece(type: PieceType.king, isWhite: true);
    board[7][5] = ChessPiece(type: PieceType.bishop, isWhite: true);
    board[7][6] = ChessPiece(type: PieceType.knight, isWhite: true);
    board[7][7] = ChessPiece(type: PieceType.rook, isWhite: true);

    currentPlayer = Player.white;
  }

  /// Public wrapper for finding and storing king positions.
  void findKings() => _findKings();

  /// Finds and stores king positions.
  void _findKings() {
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece != null && piece.type == PieceType.king) {
          if (piece.isWhite) {
            whiteKingPos = Position(row, col);
          } else {
            blackKingPos = Position(row, col);
          }
        }
      }
    }
  }

  /// Returns the king position for the given player.
  Position _kingPos(Player player) =>
      player == Player.white ? whiteKingPos : blackKingPos;

  /// Generates all pseudo-legal moves for a piece at [pos].
  /// Pseudo-legal means the moves are valid for the piece type
  /// but may leave the king in check.
  List<Move> _generatePseudoMoves(Position pos) {
    final piece = board[pos.row][pos.col];
    if (piece == null) return [];

    final moves = <Move>[];

    switch (piece.type) {
      case PieceType.pawn:
        _addPawnMoves(pos, piece, moves);
        break;
      case PieceType.rook:
        _addSlidingMoves(pos, piece, moves, [
          Position(-1, 0),
          Position(1, 0),
          Position(0, -1),
          Position(0, 1),
        ]);
        break;
      case PieceType.knight:
        _addKnightMoves(pos, piece, moves);
        break;
      case PieceType.bishop:
        _addSlidingMoves(pos, piece, moves, [
          Position(-1, -1),
          Position(-1, 1),
          Position(1, -1),
          Position(1, 1),
        ]);
        break;
      case PieceType.queen:
        _addSlidingMoves(pos, piece, moves, [
          Position(-1, 0),
          Position(1, 0),
          Position(0, -1),
          Position(0, 1),
          Position(-1, -1),
          Position(-1, 1),
          Position(1, -1),
          Position(1, 1),
        ]);
        break;
      case PieceType.king:
        _addKingMoves(pos, piece, moves);
        break;
    }

    return moves;
  }

  /// Adds pawn moves to the move list.
  void _addPawnMoves(Position pos, ChessPiece piece, List<Move> moves) {
    final direction = piece.isWhite ? -1 : 1;
    final startRow = piece.isWhite ? 6 : 1;
    final promotionRow = piece.isWhite ? 0 : 7;

    // Forward one square
    final forward = Position(pos.row + direction, pos.col);
    if (forward.isValid && board[forward.row][forward.col] == null) {
      if (forward.row == promotionRow) {
        // Promotion
        for (final promoType in [
          PieceType.queen,
          PieceType.rook,
          PieceType.bishop,
          PieceType.knight,
        ]) {
          moves.add(Move.promotion(
            from: pos,
            to: forward,
            pawn: piece,
            capturedPiece: null,
            promoteTo: promoType,
          ));
        }
      } else {
        moves.add(Move.normal(from: pos, to: forward, piece: piece));

        // Forward two squares from starting position
        final twoForward = Position(pos.row + 2 * direction, pos.col);
        if (pos.row == startRow &&
            board[twoForward.row][twoForward.col] == null) {
          moves.add(Move.normal(from: pos, to: twoForward, piece: piece));
        }
      }
    }

    // Diagonal captures
    for (final dCol in [-1, 1]) {
      final capture = Position(pos.row + direction, pos.col + dCol);
      if (!capture.isValid) continue;

      final target = board[capture.row][capture.col];
      if (target != null && target.isWhite != piece.isWhite) {
        if (capture.row == promotionRow) {
          // Capture with promotion
          for (final promoType in [
            PieceType.queen,
            PieceType.rook,
            PieceType.bishop,
            PieceType.knight,
          ]) {
            moves.add(Move.promotion(
              from: pos,
              to: capture,
              pawn: piece,
              capturedPiece: target,
              promoteTo: promoType,
            ));
          }
        } else {
          moves.add(
              Move.normal(from: pos, to: capture, piece: piece, capturedPiece: target));
        }
      }

      // En passant
      if (capture == enPassantTarget) {
        final capturedPawnPos = Position(pos.row, capture.col);
        final capturedPawn = board[capturedPawnPos.row][capturedPawnPos.col];
        if (capturedPawn != null) {
          moves.add(Move.enPassant(
            from: pos,
            to: capture,
            pawn: piece,
            capturedPawn: capturedPawn,
            capturedPawnPosition: capturedPawnPos,
          ));
        }
      }
    }
  }

  /// Adds sliding piece moves (rook, bishop, queen) to the move list.
  void _addSlidingMoves(
      Position pos, ChessPiece piece, List<Move> moves, List<Position> directions) {
    for (final dir in directions) {
      var current = pos + dir;
      while (current.isValid) {
        final target = board[current.row][current.col];
        if (target == null) {
          moves.add(Move.normal(from: pos, to: current, piece: piece));
        } else {
          if (target.isWhite != piece.isWhite) {
            moves.add(Move.normal(
                from: pos, to: current, piece: piece, capturedPiece: target));
          }
          break;
        }
        current = current + dir;
      }
    }
  }

  /// Adds knight moves to the move list.
  void _addKnightMoves(Position pos, ChessPiece piece, List<Move> moves) {
    const offsets = [
      Position(-2, -1),
      Position(-2, 1),
      Position(-1, -2),
      Position(-1, 2),
      Position(1, -2),
      Position(1, 2),
      Position(2, -1),
      Position(2, 1),
    ];

    for (final offset in offsets) {
      final target = pos + offset;
      if (!target.isValid) continue;
      final targetPiece = board[target.row][target.col];
      if (targetPiece == null || targetPiece.isWhite != piece.isWhite) {
        moves.add(Move.normal(
            from: pos,
            to: target,
            piece: piece,
            capturedPiece: targetPiece));
      }
    }
  }

  /// Adds king moves (including castling) to the move list.
  void _addKingMoves(Position pos, ChessPiece piece, List<Move> moves) {
    const offsets = [
      Position(-1, -1),
      Position(-1, 0),
      Position(-1, 1),
      Position(0, -1),
      Position(0, 1),
      Position(1, -1),
      Position(1, 0),
      Position(1, 1),
    ];

    for (final offset in offsets) {
      final target = pos + offset;
      if (!target.isValid) continue;
      final targetPiece = board[target.row][target.col];
      if (targetPiece == null || targetPiece.isWhite != piece.isWhite) {
        moves.add(Move.normal(
            from: pos,
            to: target,
            piece: piece,
            capturedPiece: targetPiece));
      }
    }

    // Castling
    _addCastlingMoves(pos, piece, moves);
  }

  /// Adds castling moves if legal.
  void _addCastlingMoves(Position pos, ChessPiece piece, List<Move> moves) {
    if (piece.hasMoved) return;

    final row = pos.row;

    if (piece.isWhite) {
      // King-side
      if (whiteKingSideCastle &&
          board[row][5] == null &&
          board[row][6] == null &&
          board[row][7] != null &&
          board[row][7]!.type == PieceType.rook &&
          !board[row][7]!.hasMoved) {
        final rook = board[row][7]!;
        moves.add(Move.castling(
          kingFrom: pos,
          kingTo: Position(row, 6),
          king: piece,
          rookFrom: Position(row, 7),
          rookTo: Position(row, 5),
          rook: rook,
        ));
      }
      // Queen-side
      if (whiteQueenSideCastle &&
          board[row][1] == null &&
          board[row][2] == null &&
          board[row][3] == null &&
          board[row][0] != null &&
          board[row][0]!.type == PieceType.rook &&
          !board[row][0]!.hasMoved) {
        final rook = board[row][0]!;
        moves.add(Move.castling(
          kingFrom: pos,
          kingTo: Position(row, 2),
          king: piece,
          rookFrom: Position(row, 0),
          rookTo: Position(row, 3),
          rook: rook,
        ));
      }
    } else {
      // King-side
      if (blackKingSideCastle &&
          board[row][5] == null &&
          board[row][6] == null &&
          board[row][7] != null &&
          board[row][7]!.type == PieceType.rook &&
          !board[row][7]!.hasMoved) {
        final rook = board[row][7]!;
        moves.add(Move.castling(
          kingFrom: pos,
          kingTo: Position(row, 6),
          king: piece,
          rookFrom: Position(row, 7),
          rookTo: Position(row, 5),
          rook: rook,
        ));
      }
      // Queen-side
      if (blackQueenSideCastle &&
          board[row][1] == null &&
          board[row][2] == null &&
          board[row][3] == null &&
          board[row][0] != null &&
          board[row][0]!.type == PieceType.rook &&
          !board[row][0]!.hasMoved) {
        final rook = board[row][0]!;
        moves.add(Move.castling(
          kingFrom: pos,
          kingTo: Position(row, 2),
          king: piece,
          rookFrom: Position(row, 0),
          rookTo: Position(row, 3),
          rook: rook,
        ));
      }
    }
  }

  /// Checks if the given player is currently in check.
  bool isInCheck(Player player) {
    final kingPos = _kingPos(player);
    return _isSquareAttacked(kingPos, player);
  }

  /// Checks if [square] is attacked by any piece of the opponent of [player].
  bool _isSquareAttacked(Position square, Player player) {
    final opponent = player.opponent;

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece == null || piece.isWhite != (opponent == Player.white)) {
          continue;
        }

        if (_canPieceAttack(Position(row, col), piece, square)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Checks if a piece at [from] can attack [target].
  bool _canPieceAttack(Position from, ChessPiece piece, Position target) {
    final dRow = target.row - from.row;
    final dCol = target.col - from.col;

    switch (piece.type) {
      case PieceType.pawn:
        final direction = piece.isWhite ? -1 : 1;
        return dRow == direction && (dCol == -1 || dCol == 1);

      case PieceType.knight:
        return (dRow.abs() == 2 && dCol.abs() == 1) ||
            (dRow.abs() == 1 && dCol.abs() == 2);

      case PieceType.bishop:
        if (dRow.abs() != dCol.abs()) return false;
        return _isClearPath(from, target);

      case PieceType.rook:
        if (dRow != 0 && dCol != 0) return false;
        return _isClearPath(from, target);

      case PieceType.queen:
        if (dRow != 0 && dCol != 0 && dRow.abs() != dCol.abs()) return false;
        return _isClearPath(from, target);

      case PieceType.king:
        return dRow.abs() <= 1 && dCol.abs() <= 1;
    }
  }

  /// Checks if the path between [from] and [target] is clear (no pieces in between).
  bool _isClearPath(Position from, Position target) {
    final dRow = (target.row - from.row).sign;
    final dCol = (target.col - from.col).sign;
    var current = Position(from.row + dRow, from.col + dCol);

    while (current != target) {
      if (board[current.row][current.col] != null) return false;
      current = Position(current.row + dRow, current.col + dCol);
    }
    return true;
  }

  /// Generates all legal moves for the current player.
  List<Move> getLegalMoves() {
    return getLegalMovesForPlayer(currentPlayer);
  }

  /// Generates all legal moves for [player].
  List<Move> getLegalMovesForPlayer(Player player) {
    final legalMoves = <Move>[];

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece == null || piece.isWhite != (player == Player.white)) {
          continue;
        }

        final pseudoMoves = _generatePseudoMoves(Position(row, col));
        for (final move in pseudoMoves) {
          if (_isMoveLegal(move, player)) {
            legalMoves.add(move);
          }
        }
      }
    }

    return legalMoves;
  }

  /// Checks if a pseudo-legal move is legal (doesn't leave own king in check).
  bool _isMoveLegal(Move move, Player player) {
    // Save hasMoved state — _applyMove and _undoMove mutate it,
    // and corrupting it breaks castling rights for subsequent validation.
    final savedHasMoved = move.piece.hasMoved;
    _applyMove(move);
    final inCheck = isInCheck(player);
    _undoMove(move);
    move.piece.hasMoved = savedHasMoved;
    return !inCheck;
  }

  /// Applies a move to the board (mutates state).
  void _applyMove(Move move) {
    final piece = board[move.from.row][move.from.col]!;

    // Move the piece
    board[move.to.row][move.to.col] = piece;
    board[move.from.row][move.from.col] = null;

    // Update hasMoved
    piece.hasMoved = true;

    // Capture
    if (move.capturedPiece != null && !move.isEnPassant) {
      // Normal capture - piece already overwritten above
    }

    // En passant capture
    if (move.isEnPassant && move.enPassantTarget != null) {
      board[move.enPassantTarget!.row][move.enPassantTarget!.col] = null;
    }

    // Castling - move rook
    if (move.isCastling && move.rookFrom != null && move.rookTo != null) {
      final rook = board[move.rookFrom!.row][move.rookFrom!.col]!;
      board[move.rookTo!.row][move.rookTo!.col] = rook;
      board[move.rookFrom!.row][move.rookFrom!.col] = null;
      rook.hasMoved = true;
    }

    // Promotion
    if (move.promotionType != null) {
      board[move.to.row][move.to.col] = ChessPiece(
        type: move.promotionType!,
        isWhite: piece.isWhite,
        hasMoved: true,
      );
    }

    // Update king position
    if (piece.type == PieceType.king) {
      if (piece.isWhite) {
        whiteKingPos = move.to;
      } else {
        blackKingPos = move.to;
      }
    }
  }

  /// Undoes a move on the board (mutates state).
  void _undoMove(Move move) {
    final piece = board[move.to.row][move.to.col]!;

    // Move piece back
    board[move.from.row][move.from.col] = piece;
    board[move.to.row][move.to.col] = move.capturedPiece;

    // Restore hasMoved (approximate - doesn't handle multiple undo perfectly)
    piece.hasMoved = false;

    // En passant - restore captured pawn
    if (move.isEnPassant && move.enPassantTarget != null) {
      board[move.enPassantTarget!.row][move.enPassantTarget!.col] =
          move.capturedPiece;
      board[move.to.row][move.to.col] = null;
    }

    // Castling - restore rook
    if (move.isCastling && move.rookFrom != null && move.rookTo != null) {
      final rook = board[move.rookTo!.row][move.rookTo!.col]!;
      board[move.rookFrom!.row][move.rookFrom!.col] = rook;
      board[move.rookTo!.row][move.rookTo!.col] = null;
      rook.hasMoved = false;
    }

    // Restore king position
    if (piece.type == PieceType.king ||
        (move.promotionType != null)) {
      _findKings();
    }
  }

  /// Makes a move on the board and updates game state.
  /// Returns true if the move was successfully made.
  bool makeMove(Move move) {
    // Verify the move is legal
    final legalMoves = getLegalMoves();
    if (!legalMoves.any((m) =>
        m.from == move.from &&
        m.to == move.to &&
        m.promotionType == move.promotionType)) {
      return false;
    }

    // Find the matching legal move (with correct promotion type)
    final legalMove = legalMoves.firstWhere((m) =>
        m.from == move.from &&
        m.to == move.to &&
        m.promotionType == move.promotionType);

    // Update castling rights
    _updateCastlingRights(move);

    // Update en passant target
    enPassantTarget = _calculateEnPassantTarget(move);

    // Update half-move clock
    if (move.piece.type == PieceType.pawn || move.capturedPiece != null) {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }

    // Apply the move
    _applyMove(legalMove);

    // Update full move count
    if (currentPlayer == Player.black) {
      fullMoveCount++;
    }

    // Add to history
    moveHistory.add(legalMove);

    // Switch turns
    currentPlayer = currentPlayer.opponent;

    // Record position for repetition detection
    positionHistory.add(_boardToFen());

    // Update game status
    _updateGameStatus();

    return true;
  }

  /// Updates castling rights based on a move.
  void _updateCastlingRights(Move move) {
    if (move.piece.type == PieceType.king) {
      if (move.piece.isWhite) {
        whiteKingSideCastle = false;
        whiteQueenSideCastle = false;
      } else {
        blackKingSideCastle = false;
        blackQueenSideCastle = false;
      }
    }

    if (move.piece.type == PieceType.rook) {
      if (move.from == const Position(7, 7)) whiteKingSideCastle = false;
      if (move.from == const Position(7, 0)) whiteQueenSideCastle = false;
      if (move.from == const Position(0, 7)) blackKingSideCastle = false;
      if (move.from == const Position(0, 0)) blackQueenSideCastle = false;
    }

    // Capturing a rook also removes castling rights
    if (move.capturedPiece?.type == PieceType.rook) {
      if (move.to == const Position(7, 7)) whiteKingSideCastle = false;
      if (move.to == const Position(7, 0)) whiteQueenSideCastle = false;
      if (move.to == const Position(0, 7)) blackKingSideCastle = false;
      if (move.to == const Position(0, 0)) blackQueenSideCastle = false;
    }
  }

  /// Calculates the en passant target after a move.
  Position? _calculateEnPassantTarget(Move move) {
    if (move.piece.type == PieceType.pawn) {
      final rowDiff = (move.to.row - move.from.row).abs();
      if (rowDiff == 2) {
        return Position(
            (move.from.row + move.to.row) ~/ 2, move.from.col);
      }
    }
    return null;
  }

  /// Updates the game status (check, checkmate, stalemate, draws).
  /// Public wrapper for re-evaluating status after loading saved game.
  void updateGameStatus() => _updateGameStatus();

  void _updateGameStatus() {
    final legalMoves = getLegalMoves();
    final inCheck = isInCheck(currentPlayer);

    if (legalMoves.isEmpty) {
      if (inCheck) {
        status = GameStatus.checkmate;
        winner = currentPlayer.opponent;
      } else {
        status = GameStatus.stalemate;
      }
      return;
    }

    if (inCheck) {
      status = GameStatus.check;
    } else {
      status = GameStatus.playing;
    }

    // Check for draws
    if (_checkThreefoldRepetition()) {
      status = GameStatus.drawThreefoldRepetition;
      return;
    }

    if (halfMoveClock >= 100) {
      status = GameStatus.drawFiftyMoveRule;
      return;
    }

    if (_checkInsufficientMaterial()) {
      status = GameStatus.drawInsufficientMaterial;
      return;
    }
  }

  /// Checks for threefold repetition.
  bool _checkThreefoldRepetition() {
    if (positionHistory.length < 4) return false;

    final currentFen = positionHistory.last;
    int count = 0;
    for (final fen in positionHistory) {
      if (fen == currentFen) count++;
    }
    return count >= 3;
  }

  /// Checks for insufficient material.
  bool _checkInsufficientMaterial() {
    final pieces = <ChessPiece>[];
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece != null) pieces.add(piece);
      }
    }

    // King vs King
    if (pieces.length == 2) return true;

    // King + Bishop vs King
    if (pieces.length == 3) {
      final nonKing = pieces.where((p) => p.type != PieceType.king).toList();
      if (nonKing.length == 1 &&
          (nonKing[0].type == PieceType.bishop ||
              nonKing[0].type == PieceType.knight)) {
        return true;
      }
    }

    return false;
  }

  /// Undoes the last move.
  Move? undoLastMove() {
    if (moveHistory.isEmpty) return null;

    final lastMove = moveHistory.removeLast();

    // Undo state changes
    _undoStateChanges(lastMove);

    // Remove position from history
    if (positionHistory.isNotEmpty) {
      positionHistory.removeLast();
    }

    // Switch back
    currentPlayer = currentPlayer.opponent;

    // Restore game status
    status = GameStatus.playing;
    winner = null;

    return lastMove;
  }

  /// Undoes state changes associated with a move.
  void _undoStateChanges(Move move) {
    // Restore castling rights (approximate)
    // A full implementation would track castling rights history
    _restoreCastlingRights();

    // Restore en passant target from previous state
    enPassantTarget = null;

    // Undo the move on the board
    _undoMove(move);

    // Decrement full move counter
    if (currentPlayer == Player.black) {
      fullMoveCount--;
    }

    // Restore half-move clock (approximate)
    halfMoveClock = halfMoveClock > 0 ? halfMoveClock - 1 : 0;
  }

  /// Restores castling rights from the current board state (approximate).
  void _restoreCastlingRights() {
    whiteKingSideCastle = _canCastle(Player.white, true);
    whiteQueenSideCastle = _canCastle(Player.white, false);
    blackKingSideCastle = _canCastle(Player.black, true);
    blackQueenSideCastle = _canCastle(Player.black, false);
  }

  /// Checks if castling is still possible based on piece positions.
  bool _canCastle(Player player, bool kingSide) {
    final row = player == Player.white ? 7 : 0;
    final rookCol = kingSide ? 7 : 0;
    final king = board[row][4];
    final rook = board[row][rookCol];

    if (king == null || king.type != PieceType.king) return false;
    if (rook == null || rook.type != PieceType.rook) return false;

    return true; // hasMoved check is implicit in piece state
  }

  /// Resets the game to the initial position.
  void reset() {
    board = List.generate(8, (_) => List.filled(8, null));
    _setupBoard();
    moveHistory.clear();
    positionHistory.clear();
    whiteKingSideCastle = true;
    whiteQueenSideCastle = true;
    blackKingSideCastle = true;
    blackQueenSideCastle = true;
    enPassantTarget = null;
    halfMoveClock = 0;
    fullMoveCount = 1;
    status = GameStatus.playing;
    winner = null;
    positionHistory.add(_boardToFen());
  }

  /// Returns the board state as a FEN string (simplified).
  String _boardToFen() {
    final buffer = StringBuffer();
    for (var row = 0; row < 8; row++) {
      int emptyCount = 0;
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(piece.type.fenChar(piece.isWhite));
        }
      }
      if (emptyCount > 0) buffer.write(emptyCount);
      if (row < 7) buffer.write('/');
    }

    buffer.write(' ${currentPlayer == Player.white ? 'w' : 'b'} ');

    // Castling rights
    final castling = StringBuffer();
    if (whiteKingSideCastle) castling.write('K');
    if (whiteQueenSideCastle) castling.write('Q');
    if (blackKingSideCastle) castling.write('k');
    if (blackQueenSideCastle) castling.write('q');
    if (castling.isEmpty) castling.write('-');
    buffer.write(castling);

    // En passant
    buffer.write(' ${enPassantTarget?.algebraic ?? '-'}');

    buffer.write(' $halfMoveClock $fullMoveCount');

    return buffer.toString();
  }

  /// Returns the piece at the given position.
  ChessPiece? pieceAt(Position pos) => board[pos.row][pos.col];

  /// Returns captured pieces for a player (from move history).
  List<ChessPiece> getCapturedPieces(Player player) {
    final captured = <ChessPiece>[];
    for (final move in moveHistory) {
      if (move.capturedPiece != null &&
          move.capturedPiece!.isWhite != (player == Player.white)) {
        captured.add(move.capturedPiece!);
      }
    }
    return captured;
  }

  // ---------------------------------------------------------------------------
  // AI Evaluation
  // ---------------------------------------------------------------------------

  /// Piece-square tables for positional evaluation.
  static const List<List<int>> pawnTable = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [ 5,  5, 10, 25, 25, 10,  5,  5],
    [ 0,  0,  0, 20, 20,  0,  0,  0],
    [ 5, -5,-10,  0,  0,-10, -5,  5],
    [ 5, 10, 10,-20,-20, 10, 10,  5],
    [ 0,  0,  0,  0,  0,  0,  0,  0],
  ];

  static const List<List<int>> knightTable = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];

  static const List<List<int>> bishopTable = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];

  static const List<List<int>> rookTable = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [ 5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [ 0,  0,  0,  5,  5,  0,  0,  0],
  ];

  static const List<List<int>> queenTable = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [ -5,  0,  5,  5,  5,  5,  0, -5],
    [  0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20],
  ];

  static const List<List<int>> kingTable = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [ 20, 20,  0,  0,  0,  0, 20, 20],
    [ 20, 30, 10,  0,  0, 10, 30, 20],
  ];

  /// Evaluates the board from the perspective of [player].
  /// Positive values favor [player], negative values favor opponent.
  int evaluate(Player player) {
    int score = 0;

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece == null) continue;

        int pieceScore = piece.type.value;

        // Add positional value
        final posTable = _getPositionTable(piece.type);
        if (posTable != null) {
          final posRow = piece.isWhite ? row : 7 - row;
          pieceScore += posTable[posRow][col];
        }

        if (piece.isWhite == (player == Player.white)) {
          score += pieceScore;
        } else {
          score -= pieceScore;
        }
      }
    }

    // Mobility bonus (number of legal moves)
    final savedPlayer = currentPlayer;
    currentPlayer = player;
    final ourMoves = getLegalMoves().length;
    currentPlayer = player.opponent;
    final theirMoves = getLegalMoves().length;
    currentPlayer = savedPlayer;

    score += (ourMoves - theirMoves) * 5;

    return score;
  }

  /// Returns the position evaluation table for a piece type.
  List<List<int>>? _getPositionTable(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return pawnTable;
      case PieceType.knight:
        return knightTable;
      case PieceType.bishop:
        return bishopTable;
      case PieceType.rook:
        return rookTable;
      case PieceType.queen:
        return queenTable;
      case PieceType.king:
        return kingTable;
    }
  }
}
