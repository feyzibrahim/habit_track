import 'package:confetti/confetti.dart';
import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/core/models/goal_model.dart' as goals;
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/features/auth/auth_page.dart';
import 'package:ezecute/features/planning/planning_page.dart';
import 'package:ezecute/features/profile/profile_page.dart';
import 'package:ezecute/features/profile/xp_history_page.dart';
import 'package:ezecute/features/taskDetails/task_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;
  bool _showXpAnimation = false;
  int _xpGained = 0;
  bool _isUpcomingExpanded = false;

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
                    if (store.isLoading &&
                        store.todaysDailyTasks.isEmpty &&
                        store.otherDaysTasks.isEmpty &&
                        store.pastDaysTasks.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (store.activeGoal == null)
                      SliverFillRemaining(child: _buildEmptyState(context))
                    else ...[
                      if (store.activeGoal != null)
                        _buildGoalCard(context, store),
                      _buildStatsGrid(context, store),

                      if (store.pastDaysTasks.isNotEmpty) ...[
                        _buildSectionHeader(context, "Overdue Tasks"),
                        _buildTaskList(
                          context,
                          store.pastDaysTasks,
                          "No overdue tasks.",
                        ),
                      ],

                      _buildSectionHeader(context, "Today's Mission Tasks"),
                      _buildTaskList(
                        context,
                        store.todaysDailyTasks,
                        "No tasks scheduled for today.",
                      ),

                      if (store.otherDaysTasks.isNotEmpty) ...[
                        _buildSectionHeader(context, "Upcoming Mission Tasks"),
                        _buildUpcomingTaskList(context, store.otherDaysTasks),
                      ],
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
          icon: Icon(LucideIcons.user, color: theme.colorScheme.onSurface),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
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
      child: GestureDetector(
        onTap: () => _showMissionDetailsModal(context, store.activeGoal!),
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
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
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
                        children:
                            goal.keyChallenges
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

  Widget _buildProbabilityChart(
    BuildContext context,
    ThemeData theme,
    double probability,
  ) {
    final color =
        probability >= 75
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
          color:
              theme.brightness == Brightness.dark
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
      children:
          data.map((item) {
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
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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

  Widget _buildUpcomingTaskList(
    BuildContext context,
    List<goals.ActionItem> tasks,
  ) {
    if (tasks.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final int displayCount = _isUpcomingExpanded
        ? tasks.length
        : (tasks.length > 3 ? 3 : tasks.length);
    final displayedTasks = tasks.take(displayCount).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == displayCount && tasks.length > 3) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isUpcomingExpanded = !_isUpcomingExpanded;
                });
              },
              icon: Icon(
                _isUpcomingExpanded
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 16,
              ),
              label: Text(
                _isUpcomingExpanded
                    ? 'Show Less'
                    : 'View ${tasks.length - 3} More',
              ),
            ),
          );
        }
        return _TaskTile(
          task: displayedTasks[index],
          onCompleted: _triggerXpAnimation,
        );
      }, childCount: displayedTasks.length + (tasks.length > 3 ? 1 : 0)),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<goals.ActionItem> tasks,
    String emptyMessage,
  ) {
    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            emptyMessage,
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
        ..shader =
            SweepGradient(
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
            if (task.targetDate != null) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.calendar,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][task.targetDate!.month - 1]} ${task.targetDate!.day}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
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
