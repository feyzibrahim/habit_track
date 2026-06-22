import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:ezecute/core/models/goal_model.dart' as goals;
import 'package:ezecute/data/app_data_store.dart';

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  String _activeTab = 'today'; // 'today', 'quests', 'side', 'boss'
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

  Widget _buildTabChip(
    String id,
    String label,
    String activeTab,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = activeTab == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isActive
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: AppDataStore(),
            builder: (context, child) {
              final store = AppDataStore();

              if (store.currentGoals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.swords,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No active battles yet.",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create an execution plan first to deploy quests to the Arena.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: store.refreshData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Daily Battlefield",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Tabs row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildTabChip(
                                    'today',
                                    'Today',
                                    _activeTab,
                                    () => setState(() => _activeTab = 'today'),
                                  ),
                                  _buildTabChip(
                                    'quests',
                                    'Quests',
                                    _activeTab,
                                    () => setState(() => _activeTab = 'quests'),
                                  ),
                                  _buildTabChip(
                                    'side',
                                    'Side Quests',
                                    _activeTab,
                                    () => setState(() => _activeTab = 'side'),
                                  ),
                                  _buildTabChip(
                                    'boss',
                                    'Boss Challenges',
                                    _activeTab,
                                    () => setState(() => _activeTab = 'boss'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content based on tab
                    if (_activeTab == 'today')
                      _buildTodayTab(context, store)
                    else if (_activeTab == 'quests')
                      _buildQuestsTab(context, store)
                    else if (_activeTab == 'side')
                      _buildSideQuestsTab(context, store)
                    else if (_activeTab == 'boss')
                      _buildBossTab(context, store),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

  // --- TODAY TAB ---
  Widget _buildTodayTab(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Aggregate today's tasks and overdue past tasks
    final todaysTasks = store.todaysDailyTasks;
    final pastTasks = store.pastDaysTasks;
    final combinedTasks = [...pastTasks, ...todaysTasks];

    // Banner metrics
    int dayCount = 1;
    final activeGoal = store.activeGoal;
    if (activeGoal != null && activeGoal.startDate != null) {
      dayCount = DateTime.now().difference(activeGoal.startDate!).inDays + 1;
      if (dayCount < 1) dayCount = 1;
    }

    final totalTasks = combinedTasks.length;
    final completedTasksCount = combinedTasks
        .where((t) => t.isCompleted)
        .toList()
        .length;
    final incompleteCount = totalTasks - completedTasksCount;
    final double completionProgress = totalTasks == 0
        ? 0.0
        : (completedTasksCount / totalTasks);
    final weekdayName = DateFormat('EEEE').format(DateTime.now());

    final requiredMissions = todaysTasks
        .where((t) => !t.isOptional && t.type != 'boss')
        .toList();
    final optionalMissions = todaysTasks.where((t) => t.isOptional).toList();
    final backlogMissions = pastTasks;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),
          // Day Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                // Day Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "$dayCount",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Day $dayCount — Keep the streak",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$weekdayName · $incompleteCount missions left",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(completionProgress * 100).toInt()}%",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      "$completedTasksCount/$totalTasks done",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, duration: 300.ms),

          const SizedBox(height: 24),

          // Required Missions
          if (requiredMissions.isNotEmpty) ...[
            _buildSectionHeader(context, "Required missions"),
            const SizedBox(height: 8),
            ...requiredMissions.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                key: ValueKey(task.id),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Optional today
          if (optionalMissions.isNotEmpty) ...[
            _buildSectionHeader(context, "Optional today"),
            const SizedBox(height: 8),
            ...optionalMissions.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                key: ValueKey(task.id),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Backlog Missions
          if (backlogMissions.isNotEmpty) ...[
            _buildSectionHeader(context, "Backlog missions"),
            const SizedBox(height: 8),
            ...backlogMissions.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                showDate: true,
                key: ValueKey(task.id),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (requiredMissions.isEmpty &&
              optionalMissions.isEmpty &&
              backlogMissions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 32,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No quests scheduled for today.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // --- QUESTS TAB ---
  Widget _buildQuestsTab(BuildContext context, AppDataStore store) {
    final combined = [
      ...store.pastDaysTasks,
      ...store.todaysDailyTasks,
      ...store.otherDaysTasks,
    ];
    final quests = combined
        .where((t) => !t.isOptional && t.type != 'boss')
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),
          _buildSectionHeader(context, "All active quests"),
          const SizedBox(height: 8),
          if (quests.isEmpty)
            _buildEmptyState(context, "No active quests found.")
          else
            ...quests.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                key: ValueKey(task.id),
              ),
            ),
        ]),
      ),
    );
  }

  // --- SIDE QUESTS TAB ---
  Widget _buildSideQuestsTab(BuildContext context, AppDataStore store) {
    final combined = [
      ...store.pastDaysTasks,
      ...store.todaysDailyTasks,
      ...store.otherDaysTasks,
    ];
    final sideQuests = combined.where((t) => t.isOptional).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),
          _buildSectionHeader(
            context,
            "Bonus missions — optional but worth it",
          ),
          const SizedBox(height: 8),
          if (sideQuests.isEmpty)
            _buildEmptyState(context, "No optional side quests found.")
          else
            ...sideQuests.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                key: ValueKey(task.id),
              ),
            ),
        ]),
      ),
    );
  }

  // --- BOSS TAB ---
  Widget _buildBossTab(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final combined = [
      ...store.pastDaysTasks,
      ...store.todaysDailyTasks,
      ...store.otherDaysTasks,
    ];
    final bossChallenges = combined
        .where(
          (t) => t.type == 'boss' || t.title.toLowerCase().contains('boss'),
        )
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),
          // Boss Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0E0C18), const Color(0xFF141028)]
                    : [const Color(0xFFF3F0FA), const Color(0xFFEBE6F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF3A3060) : AppColors.lightTertiary.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkTertiary : AppColors.lightTertiary).withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("⚔️", style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      "BOSS CHALLENGES",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? AppColors.darkTertiary : AppColors.lightTertiary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "The Visibility Test",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Fulfill high-stakes phase objectives. Toggling these challenges triggers massive XP drops (+200 XP) and pushes your goal success probability up significantly.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, duration: 300.ms),

          const SizedBox(height: 24),
          _buildSectionHeader(context, "Active boss challenges"),
          const SizedBox(height: 8),
          if (bossChallenges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.swords,
                      size: 32,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No boss challenges active this phase.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...bossChallenges.map(
              (task) => _MissionCardWidget(
                task: task,
                onCompleted: _triggerXpAnimation,
                key: ValueKey(task.id),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// --- MISSION CARD WIDGET ---
class _MissionCardWidget extends StatefulWidget {
  final goals.ActionItem task;
  final void Function(int xpGained)? onCompleted;
  final bool showDate;

  const _MissionCardWidget({
    super.key,
    required this.task,
    this.onCompleted,
    this.showDate = false,
  });

  @override
  State<_MissionCardWidget> createState() => _MissionCardWidgetState();
}

class _MissionCardWidgetState extends State<_MissionCardWidget> {
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

    // Style configurations
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
              // Left stripe indicator
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
                      // Card Top Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Checkbox
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
                          // Task Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle Type Tag
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
                                // Title
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
                                // Description
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
                                // Footer items
                                Row(
                                  children: [
                                    // XP Tag
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
                                    // Expand Details Button
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

                      // Expandable Sub-tasks (AI Blueprint Steps)
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
