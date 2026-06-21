import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/core/models/goal_model.dart' as goals;
import 'package:ezecute/features/home/mission_widget_view.dart';
import 'package:ezecute/core/models/xp_event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:home_widget/home_widget.dart';

/// AppDataStore is the central reactive state manager for the application.
/// It synchronizes local UI state with the PostgreSQL backend via ApiService.
class AppDataStore extends ChangeNotifier {
  static final AppDataStore _instance = AppDataStore._internal();
  factory AppDataStore() => _instance;
  AppDataStore._internal();

  List<goals.Goal> currentGoals = [];
  String? _activeGoalId;
  Map<String, dynamic>? userData;
  bool isLoading = false;
  List<XpEvent> xpHistory = [];

  goals.Goal? get activeGoal {
    if (currentGoals.isEmpty) return null;
    if (_activeGoalId == null) return currentGoals.first;
    return currentGoals.firstWhere(
      (g) => g.id == _activeGoalId,
      orElse: () => currentGoals.first,
    );
  }

  void setActiveGoal(String goalId) async {
    _activeGoalId = goalId;
    isLoading = true;
    notifyListeners();

    try {
      final details = await ApiService.getGoalDetails(goalId);
      final index = currentGoals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        currentGoals[index] = goals.Goal.fromJson(details);
      }
    } catch (e) {
      debugPrint("Failed to fetch goal details on switch: $e");
    } finally {
      isLoading = false;
      notifyListeners();
      _updateNativeWidget();
    }
  }

  /// Refreshes all data from the backend
  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();
    try {
      await fetchProfile();
      await fetchGoals(skipNotify: true);
      await fetchXpHistory();
    } catch (e) {
      debugPrint("Failed to refresh data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
      _updateNativeWidget();
    }
  }

  Future<void> fetchProfile() async {
    try {
      userData = await ApiService.getProfile();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch profile: $e");
    }
  }

  Future<void> fetchXpHistory() async {
    try {
      final data = await ApiService.getXpHistory();
      xpHistory = data.map((e) => XpEvent.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch XP history: $e");
    }
  }

  Future<void> fetchGoals({bool skipNotify = false}) async {
    if (!skipNotify) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final data = await ApiService.getGoals();
      currentGoals = data.map((e) => goals.Goal.fromJson(e)).toList();

      if (currentGoals.isNotEmpty) {
        final targetGoalId = _activeGoalId ?? currentGoals.first.id;
        final details = await ApiService.getGoalDetails(targetGoalId);
        final index = currentGoals.indexWhere((g) => g.id == targetGoalId);
        if (index != -1) {
          currentGoals[index] = goals.Goal.fromJson(details);
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch goals: $e");
    } finally {
      if (!skipNotify) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Deletes a goal persistently
  Future<void> deleteGoal(String goalId) async {
    // 1. Optimistic Update
    currentGoals.removeWhere((g) => g.id == goalId);
    if (_activeGoalId == goalId) {
      _activeGoalId = currentGoals.isNotEmpty ? currentGoals.first.id : null;
    }
    notifyListeners();
    _updateNativeWidget();

    // 2. Persistent Backend Sync
    try {
      await ApiService.deleteGoal(goalId);
      await refreshData();
    } catch (e) {
      debugPrint("Failed to delete goal: $e");
      await refreshData();
    }
  }

  /// Deletes multiple goals persistently
  Future<void> deleteMultipleGoals(List<String> goalIds) async {
    if (goalIds.isEmpty) return;

    // 1. Optimistic Update
    currentGoals.removeWhere((g) => goalIds.contains(g.id));
    if (goalIds.contains(_activeGoalId)) {
      _activeGoalId = currentGoals.isNotEmpty ? currentGoals.first.id : null;
    }
    notifyListeners();
    _updateNativeWidget();

    // 2. Persistent Backend Sync
    try {
      await Future.wait(goalIds.map((id) => ApiService.deleteGoal(id)));
      await refreshData();
    } catch (e) {
      debugPrint("Failed to delete goals: $e");
      await refreshData();
    }
  }

  /// Toggles an action item (task) within a goal
  Future<void> toggleActionItem(String actionItemId, bool currentStatus) async {
    // 1. Optimistic Update
    bool found = false;
    for (var goal in currentGoals) {
      for (var m in goal.milestones) {
        for (int i = 0; i < m.actionItems.length; i++) {
          if (m.actionItems[i].id == actionItemId) {
            final old = m.actionItems[i];
            m.actionItems[i] = old.copyWith(
              isCompleted: !currentStatus,
              completedCount: !currentStatus && old.type == 'habit'
                  ? old.completedCount + 1
                  : old.completedCount,
            );
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (found) break;
    }

    if (found) {
      notifyListeners();
      _updateNativeWidget();
    }

    // 2. Persistent Backend Sync
    try {
      await ApiService.updateActionItem(actionItemId, !currentStatus);
      await fetchGoals(skipNotify: true); // Sync latest success percentages and feasibility reasons!
      notifyListeners();
    } catch (e) {
      debugPrint("Action item sync failed: $e");
    }
  }

  /// Generates steps for an action item if missing
  Future<goals.ActionItem?> generateTaskSteps(String actionItemId) async {
    try {
      final data = await ApiService.generateActionItemSteps(actionItemId);
      final updatedActionItem = goals.ActionItem.fromJson(data);

      // Update in local state
      if (activeGoal != null) {
        for (var m in activeGoal!.milestones) {
          for (int i = 0; i < m.actionItems.length; i++) {
            if (m.actionItems[i].id == actionItemId) {
              m.actionItems[i] = updatedActionItem;
              notifyListeners();
              return updatedActionItem;
            }
          }
        }
      }
      return updatedActionItem;
    } catch (e) {
      debugPrint("Failed to generate task steps: $e");
      return null;
    }
  }

  /// Generates tasks for an empty milestone
  Future<goals.Milestone?> generateTasksForMilestone(String milestoneId) async {
    try {
      final data = await ApiService.generateTasksForMilestone(milestoneId);
      final updatedMilestone = goals.Milestone.fromJson(data);

      // Update in local state
      if (activeGoal != null) {
        for (int i = 0; i < activeGoal!.milestones.length; i++) {
          if (activeGoal!.milestones[i].id == milestoneId) {
            activeGoal!.milestones[i] = updatedMilestone;
            notifyListeners();
            return updatedMilestone;
          }
        }
      }
      return updatedMilestone;
    } catch (e) {
      debugPrint("Failed to generate milestone tasks: $e");
      rethrow;
    }
  }

  /// Toggles a specific step within a task
  Future<void> toggleTaskStep(
    String actionItemId,
    String stepId,
    bool currentStatus,
  ) async {
    // 1. Optimistic Update
    if (activeGoal != null) {
      for (var m in activeGoal!.milestones) {
        for (int i = 0; i < m.actionItems.length; i++) {
          if (m.actionItems[i].id == actionItemId) {
            final steps = List<goals.TaskStep>.from(m.actionItems[i].steps);
            final stepIndex = steps.indexWhere((s) => s.id == stepId);
            if (stepIndex != -1) {
              final oldStep = steps[stepIndex];
              steps[stepIndex] = goals.TaskStep(
                id: oldStep.id,
                text: oldStep.text,
                isCompleted: !currentStatus,
                completedAt: !currentStatus ? DateTime.now() : null,
                order: oldStep.order,
              );
              m.actionItems[i] = m.actionItems[i].copyWith(steps: steps);
              notifyListeners();
            }
            break;
          }
        }
      }
    }

    // 2. Persistent
    try {
      await ApiService.toggleTaskStep(stepId, !currentStatus);
      await fetchGoals(skipNotify: true);
      notifyListeners();
    } catch (e) {
      debugPrint("Step toggle failed: $e");
    }
  }

  List<goals.Milestone> get _allCurrentMilestones {
    final List<goals.Milestone> milestones = [];
    final now = DateTime.now();
    final active = currentGoals.where((g) => g.status == 'active').toList();
    for (var goal in active) {
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
        milestones.add(current);
      }
    }
    return milestones;
  }

  /// Aggregates tasks for the current day across all active goals
  List<goals.ActionItem> get todaysDailyTasks {
    final List<goals.ActionItem> tasks = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var milestone in _allCurrentMilestones) {
      for (var task in milestone.actionItems) {
        if (task.targetDate != null) {
          final target = DateTime(task.targetDate!.year, task.targetDate!.month, task.targetDate!.day);
          if (target.isAtSameMomentAs(today)) {
            tasks.add(task);
          }
        } else {
          tasks.add(task);
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

  /// Aggregates past/overdue tasks across all active goals
  List<goals.ActionItem> get pastDaysTasks {
    final List<goals.ActionItem> tasks = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var milestone in _allCurrentMilestones) {
      for (var task in milestone.actionItems) {
        if (task.targetDate != null) {
          final target = DateTime(task.targetDate!.year, task.targetDate!.month, task.targetDate!.day);
          if (target.isBefore(today)) {
            tasks.add(task);
          }
        }
      }
    }
    
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.targetDate == null && b.targetDate == null) return 0;
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });
    return tasks;
  }

  /// Aggregates tasks scheduled for future days across all active goals
  List<goals.ActionItem> get otherDaysTasks {
    final List<goals.ActionItem> tasks = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var milestone in _allCurrentMilestones) {
      for (var task in milestone.actionItems) {
        if (task.targetDate != null) {
          final target = DateTime(task.targetDate!.year, task.targetDate!.month, task.targetDate!.day);
          if (target.isAfter(today)) {
            tasks.add(task);
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

  goals.Milestone? get _currentMilestone {
    if (activeGoal == null) return null;
    final now = DateTime.now();
    for (var m in activeGoal!.milestones) {
      if (!m.isCompleted) return m;
      if (m.targetDate != null && m.targetDate!.isAfter(now)) return m;
    }
    return activeGoal!.milestones.lastOrNull;
  }

  /// Returns a list of 7 booleans indicating whether each day of the current week (Mon-Sun) is "done".
  /// A day is "done" if the user has completed at least one required mission/habit on that day.
  List<bool> get currentWeekStreakStatus {
    final List<bool> streak = List.filled(7, false);
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // Mon is 1, Sun is 7
    final monday = now.subtract(Duration(days: currentDayOfWeek - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);

    for (int i = 0; i < 7; i++) {
      final day = startOfMonday.add(Duration(days: i));
      if (day.isAfter(now)) {
        streak[i] = false;
        continue;
      }

      final hasCompletedOnDay = xpHistory.any((event) {
        final evDate = DateTime(event.date.year, event.date.month, event.date.day);
        final targetDate = DateTime(day.year, day.month, day.day);
        return evDate.isAtSameMomentAs(targetDate);
      });
      
      streak[i] = hasCompletedOnDay;
    }
    return streak;
  }

  double get goalProgress {
    if (activeGoal == null || activeGoal!.milestones.isEmpty) return 0.0;
    int totalItems = 0;
    int completedItems = 0;
    for (var m in activeGoal!.milestones) {
      for (var a in m.actionItems) {
        totalItems++;
        if (a.isCompleted) completedItems++;
      }
    }
    return totalItems == 0 ? 0.0 : completedItems / totalItems;
  }

  int get userScore {
    int score = 0;
    for (var g in currentGoals) {
      if (g.status == 'completed') score += 50; // Bonus for completed goal
      for (var m in g.milestones) {
        for (var a in m.actionItems) {
          if (a.isCompleted) score += 10;
          if (a.type == 'habit') score += (a.completedCount * 2);
          for (var s in a.steps) {
            if (s.isCompleted) score += 5;
          }
        }
      }
    }
    return score;
  }

  void _updateNativeWidget() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final active = activeGoal;
    if (active == null) return;

    final double progress = goalProgress;
    final tasks = todaysDailyTasks;
    final nextTask = tasks.where((t) => !t.isCompleted).firstOrNull;

    // 1. Render widgets to images
    try {
      await HomeWidget.renderFlutterWidget(
        MissionWidgetView(goal: active, nextTask: nextTask, progress: progress),
        key: 'widgetImage',
        logicalSize: const Size(320, 160),
      );
      await HomeWidget.renderFlutterWidget(
        MinimalMissionWidgetView(score: userScore),
        key: 'minimalWidgetImage',
        logicalSize: const Size(160, 160),
      );
    } catch (e) {
      debugPrint("Failed to render widget: $e");
    }

    // 3. Trigger OS update
    HomeWidget.updateWidget(
      iOSName: 'HabitWidget',
      androidName: 'HabitWidgetProvider',
    );
    HomeWidget.updateWidget(
      iOSName: 'MinimalWidget',
      androidName: 'MinimalWidgetProvider',
    );
  }
}
