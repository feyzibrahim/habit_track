import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Missions'), centerTitle: true),
      body: ListenableBuilder(
        listenable: AppDataStore(),
        builder: (context, child) {
          final store = AppDataStore();
          final goals = store.currentGoals;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.rocket,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No missions found",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final isActive = store.activeGoal?.id == goal.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    store.setActiveGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Switched to: ${goal.title}"),
                        backgroundColor: theme.colorScheme.primary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child:
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    )
                                  : theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : (theme.brightness == Brightness.dark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goal.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isActive
                                                  ? theme.colorScheme.primary
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          "ACTIVE",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  goal.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMeta(
                                      context,
                                      LucideIcons.calendar,
                                      "${goal.durationDays}d",
                                    ),
                                    _buildMeta(
                                      context,
                                      LucideIcons.target,
                                      goal.status.toUpperCase(),
                                    ),
                                    _buildMeta(
                                      context,
                                      LucideIcons.layers,
                                      "${goal.milestones.length} Phases",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideX(begin: 0.1),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMeta(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
