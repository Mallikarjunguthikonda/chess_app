import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import '../services/storage_service.dart';
import '../models/game_state.dart';

/// Home screen with game mode selection and navigation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final storage = StorageService();
    final hasSavedGame = storage.hasSavedGame();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              ref.read(statisticsProvider.notifier).refresh();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App logo / title area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Play Chess',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a game mode to start',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(flex: 2),
              // Resume button
              if (hasSavedGame) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startGame(
                      context,
                      ref,
                      GameMode.pvp,
                      settings.aiDifficulty,
                      resume: true,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // PvP mode button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startGame(
                    context,
                    ref,
                    GameMode.pvp,
                    settings.aiDifficulty,
                  ),
                  icon: const Icon(Icons.people),
                  label: const Text('Player vs Player'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // PvE mode button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startGame(
                    context,
                    ref,
                    GameMode.pve,
                    settings.aiDifficulty,
                  ),
                  icon: const Icon(Icons.computer),
                  label: Text('Player vs AI (${settings.aiDifficulty.label})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Quick difficulty toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Difficulty: ',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  SegmentedButton<AIDifficulty>(
                    segments: AIDifficulty.values.map((d) {
                      return ButtonSegment(
                        value: d,
                        label: Text(d.label, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    selected: {settings.aiDifficulty},
                    onSelectionChanged: (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .setAIDifficulty(selected.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(
    BuildContext context,
    WidgetRef ref,
    GameMode mode,
    AIDifficulty difficulty, {
    bool resume = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameMode: mode,
          aiDifficulty: difficulty,
          resume: resume,
        ),
      ),
    );
  }
}
