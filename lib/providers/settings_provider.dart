import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';

/// Notifier for managing application settings.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(_storageService.loadSettings());

  /// Updates sound enabled state.
  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
    _storageService.saveSettings(state);
  }

  /// Updates vibration enabled state.
  void setVibrationEnabled(bool value) {
    state = state.copyWith(vibrationEnabled: value);
    _storageService.saveSettings(state);
  }

  /// Updates dark mode preference.
  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    _storageService.saveSettings(state);
  }

  /// Updates AI difficulty.
  void setAIDifficulty(AIDifficulty difficulty) {
    state = state.copyWith(aiDifficulty: difficulty);
    _storageService.saveSettings(state);
  }
}

/// Provider for settings.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(StorageService());
});
