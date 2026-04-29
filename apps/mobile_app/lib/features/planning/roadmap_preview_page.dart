import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezucute/core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final milestones = plan != null
        ? List<dynamic>.from(plan['milestones'] ?? [])
        : [];

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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: milestones.length,
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                return _buildTimelineItem(
                  context,
                  milestone,
                  index,
                  index == milestones.length - 1,
                );
              },
            ),
          ),

          // Refinement and Initialize actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
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
                  _buildRefinementInput(context),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleInitialize,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 64),
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
                              Text("Initialize Roadmap"),
                              SizedBox(width: 8),
                              Icon(LucideIcons.check, size: 20),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinementInput(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
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
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Map<String, dynamic> milestone,
    int index,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final order = milestone['weeks_from_start'] ?? (index + 1);
    final isCurrent = index == 0; // In preview, first item is "current"

    return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? theme.colorScheme.primary
                          : Colors.transparent,
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
                    child: Center(
                      child: Text(
                        order.toString(),
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
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
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
                            "PHASE $order",
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
                        milestone['title'] ?? 'Milestone',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        milestone['description'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (milestone['action_items'] != null)
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
                            children:
                                (milestone['action_items'] as List<dynamic>)
                                    .map((action) {
                                      return _buildActionMiniRow(
                                        context,
                                        action,
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: (index * 150).ms)
        .slideX(begin: 0.05);
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
        "PREVIEW",
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionMiniRow(BuildContext context, dynamic action) {
    final theme = Theme.of(context);
    final type = action['type'] ?? 'task';
    final target = action['total_target'] ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action['title'] ?? 'Action',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
    );
  }
}
