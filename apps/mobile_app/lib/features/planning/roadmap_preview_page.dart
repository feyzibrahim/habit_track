import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RoadmapPreviewPage extends StatefulWidget {
  final Map<String, dynamic> initialAiResult;
  final Future<Map<String, dynamic>?> Function(String) onRefine;
  final Future<void> Function() onInitialize;

  const RoadmapPreviewPage({
    super.key,
    required this.initialAiResult,
    required this.onRefine,
    required this.onInitialize,
  });

  @override
  State<RoadmapPreviewPage> createState() => _RoadmapPreviewPageState();
}

class _RoadmapPreviewPageState extends State<RoadmapPreviewPage> {
  late Map<String, dynamic> _aiResult;
  final _refinementController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _aiResult = widget.initialAiResult;
  }

  @override
  void dispose() {
    _refinementController.dispose();
    super.dispose();
  }

  Future<void> _handleRefine() async {
    final prompt = _refinementController.text.trim();
    if (prompt.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final newResult = await widget.onRefine(prompt);
      if (newResult != null && mounted) {
        setState(() {
          _aiResult = newResult;
          _refinementController.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleInitialize() async {
    setState(() => _isLoading = true);
    try {
      await widget.onInitialize();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _aiResult['plan'];
    final milestones = plan != null ? List<dynamic>.from(plan['milestones'] ?? []) : [];
    final goalTitle = _aiResult['goal_title'] ?? plan?['goal_title'] ?? 'Your Goal';
    final totalWeeks = milestones.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Roadmap Preview'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _buildHeader(context, goalTitle, totalWeeks),
                const SizedBox(height: 24),
                ...List.generate(milestones.length, (index) {
                  final phase = milestones[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PhaseCard(
                      phase: phase as Map<String, dynamic>,
                      index: index,
                      totalPhases: milestones.length,
                      initiallyExpanded: index == 0,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: (index * 150).ms)
                        .slideY(begin: 0.1, end: 0, duration: 600.ms),
                  );
                }),
              ],
            ),
          ),
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, int duration) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            LucideIcons.target, // using target instead of concentric circles if not available, or combine
            size: 28,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "AI Generated Plan · $duration Phases",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
                      "PREVIEW",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "STATUS",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 0.06,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
                      "$duration",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "PHASES",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 0.06,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _refinementController,
              decoration: InputDecoration(
                hintText: "Change anything? (e.g. Make it harder)",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                suffixIcon: IconButton(
                  icon: Icon(LucideIcons.refreshCw, color: theme.colorScheme.primary),
                  onPressed: _isLoading ? null : _handleRefine,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleInitialize,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Initialize Roadmap",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.check, size: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatefulWidget {
  final Map<String, dynamic> phase;
  final int index;
  final int totalPhases;
  final bool initiallyExpanded;

  const _PhaseCard({
    required this.phase,
    required this.index,
    required this.totalPhases,
    this.initiallyExpanded = false,
  });

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _heightFactor = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

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
    
    final order = widget.phase['weeks_from_start'] ?? (widget.index + 1);
    final targetDateStr = widget.phase['target_date'];
    final dateStr = targetDateStr != null
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(targetDateStr))
        : "Phase $order";
    final title = widget.phase['title'] ?? 'Phase $order';

    final isFirst = widget.index == 0;
    
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isFirst 
                          ? theme.colorScheme.primary 
                          : (isDark ? AppColors.darkSurface3 : AppColors.lightSurface2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(
                        order.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isFirst 
                              ? Colors.white 
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? theme.colorScheme.primary
                          : (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      isFirst ? "Starting soon" : "Upcoming",
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: isFirst
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                  final items = List<dynamic>.from(widget.phase['action_items'] ?? []);
                  items.sort((a, b) {
                    final dayA = a['day_from_start'] as int? ?? 999;
                    final dayB = b['day_from_start'] as int? ?? 999;
                    return dayA.compareTo(dayB);
                  });
                  if (items.isEmpty) {
                    return [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.calendarClock,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Tasks will be generated later",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    ];
                  }
                  return items.map((action) {
                    return _buildInnerMilestone(context, action);
                  }).toList();
                }(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerMilestone(BuildContext context, dynamic action) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final type = action['type'] ?? 'task';
    final target = action['total_target'] ?? 1;
    final title = action['title'] ?? 'Action';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder2 : AppColors.lightBorder,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type == 'habit' 
                      ? "Daily habit · Target: $target" 
                      : "One-time action",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (type == 'habit')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "0/$target (+2 XP)",
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
