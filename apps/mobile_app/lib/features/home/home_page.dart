import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezucute/core/models/goal_model.dart' as goals;
import 'package:ezucute/core/theme/app_colors.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:ezucute/features/planning/planning_page.dart';
import 'package:ezucute/features/taskDetails/task_details_page.dart';
import 'package:ezucute/features/friends/leaderboard_page.dart';
import 'package:ezucute/features/chat/chat_page.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:ezucute/core/api/api_service.dart';
import 'package:ezucute/features/auth/auth_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;
  bool _showXpAnimation = false;
  int _xpGained = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerXpAnimation(int xp) {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    setState(() {
      _showXpAnimation = true;
      _xpGained = xp;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showXpAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiCoachPage()),
          );
        },
        icon: const Icon(LucideIcons.sparkles),
        label: const Text('AI Coach'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: AppDataStore(),
            builder: (context, child) {
              final store = AppDataStore();

              return RefreshIndicator(
                onRefresh: store.refreshData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context),
                    if (ApiService.isGuest) _buildGuestBanner(context),
                    if (store.isLoading && store.todaysDailyTasks.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (store.activeGoal == null)
                      SliverFillRemaining(child: _buildEmptyState(context))
                    else ...[
                      if (store.activeGoal != null)
                        _buildGoalCard(context, store),
                      _buildStatsGrid(context, store),
                      _buildSectionHeader(context, "Today's Mission Tasks"),
                      _buildTaskList(context, store),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ],
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          if (_showXpAnimation)
            Center(
              child:
                  Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.2),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                  LucideIcons.trophy,
                                  size: 72,
                                  color: Colors.amber,
                                )
                                .animate()
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1.2, 1.2),
                                  duration: 400.ms,
                                  curve: Curves.easeOutBack,
                                )
                                .then()
                                .scale(
                                  end: const Offset(1.0, 1.0),
                                  duration: 200.ms,
                                )
                                .shake(hz: 2, rotation: 0.1, duration: 400.ms),
                            const SizedBox(height: 16),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: _xpGained),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Text(
                                  "+$value XP",
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Colors.amber.withValues(
                                              alpha: 0.8,
                                            ),
                                            blurRadius: 30,
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      )
                      .then(delay: 1.seconds)
                      .fadeOut(duration: 400.ms)
                      .slideY(begin: 0, end: -0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      floating: true,
      toolbarHeight: 80.h,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Overview',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            'Good Morning',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.trophy, color: Colors.amber.shade400),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = store.goalProgress;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.target,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTIVE MISSION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              store.activeGoal!.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppDataStore store) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            _StatItem(
              label: 'Xp Points',
              value: store.userScore.toString(),
              unit: 'XP',
              icon: LucideIcons.trophy,
              iconColor: Colors.amber,
            ),
            const SizedBox(width: 12),
            _StatItem(
              label: 'Current Level',
              value: (store.userScore ~/ 100 + 1).toString(),
              unit: 'Rank',
              icon: LucideIcons.medal,
              iconColor: Colors.blue,
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, AppDataStore store) {
    final tasks = store.todaysDailyTasks;

    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            "No tasks scheduled for today.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final task = tasks[index];
        return _TaskTile(task: task, onCompleted: _triggerXpAnimation);
      }, childCount: tasks.length),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.rocket,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text("No Active Mission", style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              "Start a new journey with AI guidance to achieve your goals.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showPlanning(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Start New Mission'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanningPage()),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You haven't registered",
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    "Register to save your progress",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showAuthModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthModal(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: const AuthPage(
              initialIsLogin: false,
              disableToggle: true,
            ),
          ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.sp,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatefulWidget {
  final goals.ActionItem task;
  final void Function(int xpGained)? onCompleted;

  const _TaskTile({required this.task, this.onCompleted});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = task.title;
    final String subtitle = task.type.toUpperCase();
    final bool isCompleted = task.isCompleted;
    final String id = task.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () {
            final hasSteps = task.steps.isNotEmpty;
            final allStepsDone =
                !hasSteps || task.steps.every((s) => s.isCompleted);

            if (!allStepsDone && !isCompleted) {
              setState(() => _showError = true);
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) setState(() => _showError = false);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Click the row to view and complete all sub-tasks first",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (!isCompleted) {
              widget.onCompleted?.call(task.type == 'habit' ? 2 : 10);
            }
            AppDataStore().toggleActionItem(id, isCompleted);
          },
          child: AnimatedContainer(
            duration: 200.ms,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _showError
                  ? Colors.red
                  : (isCompleted
                        ? theme.colorScheme.primary
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showError
                    ? Colors.red
                    : (isCompleted
                          ? theme.colorScheme.primary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)),
                width: 2,
              ),
            ),
            child: _showError
                ? const Icon(LucideIcons.x, size: 20, color: Colors.white)
                      .animate()
                      .scale(duration: 150.ms, curve: Curves.easeOutBack)
                      .shake(hz: 3, rotation: 0.1, duration: 300.ms)
                : (isCompleted
                      ? const Icon(
                          LucideIcons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null),
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.type == 'habit' ? "+2 XP" : "+10 XP",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 9.sp,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
      ),
    );
  }
}
