class Goal {
  final String id;
  final String title;
  final String description;
  final String prompt;
  final String feasibility;
  final String? feasibilityReason;
  final String? strategicAnalysis;
  final int probabilityRatio;
  final List<String> keyChallenges;
  final List<Map<String, dynamic>> graphData;
  final String category;
  final int durationDays;
  final DateTime? startDate;
  final DateTime? targetDate;
  final String status;
  final List<Milestone> milestones;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.feasibility,
    this.feasibilityReason,
    this.strategicAnalysis,
    this.probabilityRatio = 0,
    this.keyChallenges = const [],
    this.graphData = const [],
    required this.category,
    required this.durationDays,
    this.startDate,
    this.targetDate,
    required this.status,
    this.milestones = const [],
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      prompt: json['prompt'] ?? '',
      feasibility: json['feasibility'] ?? 'moderate',
      feasibilityReason: json['feasibilityReason'],
      strategicAnalysis: json['strategicAnalysis'],
      probabilityRatio: json['probabilityRatio'] ?? 0,
      keyChallenges: List<String>.from(json['keyChallenges'] ?? []),
      graphData: (json['graphData'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      category: json['category'] ?? 'other',
      durationDays: json['durationDays'] ?? 90,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      targetDate: json['targetDate'] != null ? DateTime.tryParse(json['targetDate']) : null,
      status: json['status'] ?? 'active',
      milestones: (json['milestones'] as List? ?? [])
          .map((m) => Milestone.fromJson(m))
          .toList(),
    );
  }
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime? targetDate;
  final int order;
  final bool isCompleted;
  final List<ActionItem> actionItems;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    this.targetDate,
    required this.order,
    required this.isCompleted,
    this.actionItems = const [],
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      order: json['order'],
      isCompleted: json['isCompleted'] ?? false,
      actionItems: (json['actionItems'] as List? ?? [])
          .map((a) => ActionItem.fromJson(a))
          .toList(),
    );
  }
}

class ActionItem {
  final String id;
  final String title;
  final String description;
  final String type; // 'task', 'habit'
  final String? frequency;
  final bool isCompleted;
  final int completedCount;
  final int totalTarget;
  final DateTime? targetDate;
  final bool isOptional;
  final List<TaskStep> steps;

  ActionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.frequency,
    required this.isCompleted,
    required this.completedCount,
    required this.totalTarget,
    this.targetDate,
    this.isOptional = false,
    this.steps = const [],
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      frequency: json['frequency'],
      isCompleted: json['isCompleted'] ?? false,
      completedCount: json['completedCount'] ?? 0,
      totalTarget: json['totalTarget'] ?? 1,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      isOptional: json['isOptional'] ?? false,
      steps: (json['steps'] as List? ?? [])
          .map((s) => TaskStep.fromJson(s))
          .toList(),
    );
  }

  ActionItem copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? frequency,
    bool? isCompleted,
    int? completedCount,
    int? totalTarget,
    DateTime? targetDate,
    bool? isOptional,
    List<TaskStep>? steps,
  }) {
    return ActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      isCompleted: isCompleted ?? this.isCompleted,
      completedCount: completedCount ?? this.completedCount,
      totalTarget: totalTarget ?? this.totalTarget,
      targetDate: targetDate ?? this.targetDate,
      isOptional: isOptional ?? this.isOptional,
      steps: steps ?? this.steps,
    );
  }
}

class TaskStep {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? completedAt;
  final int order;

  TaskStep({
    required this.id,
    required this.text,
    required this.isCompleted,
    this.completedAt,
    required this.order,
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id'],
      text: json['text'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      order: json['order'] ?? 0,
    );
  }
}
