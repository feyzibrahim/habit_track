import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:ezucute/core/models/goal_model.dart';
import 'package:ezucute/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ezucute/features/chat/chat_page.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Roadmap'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'timeline_fab',
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
      body: ListenableBuilder(
        listenable: AppDataStore(),
        builder: (context, child) {
          final store = AppDataStore();
          final goal = store.activeGoal;

          if (goal == null) {
            return Center(
              child: Text(
                "No active timeline. Start a mission first.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: store.refreshData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Progress Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat(
                          context,
                          "PHASES",
                          goal.milestones.length.toString(),
                        ),
                        _buildMiniStat(
                          context,
                          "PROGRESS",
                          "${(store.goalProgress * 100).toInt()}%",
                        ),
                        _buildMiniStat(
                          context,
                          "XP",
                          store.userScore.toString(),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ),
                ),

                // Timeline List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final milestone = goal.milestones[index];
                      // Find if this is the currently active milestone
                      final bool isCurrent =
                          !milestone.isCompleted &&
                          (index == 0 ||
                              goal.milestones[index - 1].isCompleted);

                      return _buildAdvancedTimelineItem(
                        context,
                        milestone,
                        index == goal.milestones.length - 1,
                        isCurrent,
                      );
                    }, childCount: goal.milestones.length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedTimelineItem(
    BuildContext context,
    Milestone milestone,
    bool isLast,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateStr = milestone.targetDate != null
        ? DateFormat('dd MMMM yyyy').format(milestone.targetDate!)
        : "PHASE ${milestone.order}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Indicator with line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : (milestone.isCompleted
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    width: 2,
                  ),
                ),
                child: milestone.isCompleted
                    ? Icon(
                        LucideIcons.check,
                        size: 16,
                        color: theme.colorScheme.primary,
                      )
                    : Center(
                        child: Text(
                          milestone.order.toString(),
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: milestone.isCompleted
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          // Right side: Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isCurrent) _buildCurrentBadge(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    milestone.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: milestone.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: milestone.isCompleted
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phase Action Items Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: milestone.actionItems
                          .map(
                            (action) => _ActionMiniRow(
                              action: action,
                              key: ValueKey(action.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Widget _buildCurrentBadge(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "ACTIVE",
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
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

  Future<void> _generateSteps() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final result = await AppDataStore().generateTaskSteps(widget.action.id);
      if (mounted) {
        if (result == null || result.steps.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not generate steps. Please try again."),
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSteps = widget.action.steps.isNotEmpty;
    final allStepsDone =
        !hasSteps || widget.action.steps.every((s) => s.isCompleted);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(widget.action.id), // Preserve expansion state
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(36, 0, 4, 8),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
          children: [
            GestureDetector(
              onTap: () {
                if (!allStepsDone && !widget.action.isCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Complete all blueprint steps first"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                AppDataStore().toggleActionItem(
                  widget.action.id,
                  widget.action.isCompleted,
                );
              },
              child: Icon(
                widget.action.isCompleted
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 18,
                color: !allStepsDone && !widget.action.isCompleted
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                    : (widget.action.isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.action.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.action.isCompleted
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : null,
                  decoration: widget.action.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            if (widget.action.type == 'habit')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${widget.action.completedCount}/${widget.action.totalTarget} (+2 XP)",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "+10 XP",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber,
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
                          fontSize: 11,
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
                  fontSize: 11,
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
