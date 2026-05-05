import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/core/models/goal_model.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TaskDetailsPage extends StatefulWidget {
  final ActionItem task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  bool _isGenerating = false;
  late ConfettiController _confettiController;
  bool _showXpAnimation = false;
  int _xpGained = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    if (widget.task.steps.isEmpty) {
      _generateSteps();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _generateSteps() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final result = await AppDataStore().generateTaskSteps(widget.task.id);
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
    return ListenableBuilder(
      listenable: AppDataStore(),
      builder: (context, child) {
        // Always get the freshest data from store
        ActionItem? currentTask;
        if (AppDataStore().activeGoal != null) {
          for (var m in AppDataStore().activeGoal!.milestones) {
            for (var a in m.actionItems) {
              if (a.id == widget.task.id) {
                currentTask = a;
                break;
              }
            }
            if (currentTask != null) break;
          }
        }
        currentTask ??= widget.task;

        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(context, currentTask),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(context, currentTask),
                        const SizedBox(height: 32),
                        _buildDescription(context, currentTask),
                        const SizedBox(height: 40),
                        if (currentTask.type == 'habit')
                          _buildProgressSection(context, currentTask),
                        const SizedBox(height: 40),
                        _buildStepsSection(context, currentTask),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
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
                                    .shake(
                                      hz: 2,
                                      rotation: 0.1,
                                      duration: 400.ms,
                                    ),
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
          bottomNavigationBar: _buildBottomAction(context, currentTask),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, ActionItem task) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.moreVertical),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ActionItem task) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (task.frequency != null) ...[
              const SizedBox(width: 8),
              Text(
                '•  ${task.frequency!.toUpperCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, ActionItem task) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MISSION CONTEXT",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          task.description.isEmpty
              ? "No description provided."
              : task.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildProgressSection(BuildContext context, ActionItem task) {
    final theme = Theme.of(context);
    final progress = task.totalTarget > 0
        ? task.completedCount / task.totalTarget
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MILESTONE PROGRESS",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${task.completedCount} of ${task.totalTarget} completions achieved in this phase.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStepsSection(BuildContext context, ActionItem task) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ACTION STEPS",
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
            if (_isGenerating)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (task.steps.isEmpty && !_isGenerating)
          _buildEmptySteps(context)
        else
          ...task.steps.map((step) => _buildStepItem(context, task, step)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildStepItem(BuildContext context, ActionItem task, TaskStep step) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (!step.isCompleted) {
            _triggerXpAnimation(5);
          }
          AppDataStore().toggleTaskStep(task.id, step.id, step.isCompleted);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color?.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : (theme.brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
            ),
          ),
          child: Row(
            children: [
              Icon(
                step.isCompleted
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 20,
                color: step.isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: step.isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : null,
                    decoration: step.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (!step.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "+5 XP",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySteps(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: _generateSteps,
        icon: const Icon(LucideIcons.sparkles, size: 16),
        label: const Text("Generate AI Blueprint"),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, ActionItem task) {
    final theme = Theme.of(context);
    final isMainDone = task.isCompleted;

    // Check if all substeps are completed if any exist
    final bool hasSteps = task.steps.isNotEmpty;
    final bool allStepsDone =
        !hasSteps || task.steps.every((s) => s.isCompleted);

    // Restriction: If steps exist, only allow completion of the main item if all steps are done
    final bool canComplete = !hasSteps || allStepsDone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSteps && !allStepsDone && !isMainDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Complete all blueprint steps first",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(),
          ElevatedButton(
            onPressed: (!canComplete && !isMainDone)
                ? null
                : () {
                    AppDataStore().toggleActionItem(task.id, task.isCompleted);
                    if (!isMainDone) {
                      _triggerXpAnimation(task.type == 'habit' ? 2 : 10);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMainDone
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.primary,
              foregroundColor: isMainDone ? Colors.green : Colors.white,
              disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.3,
              ),
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              side: isMainDone
                  ? const BorderSide(color: Colors.green, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isMainDone ? LucideIcons.checkCircle : LucideIcons.zap),
                const SizedBox(width: 12),
                Text(
                  isMainDone ? "MISSION COMPLETED" : "MARK AS COMPLETE",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
