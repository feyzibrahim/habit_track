import 'package:ezucute/core/api/api_service.dart';
import 'package:ezucute/core/theme/app_colors.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:ezucute/features/auth/auth_page.dart';
import 'package:ezucute/features/planning/roadmap_preview_page.dart';
import 'package:ezucute/routes/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0; // 0: prompt, 1: questions, 2: preview

  final _promptController = TextEditingController();
  final _refinementController = TextEditingController();

  bool _isEvaluating = false;
  Map<String, dynamic>? _aiResult;
  String? _error;

  String _selectedCategory = 'productivity';
  final List<String> _categories = [
    'startup',
    'health',
    'productivity',
    'learning',
    'other',
  ];
  final _customCategoryController = TextEditingController();

  int _selectedDuration = 90;

  List<String> _questions = [];
  final List<TextEditingController> _answerControllers = [];

  Future<void> _clarify() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isEvaluating = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final result = await ApiService.clarifyGoal(prompt);
      final questions = List<String>.from(result['questions'] ?? []);
      setState(() {
        _questions = questions;
        _answerControllers.clear();
        for (var _ in questions) {
          _answerControllers.add(TextEditingController());
        }
        _step = 1;
      });
    } catch (e) {
      setState(() => _error = "Failed to generate clarifying questions.");
    } finally {
      setState(() => _isEvaluating = false);
    }
  }

  Future<void> _evaluate() async {
    setState(() {
      _isEvaluating = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    final answers = <String, String>{};
    for (int i = 0; i < _questions.length; i++) {
      answers[_questions[i]] = _answerControllers[i].text.trim();
    }

    try {
      final result = await ApiService.evaluateGoal(
        _promptController.text.trim(),
        durationDays: _selectedDuration,
        answers: answers,
      );
      setState(() {
        _aiResult = result;
        _step = 2;
      });
    } catch (e) {
      setState(() => _error = "Something went wrong. High traffic maybe?");
    } finally {
      setState(() => _isEvaluating = false);
    }
  }

  Future<Map<String, dynamic>?> _refineRoadmap(String prompt) async {
    setState(() => _isEvaluating = true);
    final answers = <String, String>{};
    for (int i = 0; i < _questions.length; i++) {
      answers[_questions[i]] = _answerControllers[i].text.trim();
    }

    try {
      final result = await ApiService.evaluateGoal(
        _promptController.text.trim(),
        durationDays: _selectedDuration,
        answers: answers,
        previousPlan: _aiResult,
        refinementPrompt: prompt,
      );
      return result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to refine roadmap.")),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  Future<void> _startPlan() async {
    if (_aiResult == null) return;

    setState(() => _isEvaluating = true);
    try {
      final category = _selectedCategory == 'other' && _customCategoryController.text.trim().isNotEmpty
          ? _customCategoryController.text.trim()
          : _selectedCategory;

      await ApiService.createGoal(
        _promptController.text.trim(),
        _aiResult!,
        durationDays: _selectedDuration,
        category: category,
      );
      await AppDataStore().refreshData();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AppShell(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = "Failed to finalize plan");
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _refinementController.dispose();
    _customCategoryController.dispose();
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget bodyContent;
    if (_step == 0) {
      bodyContent = _buildInputState(context, theme, isDark);
    } else if (_step == 1) {
      bodyContent = _buildQuestionsView(context, theme, isDark);
    } else {
      bodyContent = _buildFeasibilityView(context, theme, isDark);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () {
                  setState(() => _step--);
                },
              )
            : null,
        actions: _step == 0
            ? [
                TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.9,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: const AuthPage(
                          initialIsLogin: true,
                          disableToggle: true,
                        ),
                      ),
                    );
                    if (result == true) {
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AppShell()),
                      );
                    }
                  },
                  child: Text(
                    "Skip & Login",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: bodyContent,
        ),
      ),
    );
  }

  Widget _buildInputState(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            LucideIcons.rocket,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),

        const SizedBox(height: 32),

        Text(
          "Define your\nvision.",
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 40.sp),
        ).animate().fade().slideY(begin: 0.1),

        const SizedBox(height: 16),

        Text(
          "Describe what you want to achieve, and our Architect AI will construct a tailored roadmap for your success.",
          style: theme.textTheme.bodyMedium,
        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

        const SizedBox(height: 48),

        TextField(
          controller: _promptController,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "e.g., I want to master high-performance engineering...",
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ).animate().fade(delay: 400.ms).slideX(begin: 0.05),

        const SizedBox(height: 32),

        _buildSectionTitle(context, "MISSION TYPE"),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                    ),
                    child: Text(
                      cat.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fade(delay: 500.ms).slideX(begin: 0.1),

        if (_selectedCategory == 'other') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customCategoryController,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: "Enter custom category...",
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ).animate().fade().slideY(begin: -0.1),
        ],

        const SizedBox(height: 32),

        _buildSectionTitle(context, "MISSION TIMELINE"),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [30, 90, 180, 365].map((days) {
              final isSelected = _selectedDuration == days;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDuration = days);
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                    ),
                    child: Text(
                      "$days Days",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fade(delay: 600.ms).slideX(begin: 0.1),

        const SizedBox(height: 48),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: _isEvaluating ? null : _clarify,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isEvaluating
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
                    Text("Continue"),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 20),
                  ],
                ),
        ).animate().fade(delay: 800.ms).scaleY(begin: 0.8),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildQuestionsView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          "Let's refine.",
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 40.sp),
        ).animate().fade().slideY(begin: 0.1),
        const SizedBox(height: 16),
        Text(
          "Answer a few quick questions so we can generate the perfect roadmap for you.",
          style: theme.textTheme.bodyMedium,
        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),

        const SizedBox(height: 32),

        ...List.generate(_questions.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _questions[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _answerControllers[index],
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: "Your answer...",
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fade(delay: Duration(milliseconds: 300 + (index * 100)))
                    .slideX(begin: 0.05),
          );
        }),

        const SizedBox(height: 24),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),

        ElevatedButton(
          onPressed: _isEvaluating ? null : _evaluate,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isEvaluating
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
                    Text("Analyze with AI"),
                    SizedBox(width: 8),
                    Icon(LucideIcons.sparkles, size: 20),
                  ],
                ),
        ).animate().fade(delay: 800.ms).scaleY(begin: 0.8),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFeasibilityView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final result = _aiResult!;
    final feasibility = result['feasibility'] ?? 'moderate';
    final reason = result['feasibility_reason'] ?? "";
    final analysis = result['strategic_analysis'] ?? "";
    final challenges = List<String>.from(result['key_challenges'] ?? []);
    final graphData = List<Map<String, dynamic>>.from(
      result['graph_data'] ?? [],
    );
    final isPossible = feasibility != 'not possible';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Strategic\nAnalysis",
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 40.sp),
        ).animate().fade().slideY(begin: 0.1),
        const SizedBox(height: 32),

        _buildStatusBadge(context, feasibility).animate().fade(delay: 200.ms),
        const SizedBox(height: 16),
        Text(
          reason,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ).animate().fade(delay: 300.ms),

        const SizedBox(height: 24),
        _buildProbabilityChart(
          context,
          theme,
          (result['probability_ratio'] ?? 75).toDouble(),
        ).animate().fade(delay: 350.ms),

        const SizedBox(height: 40),
        if (analysis.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            "Strategic Approach",
          ).animate().fade(delay: 400.ms),
          const SizedBox(height: 16),
          Text(
            analysis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ).animate().fade(delay: 500.ms),
          const SizedBox(height: 40),
        ],

        if (graphData.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            "Requirements Graph",
          ).animate().fade(delay: 550.ms),
          const SizedBox(height: 16),
          _buildBarChart(
            context,
            theme,
            graphData,
          ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
          const SizedBox(height: 40),
        ],

        if (challenges.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            "Key Challenges",
          ).animate().fade(delay: 600.ms),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: challenges.map((c) => _buildChip(context, c)).toList(),
          ).animate().fade(delay: 700.ms),
          const SizedBox(height: 48),
        ],

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),

        if (isPossible)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoadmapPreviewPage(
                    initialAiResult: _aiResult!,
                    onRefine: _refineRoadmap,
                    onInitialize: _startPlan,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("View Proposed Roadmap"),
                SizedBox(width: 8),
                Icon(LucideIcons.arrowRight, size: 20),
              ],
            ),
          ).animate().fade(delay: 800.ms).scaleY(begin: 0.8)
        else
          TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text("Try another mission prompt"),
          ).animate().fade(delay: 800.ms),

        const SizedBox(height: 40),
      ],
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
                        fontSize: 34.sp,
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
                          duration: 1.seconds,
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
