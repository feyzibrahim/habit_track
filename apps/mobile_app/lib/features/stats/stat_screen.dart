import 'package:flutter/material.dart';
import 'package:ezucute/core/theme/app_colors.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  @override
  void initState() {
    super.initState();
    AppDataStore().addListener(_update);
  }

  @override
  void dispose() {
    AppDataStore().removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = AppDataStore();
    final tasks = store.todaysDailyTasks;

    final double completionRate = tasks.isEmpty
        ? 0
        : (tasks.where((t) => t.isCompleted).length / tasks.length) * 100;

    final int totalSessions = tasks.fold(0, (sum, t) {
      // For tasks of type 'habit' in ActionItem, we might want to count actual sessions.
      // But for now, we'll count as 1 if completed.
      return sum + (t.isCompleted ? 1 : 0);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            _buildStreakHero(context),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatMiniCard(
                    context,
                    icon: LucideIcons.calendarCheck,
                    label: 'Consistency',
                    value: '${completionRate.toInt()}%',
                    sublabel: 'Success rate',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatMiniCard(
                    context,
                    icon: LucideIcons.checkCircle,
                    label: 'Sessions',
                    value: '$totalSessions',
                    sublabel: 'Completions',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Activity Level'),
            const SizedBox(height: 16),
            _buildWeekChart(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildStreakHero(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            'CURRENT STREAK',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '12 days',
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            "You are doing great! Keep the momentum going.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String sublabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sublabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                LucideIcons.barChart,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final double value = (index % 3 + 1) / 4;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: 80 * value,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
