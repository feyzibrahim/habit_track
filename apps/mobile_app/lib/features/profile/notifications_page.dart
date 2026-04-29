import 'package:flutter/material.dart';
import 'package:ezucute/core/api/api_service.dart';
import 'package:ezucute/data/app_data_store.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userData = AppDataStore().userData;
    final settings = userData?['settings'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(context, "MISSION ALERTS"),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            "Daily Reminders",
            "Be notified about your habits and tasks for the day.",
            settings['notifications'] ?? true,
            (val) => _updateSetting('notifications', val),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            context,
            "Milestone Celebrations",
            "Get a notification when you complete a phase or a mission.",
            settings['milestoneAlerts'] ?? true,
            (val) => _updateSetting('milestoneAlerts', val),
          ),
          const SizedBox(height: 48),
          _buildSectionHeader(context, "AI COACH"),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            "Strategy Suggestions",
            "Receive insights from the AI about your habit patterns.",
            settings['aiInsights'] ?? true,
            (val) => _updateSetting('aiInsights', val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        value: value,
        onChanged: _isLoading ? null : onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final userData = AppDataStore().userData;
    final settings = Map<String, dynamic>.from(userData?['settings'] ?? {});
    settings[key] = value;
    setState(() => _isLoading = true);
    try {
      await ApiService.updateProfile({'settings': settings});
      await AppDataStore().fetchProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
