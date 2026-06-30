import 'package:execut/core/models/goal_model.dart';
import 'package:execut/core/theme/app_colors.dart';
import 'package:execut/data/app_data_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TimelinePage extends StatelessWidget {
  final Goal goal;

  const TimelinePage({super.key, required this.goal});

  void _confirmDelete(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text("Delete Mission"),
          content: Text(
            "Are you sure you want to permanently delete \"${goal.title}\"? This will erase all milestones, daily quests, and progress history.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Deleting mission \"${goal.title}\"..."),
                    backgroundColor: Colors.amber,
                  ),
                );
                try {
                  await AppDataStore().deleteGoal(goal.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Mission deleted successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to delete: $e"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final theme = parentTheme.copyWith(
      textTheme: GoogleFonts.robotoTextTheme(parentTheme.textTheme),
    );
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Roadmap'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, goal),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: AppDataStore(),
          builder: (context, child) {
            final store = AppDataStore();
            final activeGoal = store.currentGoals.firstWhere(
              (g) => g.id == goal.id,
              orElse: () => goal,
            );

            int totalItems = 0;
            int completedItems = 0;
            for (var m in activeGoal.milestones) {
              for (var a in m.actionItems) {
                totalItems++;
                if (a.isCompleted) completedItems++;
              }
            }
            final progress = totalItems == 0
                ? 0.0
                : completedItems / totalItems;

            final createdAtStr = DateFormat(
              'MMMM d',
            ).format(activeGoal.startDate ?? DateTime.now());
            final metaText =
                "Started $createdAtStr · ${activeGoal.milestones.length} phases";

            return RefreshIndicator(
              onRefresh: store.refreshData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              LucideIcons.target,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activeGoal.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            metaText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  "PROGRESS",
                                  "${(progress * 100).toInt()}%",
                                  isPrimary: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  "PHASES",
                                  "${activeGoal.milestones.length}",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  "XP",
                                  "${store.userScore}",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "OVERALL PROGRESS",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "$completedItems of $totalItems",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface3
                                  : AppColors.lightSurface2,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              height: 8,
                              width:
                                  MediaQuery.of(context).size.width *
                                  progress, // Approximation
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final milestone = activeGoal.milestones[index];
                        final bool isCurrent =
                            !milestone.isCompleted &&
                            (index == 0 ||
                                activeGoal.milestones[index - 1].isCompleted);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _PhaseCard(
                                    milestone: milestone,
                                    index: index,
                                    isCurrent: isCurrent,
                                    initiallyExpanded:
                                        isCurrent ||
                                        (!(activeGoal.milestones.every(
                                              (m) => m.isCompleted,
                                            )) &&
                                            index == 0 &&
                                            milestone.isCompleted &&
                                            activeGoal.milestones.length > 1 &&
                                            !activeGoal
                                                .milestones[1]
                                                .isCompleted),
                                  )
                                  .animate()
                                  .fadeIn(delay: (200 + index * 100).ms)
                                  .slideY(begin: 0.1),
                        );
                      }, childCount: activeGoal.milestones.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value, {
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPrimary
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatefulWidget {
  final Milestone milestone;
  final int index;
  final bool isCurrent;
  final bool initiallyExpanded;

  const _PhaseCard({
    required this.milestone,
    required this.index,
    required this.isCurrent,
    this.initiallyExpanded = false,
  });

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  int _visibleUncompletedCount = 3;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded || widget.isCurrent;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _iconTurns = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final milestone = widget.milestone;

    final dateStr = milestone.targetDate != null
        ? DateFormat('dd MMMM yyyy').format(milestone.targetDate!)
        : "Phase ${milestone.order}";

    final isDone = milestone.isCompleted;
    final isActive = widget.isCurrent;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isDone) {
      badgeBg = theme.colorScheme.primary.withValues(alpha: 0.15);
      badgeText = theme.colorScheme.primary;
      badgeLabel = "Complete";
    } else if (isActive) {
      badgeBg = theme.colorScheme.primary;
      badgeText = Colors.white;
      badgeLabel = "Active";
    } else {
      badgeBg = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
      badgeText = theme.colorScheme.onSurface.withValues(alpha: 0.5);
      badgeLabel = "Upcoming";
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDone
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : (isActive
                                ? theme.colorScheme.primary
                                : (isDark
                                      ? AppColors.darkSurface3
                                      : AppColors.lightSurface2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        milestone.order.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDone || isActive
                              ? (isDone
                                    ? theme.colorScheme.primary
                                    : Colors.white)
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: badgeText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _heightFactor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: () {
                  if (milestone.actionItems.isEmpty) {
                    return [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface2
                              : AppColors.lightSurface2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.calendarClock,
                              size: 24,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Tasks haven't been generated yet.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _GenerateTasksButton(milestoneId: milestone.id),
                          ],
                        ),
                      ),
                    ];
                  }

                  final sortedItems =
                      List<ActionItem>.from(milestone.actionItems)
                        ..sort((a, b) {
                          if (a.targetDate == null && b.targetDate == null) {
                            return 0;
                          }
                          if (a.targetDate == null) return 1;
                          if (b.targetDate == null) return -1;
                          return a.targetDate!.compareTo(b.targetDate!);
                        });

                  final uncompletedItems = sortedItems
                      .where((i) => !i.isCompleted)
                      .toList();
                  final completedItems = sortedItems
                      .where((i) => i.isCompleted)
                      .toList();

                  final widgets = <Widget>[];

                  if (completedItems.isNotEmpty) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showCompleted = !_showCompleted;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showCompleted
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showCompleted
                                      ? "Hide completed"
                                      : "View ${completedItems.length} completed",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    if (_showCompleted) {
                      widgets.addAll(
                        completedItems.map(
                          (action) => _ActionMiniRow(
                            action: action,
                            key: ValueKey(action.id),
                          ),
                        ),
                      );
                    }
                  }

                  final visibleUncompleted = uncompletedItems
                      .take(_visibleUncompletedCount)
                      .toList();
                  widgets.addAll(
                    visibleUncompleted.map(
                      (action) => _ActionMiniRow(
                        action: action,
                        key: ValueKey(action.id),
                      ),
                    ),
                  );

                  if (uncompletedItems.length > _visibleUncompletedCount) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _visibleUncompletedCount =
                                      (_visibleUncompletedCount + 3).clamp(
                                        0,
                                        uncompletedItems.length,
                                      );
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "View more",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _visibleUncompletedCount =
                                      uncompletedItems.length;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "View all",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return widgets;
                }(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMiniRow extends StatefulWidget {
  final ActionItem action;
  const _ActionMiniRow({super.key, required this.action});
  @override
  State<_ActionMiniRow> createState() => _ActionMiniRowState();
}

class _ActionMiniRowState extends State<_ActionMiniRow> {
  bool _isGenerating = false;
  bool _isTransitioning = false;

  @override
  void didUpdateWidget(covariant _ActionMiniRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action.isCompleted != widget.action.isCompleted) {
      _isTransitioning = false;
    }
  }

  Future<void> _generateSteps() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final result = await AppDataStore().generateTaskSteps(widget.action.id);
      if (mounted) {
        if (result == null || result.steps.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not generate steps."),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("AI Blueprint generated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSteps = widget.action.steps.isNotEmpty;
    final allStepsDone =
        !hasSteps || widget.action.steps.every((s) => s.isCompleted);
    final isDone = widget.action.isCompleted;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 350),
      crossFadeState: _isTransitioning ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      secondChild: const SizedBox(width: double.infinity, height: 0),
      firstChild: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(widget.action.id),
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.fromLTRB(40, 0, 4, 8),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.3,
            ),
            trailing: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onExpansionChanged: (expanded) {
              if (expanded && widget.action.steps.isEmpty) {
                _generateSteps();
              }
            },
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_isTransitioning) return;
                    if (!allStepsDone && !isDone) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Complete all blueprint steps first"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    
                    setState(() {
                      _isTransitioning = true;
                    });
                    
                    await Future.delayed(const Duration(milliseconds: 350));
                    if (!mounted) return;
                    
                    AppDataStore().toggleActionItem(
                      widget.action.id,
                      widget.action.isCompleted,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone
                            ? theme.colorScheme.primary
                            : (!allStepsDone && !isDone
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.1,
                                    )
                                  : (isDark
                                        ? AppColors.darkBorder2
                                        : AppColors.lightBorder)),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            LucideIcons.check,
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
                        widget.action.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDone
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.action.targetDate != null ||
                          widget.action.isOptional)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              if (widget.action.targetDate != null)
                                Text(
                                  DateFormat(
                                    'MMM dd',
                                  ).format(widget.action.targetDate!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (widget.action.targetDate != null &&
                                  widget.action.isOptional)
                                const SizedBox(width: 8),
                              if (widget.action.isOptional)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "OPTIONAL",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.action.type == 'habit')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${widget.action.completedCount}/${widget.action.totalTarget} (+2 XP)",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "+10 XP",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            children: _isGenerating
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Generating AI Blueprint...",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : widget.action.steps
                      .map((step) => _buildStepRow(context, widget.action, step))
                      .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, ActionItem action, TaskStep step) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () =>
          AppDataStore().toggleTaskStep(action.id, step.id, step.isCompleted),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              step.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 14,
              color: step.isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: step.isCompleted
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  decoration: step.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateTasksButton extends StatefulWidget {
  final String milestoneId;
  const _GenerateTasksButton({required this.milestoneId});
  @override
  State<_GenerateTasksButton> createState() => _GenerateTasksButtonState();
}

class _GenerateTasksButtonState extends State<_GenerateTasksButton> {
  bool _isLoading = false;

  Future<void> _handleGenerate() async {
    setState(() => _isLoading = true);
    try {
      await AppDataStore().generateTasksForMilestone(widget.milestoneId);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to generate tasks."),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleGenerate,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text("Generate Tasks"),
    );
  }
}
