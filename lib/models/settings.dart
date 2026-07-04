import 'game_state.dart';

/// Application settings persisted to local storage.
class AppSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkMode;
  final AIDifficulty aiDifficulty;

  const AppSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.darkMode = true,
    this.aiDifficulty = AIDifficulty.medium,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkMode,
    AIDifficulty? aiDifficulty,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      darkMode: darkMode ?? this.darkMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      soundEnabled: (map['soundEnabled'] as bool?) ?? true,
      vibrationEnabled: (map['vibrationEnabled'] as bool?) ?? true,
      darkMode: (map['darkMode'] as bool?) ?? true,
      aiDifficulty: AIDifficulty.values[
          (map['aiDifficulty'] as int?) ?? AIDifficulty.medium.index],
    );
  }

  Map<String, dynamic> toMap() => {
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'darkMode': darkMode,
        'aiDifficulty': aiDifficulty.index,
      };
}
