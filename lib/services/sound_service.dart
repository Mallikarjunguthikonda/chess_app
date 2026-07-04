import 'package:audioplayers/audioplayers.dart';

/// Service for playing chess sound effects.
///
/// Uses the audioplayers package for sound playback.
/// Sound effects include move, capture, check, and game over sounds.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  bool _enabled = true;

  /// Whether sound effects are enabled.
  bool get enabled => _enabled;

  /// Enables or disables sound effects.
  void setEnabled(bool value) => _enabled = value;

  /// Plays the move sound.
  Future<void> playMove() async {
    if (!_enabled) return;
    await _playAsset('sounds/move.wav');
  }

  /// Plays the capture sound.
  Future<void> playCapture() async {
    if (!_enabled) return;
    await _playAsset('sounds/capture.wav');
  }

  /// Plays the check sound.
  Future<void> playCheck() async {
    if (!_enabled) return;
    await _playAsset('sounds/check.wav');
  }

  /// Plays the game over sound.
  Future<void> playGameOver() async {
    if (!_enabled) return;
    await _playAsset('sounds/game_over.wav');
  }

  /// Plays a sound from the assets.
  Future<void> _playAsset(String path) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {
      // Silently handle missing audio files
    }
  }

  /// Disposes the audio player.
  void dispose() {
    _player.dispose();
  }
}
