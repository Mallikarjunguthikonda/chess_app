import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statistics_provider.dart';

/// Statistics screen displaying cumulative game records.
///
/// Shows wins, losses, draws, total games, and win rate
/// with visual progress indicators.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final theme = Theme.of(context);

    final winRate = stats.totalGames > 0
        ? (stats.wins / stats.totalGames * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Win rate circle
            Container(
              width: 140,
              height: 140,
              margin: const EdgeInsets.only(bottom: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: winRate / 100,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$winRate%',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Win Rate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statistics cards
            Row(
              children: [
                _StatCard(
                  label: 'Wins',
                  value: '${stats.wins}',
                  icon: Icons.emoji_events,
                  color: Colors.green,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Losses',
                  value: '${stats.losses}',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Draws',
                  value: '${stats.draws}',
                  icon: Icons.handshake,
                  color: Colors.orange,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total games
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.sports_score,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Total Games'),
                trailing: Text(
                  '${stats.totalGames}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (stats.totalGames > 0) ...[
              const SizedBox(height: 16),
              // Win/Loss/Draw progress bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results Breakdown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 24,
                          child: Row(
                            children: [
                              if (stats.wins > 0)
                                Expanded(
                                  flex: stats.wins,
                                  child: Container(
                                    color: Colors.green,
                                    child: Center(
                                      child: Text(
                                        '${(stats.wins / stats.totalGames * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (stats.draws > 0)
                                Expanded(
                                  flex: stats.draws,
                                  child: Container(
                                    color: Colors.orange,
                                    child: Center(
                                      child: Text(
                                        '${(stats.draws / stats.totalGames * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (stats.losses > 0)
                                Expanded(
                                  flex: stats.losses,
                                  child: Container(
                                    color: Colors.red,
                                    child: Center(
                                      child: Text(
                                        '${(stats.losses / stats.totalGames * 100).round()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (stats.totalGames == 0)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No games played yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Play some games to see your statistics',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card displaying a single statistic.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
