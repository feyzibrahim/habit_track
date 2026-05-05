import 'package:flutter/material.dart';
import 'package:ezecute/core/api/api_service.dart';
import 'package:ezecute/data/app_data_store.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = AppDataStore().userData;
    final settings = userData?['settings'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(context, "DATA & VISIBILITY"),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            "Incognito Mode",
            "Keep your missions private from the community.",
            settings['privacyMode'] ?? false,
            (val) => _updateSetting('privacyMode', val),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            context,
            "Share Progress",
            "Allow AI Coach to see your habit history for better insights.",
            settings['shareData'] ?? true,
            (val) => _updateSetting('shareData', val),
          ),
          const SizedBox(height: 48),
          _buildSectionHeader(context, "SECURITY"),
          const SizedBox(height: 16),
          ListTile(
            title: const Text("Export My Data"),
            subtitle: const Text("Download a JSON copy of all your missions."),
            trailing: const Icon(Icons.download, size: 20),
            onTap: () {},
          ),
          ListTile(
            title: Text(
              "Delete Account",
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text("Permanently erase all your data."),
            onTap: () {},
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
        activeThumbColor: theme.colorScheme.primary,
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
