import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/core/models/goal_model.dart' as goals;
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/features/auth/auth_page.dart';
import 'package:ezecute/features/planning/planning_page.dart';
import 'package:ezecute/features/planning/timeline_page.dart';
import 'package:ezecute/features/friends/leaderboard_page.dart';
import 'package:ezecute/features/profile/xp_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;
  bool _showXpAnimation = false;
  int _xpGained = 0;
  int _selectedDayIndex = DateTime.now().weekday - 1;
  bool _showAllTasks = false;
  bool _showAllBacklog = false;

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

  List<goals.ActionItem> _getTasksForDate(AppDataStore store, DateTime date) {
    final List<goals.ActionItem> tasks = [];
    final targetDay = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeGoals = store.currentGoals
        .where((g) => g.status == 'active')
        .toList();
    for (var goal in activeGoals) {
      goals.Milestone? current;
      for (var m in goal.milestones) {
        if (!m.isCompleted) {
          current = m;
          break;
        }
        if (m.targetDate != null && m.targetDate!.isAfter(now)) {
          current = m;
          break;
        }
      }
      current ??= goal.milestones.lastOrNull;
      if (current != null) {
        for (var task in current.actionItems) {
          if (task.targetDate != null) {
            final taskDate = DateTime(
              task.targetDate!.year,
              task.targetDate!.month,
              task.targetDate!.day,
            );
            if (taskDate.isAtSameMomentAs(targetDay)) {
              tasks.add(task);
            }
          } else {
            if (targetDay.isAtSameMomentAs(today)) {
              tasks.add(task);
            }
          }
        }
      }
    }

    tasks.sort((a, b) {
      if (a.targetDate == null && b.targetDate == null) return 0;
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _buildAppBar(context, store),
                    if (ApiService.isGuest) _buildGuestBanner(context),
                    if (store.isLoading && store.currentGoals.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (store.currentGoals.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState(context))
                    else ...[
                      _buildXpCard(context, store),
                      _buildStatsGrid(context, store),
                      _buildStreakWeek(context, store),
                      _buildDailyFocusSection(context, store),
                      _buildSuccessProbabilityCard(context, store),
                      _buildActiveGoalsSection(context, store),
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

  Widget _buildAppBar(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final String name = store.userData?['firstName'] ?? 'Althaf';
    final int pendingMissions = store.todaysDailyTasks
        .where((t) => !t.isCompleted)
        .length;

    return SliverAppBar(
      floating: true,
      toolbarHeight: 80.h,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning, $name 👋',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Day ${store.todaysDailyTasks.isNotEmpty ? "Streak Status" : "0"} · $pendingMissions missions pending today',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.trophy, color: theme.colorScheme.onSurface),
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

  Widget _buildXpCard(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int score = store.userScore;
    final int level = score ~/ 100 + 1;
    final int nextLevelXp = level * 100;
    final int prevLevelXp = (level - 1) * 100;
    final int xpInCurrentLevel = score - prevLevelXp;
    final double xpProgress = (xpInCurrentLevel / 100).clamp(0.0, 1.0);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D1A13), const Color(0xFF0A1A10)]
                : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.greenMid : AppColors.lightAccent.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL $level · EXECUTOR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$score XP',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Next level',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$nextLevelXp XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: xpProgress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${nextLevelXp - score} XP to Level ${level + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '+120 XP earned',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakWeek(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final streakStatus = store.currentWeekStreakStatus;
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1; // 0-indexed

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "This Week's Streak"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isDone = streakStatus[i];
                final isToday = i == todayIndex;
                final isSelected = i == _selectedDayIndex;

                Color bgColor;
                Color borderCol;
                Color txtColor;
                double borderWidth = isSelected ? 2.5 : 1.5;

                if (isToday) {
                  bgColor = theme.colorScheme.primary;
                  borderCol = isSelected
                      ? Colors.amber
                      : theme.colorScheme.primary;
                  txtColor = Colors.white;
                } else if (isDone) {
                  bgColor = isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.25)
                      : theme.colorScheme.primary.withValues(alpha: 0.15);
                  borderCol = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.4);
                  txtColor = theme.colorScheme.primary;
                } else {
                  bgColor = isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : (theme.cardTheme.color ?? Colors.transparent);
                  borderCol = isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
                  txtColor = isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3);
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedDayIndex = i;
                        _showAllTasks = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderCol,
                          width: borderWidth,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdays[i],
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: txtColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: txtColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessProbabilityCard(
    BuildContext context,
    AppDataStore store,
  ) {
    final activeGoals = store.currentGoals
        .where((g) => g.status == 'active')
        .toList();

    if (activeGoals.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: _SuccessProbabilitySlider(
        activeGoals: activeGoals,
        onTapGoal: (goal) => _showMissionDetailsModal(context, goal),
      ),
    );
  }

  Widget _buildActiveGoalsSection(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeGoals = store.currentGoals
        .where((g) => g.status == 'active')
        .toList();

    if (activeGoals.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    Color getGoalColor(String category, int index) {
      final List<Color> colors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.tertiary,
        theme.colorScheme.error,
        theme.colorScheme.primary,
      ];
      return colors[index % colors.length];
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Active goals"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: List.generate(activeGoals.length, (index) {
                  final g = activeGoals[index];
                  final isSelected = store.activeGoal?.id == g.id;
                  final color = getGoalColor(g.category, index);

                  int dayCount = 1;
                  if (g.startDate != null) {
                    dayCount =
                        DateTime.now().difference(g.startDate!).inDays + 1;
                    if (dayCount < 1) dayCount = 1;
                  }

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      store.setActiveGoal(g.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimelinePage(goal: g),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index == activeGoals.length - 1
                                ? Colors.transparent
                                : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            width: index == activeGoals.length - 1 ? 0 : 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Day $dayCount of ${g.durationDays} · Category: ${g.category}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${g.probabilityRatio}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyFocusSection(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // Mon is 1, Sun is 7
    final monday = now.subtract(Duration(days: currentDayOfWeek - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);
    final selectedDate = startOfMonday.add(Duration(days: _selectedDayIndex));
    final today = DateTime(now.year, now.month, now.day);

    final List<goals.ActionItem> dayTasks = _getTasksForDate(
      store,
      selectedDate,
    );
    final isSelectedToday = selectedDate.isAtSameMomentAs(today);

    final List<goals.ActionItem> finalTasks = List.from(dayTasks);

    final List<String> dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final String dayLabel = isSelectedToday
        ? "Today's Focus"
        : "${dayNames[_selectedDayIndex]}'s Focus";

    final totalTasks = finalTasks.length;
    final completedCount = finalTasks.where((t) => t.isCompleted).length;
    final displayTasks = _showAllTasks
        ? finalTasks
        : finalTasks.take(3).toList();

    final totalBacklog = store.pastDaysTasks.length;
    final displayBacklog = _showAllBacklog
        ? store.pastDaysTasks
        : store.pastDaysTasks.take(3).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(context, dayLabel),
                if (totalTasks > 0)
                  Text(
                    '$completedCount/$totalTasks completed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (finalTasks.isEmpty &&
                (!isSelectedToday || store.pastDaysTasks.isEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 28,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No missions scheduled for this day.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (finalTasks.isNotEmpty) ...[
                    ...displayTasks.map((task) {
                      return _HomeMissionCardWidget(
                        task: task,
                        onCompleted: _triggerXpAnimation,
                        key: ValueKey('${task.id}_${task.isCompleted}'),
                      );
                    }),
                    if (totalTasks > 3) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _showAllTasks = !_showAllTasks;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                          ),
                          icon: Icon(
                            _showAllTasks
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 16,
                          ),
                          label: Text(
                            _showAllTasks
                                ? "Show Less"
                                : "Show More (${totalTasks - 3})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (isSelectedToday && store.pastDaysTasks.isNotEmpty) ...[
                    if (finalTasks.isNotEmpty) const SizedBox(height: 24),
                    _buildSectionTitle(context, "Backlog missions"),
                    const SizedBox(height: 12),
                    ...displayBacklog.map((task) {
                      return _HomeMissionCardWidget(
                        task: task,
                        onCompleted: _triggerXpAnimation,
                        showDate: true,
                        key: ValueKey('${task.id}_${task.isCompleted}'),
                      );
                    }),
                    if (totalBacklog > 3) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _showAllBacklog = !_showAllBacklog;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                          ),
                          icon: Icon(
                            _showAllBacklog
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 16,
                          ),
                          label: Text(
                            _showAllBacklog
                                ? "Show Less"
                                : "Show More (${totalBacklog - 3})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showMissionDetailsModal(BuildContext context, goals.Goal goal) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, "Strategic Blueprint"),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Initial Vision',
                      goal.prompt,
                      LucideIcons.messageSquare,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Type',
                            goal.category.toUpperCase(),
                            LucideIcons.tag,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            context,
                            'Timeline',
                            '${goal.durationDays} Days',
                            LucideIcons.calendar,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      context,
                      'Start Date',
                      goal.startDate != null
                          ? "${goal.startDate!.day}/${goal.startDate!.month}/${goal.startDate!.year}"
                          : "Not set",
                      LucideIcons.play,
                    ),
                    const SizedBox(height: 40),
                    _buildSectionTitle(context, "Probability Analysis"),
                    const SizedBox(height: 20),
                    _buildStatusBadge(context, goal.feasibility),
                    if (goal.feasibilityReason != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        goal.feasibilityReason!,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildProbabilityChart(
                      context,
                      theme,
                      goal.probabilityRatio.toDouble(),
                    ),
                    const SizedBox(height: 40),
                    if (goal.strategicAnalysis != null) ...[
                      _buildSectionTitle(context, "Strategic Approach"),
                      const SizedBox(height: 16),
                      Text(
                        goal.strategicAnalysis!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                    if (goal.graphData.isNotEmpty) ...[
                      _buildSectionTitle(context, "Requirements Graph"),
                      const SizedBox(height: 16),
                      _buildBarChart(context, theme, goal.graphData),
                      const SizedBox(height: 40),
                    ],
                    if (goal.keyChallenges.isNotEmpty) ...[
                      _buildSectionTitle(context, "Key Challenges"),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: goal.keyChallenges
                            .map((c) => _buildChip(context, c))
                            .toList(),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const XpHistoryPage()),
                );
              },
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

  Widget _buildProbabilityChart(
    BuildContext context,
    ThemeData theme,
    double probability,
  ) {
    final color = probability >= 75
        ? Colors.greenAccent
        : (probability >= 50 ? Colors.orangeAccent : Colors.redAccent);

    String label;
    String description;
    if (probability >= 80) {
      label = "OPTIMAL";
      description =
          "The metrics are excellent. Your consistency and target duration indicate a high success rate.";
    } else if (probability >= 60) {
      label = "GOOD";
      description =
          "A strong roadmap. Success is highly likely with disciplined execution of daily quests.";
    } else if (probability >= 40) {
      label = "MODERATE";
      description =
          "Feasible, but demands strict alignment. You will need to build heavy friction blockers.";
    } else {
      label = "RISKY";
      description =
          "High operational hazard. This timeline is extremely tight for the scale of this quest.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "CHANCE OF SUCCESS",
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _GradientCircularProgressPainter(
                    probability: probability,
                    baseColor: color,
                    trackColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${probability.toInt()}%",
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    BuildContext context,
    ThemeData theme,
    List<Map<String, dynamic>> data,
  ) {
    return Column(
      children: data.map((item) {
        final label = item['label'] ?? '';
        final value = (item['value'] ?? 0).toDouble();
        final fraction = (value / 100).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${value.toInt()}%",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeOutCubic,
                          height: 8,
                          width: constraints.maxWidth * fraction,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String feasibility) {
    final theme = Theme.of(context);
    Color color;
    switch (feasibility) {
      case 'can be done':
        color = Colors.green;
        break;
      case 'moderate':
        color = Colors.orange;
        break;
      default:
        color = theme.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Text(
        feasibility.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const AuthPage(initialIsLogin: false, disableToggle: true),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double probability;
  final Color baseColor;
  final Color trackColor;

  _GradientCircularProgressPainter({
    required this.probability,
    required this.baseColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width / 2 : size.height / 2) - 6;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (probability > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -3.1415926535 / 2;
      final sweepAngle = 2 * 3.1415926535 * (probability / 100);

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -3.1415926535 / 2,
          endAngle: 3 * 3.1415926535 / 2,
          colors: [baseColor.withValues(alpha: 0.2), baseColor],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.probability != probability ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }
}

class _SuccessProbabilitySlider extends StatefulWidget {
  final List<goals.Goal> activeGoals;
  final void Function(goals.Goal) onTapGoal;

  const _SuccessProbabilitySlider({
    required this.activeGoals,
    required this.onTapGoal,
  });

  @override
  State<_SuccessProbabilitySlider> createState() =>
      _SuccessProbabilitySliderState();
}

class _SuccessProbabilitySliderState extends State<_SuccessProbabilitySlider> {
  late PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  static const int _infinitePageMultiplier = 10000;

  @override
  void initState() {
    super.initState();
    _setupSlider();
  }

  void _setupSlider() {
    if (widget.activeGoals.length <= 1) {
      _currentPage = 0;
      _pageController = PageController(initialPage: 0);
      return;
    }

    final middle = (widget.activeGoals.length * _infinitePageMultiplier) ~/ 2;
    _currentPage = middle;
    _pageController = PageController(initialPage: middle);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _SuccessProbabilitySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeGoals.length != widget.activeGoals.length) {
      _stopTimer();
      _pageController.dispose();
      _setupSlider();
    }
  }

  void _startTimer() {
    _stopTimer();
    if (widget.activeGoals.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _currentPage + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.activeGoals.isEmpty) return const SizedBox();

    final goalsCount = widget.activeGoals.length;

    // Build the card layout dynamically so it can be reused
    Widget buildGoalCard(goals.Goal goal, {bool hasMargin = true}) {
      final prob = goal.probabilityRatio;
      final double fraction = (prob / 100).clamp(0.0, 1.0);

      return GestureDetector(
        onTap: () => widget.onTapGoal(goal),
        child: Container(
          margin: hasMargin
              ? EdgeInsets.symmetric(horizontal: 20.w)
              : EdgeInsets.zero,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUCCESS PROBABILITY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$prob%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  goal.feasibilityReason ??
                      "Complete today's missions to push your probability higher.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If there is only 1 goal, render it directly without PageView or a fixed height wrapper.
    // It will dynamically size itself based on its contents (e.g. feasibilityReason length and text scaling).
    if (goalsCount == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: buildGoalCard(widget.activeGoals[0]),
      );
    }

    final int displayIndex = goalsCount > 0 ? _currentPage % goalsCount : 0;
    final textScale =
        MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ??
        MediaQuery.maybeOf(context)?.textScaleFactor ??
        1.0;
    final pageViewHeight = 170 * textScale;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: pageViewHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _stopTimer();
                } else if (notification is ScrollEndNotification) {
                  _startTimer();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                physics: widget.activeGoals.length <= 1
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: widget.activeGoals.length <= 1 ? 1 : null,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final goalIndex = index % goalsCount;
                  return buildGoalCard(widget.activeGoals[goalIndex]);
                },
              ),
            ),
          ),
          if (goalsCount > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(goalsCount, (dotIndex) {
                final isSelected = displayIndex == dotIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 18.w : 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeMissionCardWidget extends StatefulWidget {
  final goals.ActionItem task;
  final void Function(int xpGained)? onCompleted;
  final bool showDate;

  const _HomeMissionCardWidget({
    super.key,
    required this.task,
    this.onCompleted,
    this.showDate = false,
  });

  @override
  State<_HomeMissionCardWidget> createState() => _HomeMissionCardWidgetState();
}

class _HomeMissionCardWidgetState extends State<_HomeMissionCardWidget> {
  bool _isGenerating = false;
  bool _isExpanded = false;
  final List<goals.TaskStep> _visibleSteps = [];
  bool _isStreaming = false;
  String _generatingStatus = "🧠 Reading task context...";
  Timer? _statusTimer;

  void _startStatusTimer() {
    _statusTimer?.cancel();
    final statuses = [
      "🧠 Reading task context...",
      "✨ Designing roadmap...",
      "🎯 Structuring blueprint...",
      "⚡ Finalizing coaching plan...",
    ];
    int index = 0;
    setState(() => _generatingStatus = statuses[index]);
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted || !_isGenerating) {
        timer.cancel();
        return;
      }
      index = (index + 1) % statuses.length;
      setState(() => _generatingStatus = statuses[index]);
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateSteps() async {
    if (_isGenerating || _isStreaming) return;
    setState(() {
      _isGenerating = true;
      _visibleSteps.clear();
    });
    _startStatusTimer();

    try {
      final result = await AppDataStore().generateTaskSteps(widget.task.id);
      _statusTimer?.cancel();
      if (!mounted) return;

      if (result == null || result.steps.isEmpty) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to generate AI blueprint steps. Try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() {
          _isGenerating = false;
          _isStreaming = true;
        });

        // Progressive stream-in of steps
        for (var step in result.steps) {
          if (!mounted) break;
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) break;
          setState(() {
            _visibleSteps.add(step);
          });
        }

        if (mounted) {
          setState(() {
            _isStreaming = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("AI Blueprint steps generated!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      _statusTimer?.cancel();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _isStreaming = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error generating steps: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isBoss =
        widget.task.type == 'boss' ||
        widget.task.title.toLowerCase().contains('boss');
    final bool isSide = widget.task.isOptional;

    final displaySteps = (_isStreaming || _isGenerating)
        ? _visibleSteps
        : widget.task.steps;

    Color leftStripeColor = theme.colorScheme.primary;
    Color cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    BorderStyle borderStyle = BorderStyle.solid;

    if (isBoss) {
      leftStripeColor = isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
      cardBg = isDark ? AppColors.purpleDim : const Color(0xFFF5F2FC);
      borderColor = (isDark ? AppColors.darkTertiary : AppColors.lightTertiary).withValues(alpha: 0.3);
    } else if (isSide) {
      leftStripeColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
      borderColor = (isDark ? AppColors.darkSecondary : AppColors.lightSecondary).withValues(alpha: 0.3);
    }

    if (widget.task.isCompleted) {
      cardBg = isDark ? AppColors.greenDim : const Color(0xFFE8F5E9);
      borderColor = (isDark ? AppColors.greenMid : AppColors.lightAccent).withValues(alpha: 0.3);
    }

    final hasSteps = widget.task.steps.isNotEmpty;
    final allStepsDone =
        !hasSteps || widget.task.steps.every((s) => s.isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1, style: borderStyle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: widget.task.isCompleted
                    ? theme.colorScheme.primary
                    : leftStripeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!allStepsDone && !widget.task.isCompleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Complete all blueprint steps first",
                                    ),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }
                              HapticFeedback.mediumImpact();
                              if (!widget.task.isCompleted && allStepsDone) {
                                final xp = isBoss ? 200 : (isSide ? 25 : 50);
                                widget.onCompleted?.call(xp);
                              }
                              AppDataStore().toggleActionItem(
                                widget.task.id,
                                widget.task.isCompleted,
                              );
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: widget.task.isCompleted
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.task.isCompleted
                                      ? theme.colorScheme.primary
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                  width: 1.8,
                                ),
                              ),
                              child: widget.task.isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBoss
                                      ? "BOSS CHALLENGE"
                                      : (isSide ? "SIDE QUEST" : "QUEST"),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: widget.task.isCompleted
                                        ? theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3)
                                        : (isBoss
                                              ? (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                                              : (isSide
                                                    ? (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                                                    : theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ))),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8.5,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.task.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: widget.task.isCompleted
                                        ? theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3)
                                        : theme.colorScheme.onSurface,
                                    decoration: widget.task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.task.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 11,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.task.isCompleted
                                            ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.05)
                                            : (isBoss
                                                  ? (isDark ? AppColors.purpleDim : AppColors.lightTertiary.withValues(alpha: 0.1))
                                                  : (isSide
                                                        ? (isDark ? AppColors.amberDim : AppColors.lightSecondary.withValues(alpha: 0.1))
                                                        : theme
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ))),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isBoss
                                            ? "+200 XP"
                                            : (isSide ? "+25 XP" : "+50 XP"),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: widget.task.isCompleted
                                                  ? theme.colorScheme.primary
                                                        .withValues(alpha: 0.3)
                                                  : (isBoss
                                                        ? (isDark ? AppColors.darkTertiary : AppColors.lightTertiary)
                                                        : (isSide
                                                              ? (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                                                              : theme
                                                                    .colorScheme
                                                                    .primary)),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ),
                                    if (widget.task.totalTarget > 1) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "Target: ${widget.task.totalTarget}",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                              fontSize: 9,
                                            ),
                                      ),
                                    ],
                                    if (widget.showDate &&
                                        widget.task.targetDate != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              LucideIcons.calendar,
                                              size: 10,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat(
                                                'MMM d',
                                              ).format(widget.task.targetDate!),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                        if (_isExpanded &&
                                            widget.task.steps.isEmpty) {
                                          _generateSteps();
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _isExpanded
                                                ? "Collapse"
                                                : "Blueprint",
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9.5,
                                                ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            _isExpanded
                                                ? LucideIcons.chevronUp
                                                : LucideIcons.chevronDown,
                                            size: 11,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 12),
                        Text(
                          "AI EXECUTION BLUEPRINT",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isGenerating) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.deepPurpleAccent,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .rotate(duration: 1.seconds),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _generatingStatus,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(3, (index) {
                            return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .fade(
                                  begin: 0.3,
                                  end: 0.8,
                                  duration: 800.ms,
                                  delay: (index * 200).ms,
                                );
                          }),
                        ] else if (widget.task.steps.isEmpty && !_isStreaming)
                          GestureDetector(
                            onTap: _generateSteps,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.sparkles,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Generate AI Action Steps",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Column(
                            children: displaySteps.map((step) {
                              return InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      if (!step.isCompleted) {
                                        widget.onCompleted?.call(5);
                                      }
                                      AppDataStore().toggleTaskStep(
                                        widget.task.id,
                                        step.id,
                                        step.isCompleted,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            step.isCompleted
                                                ? LucideIcons.checkCircle2
                                                : LucideIcons.circle,
                                            size: 14,
                                            color: step.isCompleted
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.3),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              step.text,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11,
                                                    color: step.isCompleted
                                                        ? theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.4,
                                                              )
                                                        : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                    decoration: step.isCompleted
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    height: 1.35,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 300.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    duration: 300.ms,
                                    curve: Curves.easeOutBack,
                                  );
                            }).toList(),
                          ),
                          if (_isStreaming) ...[
                            const SizedBox(height: 8),
                            Row(
                                  children: [
                                    const SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.0,
                                        color: Colors.deepPurpleAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Streaming steps...",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .fade(begin: 0.5, end: 1.0, duration: 500.ms),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
