import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';

/// Notifier for game statistics.
class StatisticsNotifier extends StateNotifier<GameStatistics> {
  final StorageService _storageService;

  StatisticsNotifier(this._storageService)
      : super(_storageService.loadStatistics());

  /// Refreshes statistics from storage.
  void refresh() {
    state = _storageService.loadStatistics();
  }

  /// Resets all statistics to zero.
  void reset() {
    state = GameStatistics();
    _storageService.saveStatistics(state);
  }
}

/// Provider for game statistics.
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, GameStatistics>((ref) {
  return StatisticsNotifier(StorageService());
});
