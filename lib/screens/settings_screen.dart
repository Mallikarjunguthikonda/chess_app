import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../models/game_state.dart';

/// Settings screen for configuring game preferences.
///
/// Options include:
///   - Sound effects toggle
///   - Vibration toggle
///   - Dark/Light mode toggle
///   - AI difficulty selection
///   - Reset statistics
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Game section
          _SectionHeader(title: 'Game'),
          Card(
            child: Column(
              children: [
                // AI Difficulty
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'AI Difficulty',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<AIDifficulty>(
                    segments: AIDifficulty.values.map((d) {
                      return ButtonSegment(
                        value: d,
                        label: Text(d.label),
                      );
                    }).toList(),
                    selected: {settings.aiDifficulty},
                    onSelectionChanged: (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setAIDifficulty(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Audio & Haptics section
          _SectionHeader(title: 'Audio & Haptics'),
          Card(
            child: Column(
              children: [
                // Sound toggle
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Play sounds for moves and events'),
                  secondary: const Icon(Icons.volume_up),
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setSoundEnabled(value);
                  },
                ),
                const Divider(height: 1, indent: 72),
                // Vibration toggle
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Haptic feedback on moves'),
                  secondary: const Icon(Icons.vibration),
                  value: settings.vibrationEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setVibrationEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance section
          _SectionHeader(title: 'Appearance'),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle dark/light theme'),
              secondary: Icon(
                settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              value: settings.darkMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDarkMode(value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Data section
          _SectionHeader(title: 'Data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Reset Statistics'),
              subtitle: const Text('Clear all game statistics'),
              onTap: () => _confirmResetStats(context, ref),
            ),
          ),

          const SizedBox(height: 32),

          // App info
          Center(
            child: Text(
              'Chess v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Shows confirmation dialog before resetting statistics.
  void _confirmResetStats(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
            'This will permanently delete all game statistics. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(statisticsProvider.notifier).reset();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics reset')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

/// A section header label for settings groups.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
