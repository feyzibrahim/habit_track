import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ezecute/data/app_data_store.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezecute/core/models/goal_model.dart' as goals;

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedGoalIds = {};

  void _toggleSelection(String goalId) {
    setState(() {
      if (_selectedGoalIds.contains(goalId)) {
        _selectedGoalIds.remove(goalId);
        if (_selectedGoalIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedGoalIds.add(goalId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedGoalIds.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<goals.Goal> goalsList) {
    setState(() {
      _selectedGoalIds.addAll(goalsList.map((g) => g.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedGoalIds.clear();
    });
  }

  void _confirmDeleteSelected(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Delete Selected"),
            ],
          ),
          content: Text(
            "Are you sure you want to delete the ${_selectedGoalIds.length} selected mission(s)?\n\nThis will permanently erase all associated milestones, daily tasks, and progress history."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final idsToDelete = _selectedGoalIds.toList();
                _clearSelection();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Deleting selected missions..."),
                    backgroundColor: Colors.amber,
                  ),
                );
                
                try {
                  await AppDataStore().deleteMultipleGoals(idsToDelete);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Missions deleted successfully"),
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
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAll(BuildContext context, List<String> allGoalIds) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isCheckboxChecked = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text("Danger Zone: Delete All"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You are about to permanently delete ALL missions in your dashboard.\n\nThis action cannot be undone and will completely reset your progress, history, and active roadmap.",
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      setStateDialog(() {
                        isCheckboxChecked = !isCheckboxChecked;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCheckboxChecked ? LucideIcons.checkSquare : LucideIcons.square,
                            color: isCheckboxChecked ? Colors.redAccent : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "I understand that this will permanently erase all my data and is 100% irreversible.",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isCheckboxChecked
                      ? () async {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Deleting all missions..."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          try {
                            await AppDataStore().deleteMultipleGoals(allGoalIds);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("All missions deleted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to delete all: $e"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text("DELETE ALL"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: AppDataStore(),
      builder: (context, child) {
        final store = AppDataStore();
        final goals = store.currentGoals;

        // Ensure we exit selection mode if the list becomes empty
        if (goals.isEmpty && _isSelectionMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isSelectionMode = false;
              _selectedGoalIds.clear();
            });
          });
        }

        return Scaffold(
          appBar: _isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: _clearSelection,
                  ),
                  title: Text(
                    "${_selectedGoalIds.length} Selected",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _selectedGoalIds.length == goals.length
                            ? LucideIcons.checkSquare
                            : LucideIcons.square,
                      ),
                      tooltip: "Select All",
                      onPressed: () {
                        if (_selectedGoalIds.length == goals.length) {
                          _deselectAll();
                        } else {
                          _selectAll(goals);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                      tooltip: "Delete Selected",
                      onPressed: () => _confirmDeleteSelected(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : AppBar(
                  title: const Text('My Missions'), 
                  centerTitle: true,
                  actions: [
                    if (goals.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreVertical),
                        onSelected: (value) {
                          if (value == 'delete_all') {
                            _confirmDeleteAll(context, goals.map((g) => g.id).toList());
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                SizedBox(width: 10),
                                Text('Delete All', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
          body: goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.rocket,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No missions found",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final isActive = store.activeGoal?.id == goal.id;
                    final isSelected = _selectedGoalIds.contains(goal.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(goal.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedGoalIds.add(goal.id);
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.08,
                                  )
                                : (isActive
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.04,
                                      )
                                    : theme.cardTheme.color),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected || isActive
                                  ? theme.colorScheme.primary
                                  : (theme.brightness == Brightness.dark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              width: isSelected || isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                width: _isSelectionMode ? 44.0 : 0.0,
                                clipBehavior: Clip.hardEdge,
                                decoration: const BoxDecoration(),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Container(
                                    width: 44,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                      width: 24,
                                      height: 24,
                                      child: isSelected
                                          ? const Icon(
                                              LucideIcons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            goal.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isActive
                                                      ? theme.colorScheme.primary
                                                      : null,
                                                ),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius: BorderRadius.circular(
                                                6,
                                              ),
                                            ),
                                            child: const Text(
                                              "ACTIVE",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      goal.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMeta(
                                          context,
                                          LucideIcons.calendar,
                                          "${goal.durationDays}d",
                                        ),
                                        _buildMeta(
                                          context,
                                          LucideIcons.target,
                                          goal.status.toUpperCase(),
                                        ),
                                        _buildMeta(
                                          context,
                                          LucideIcons.layers,
                                          "${goal.milestones.length} Phases",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.1),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMeta(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
