import 'package:ezucute/core/api/api_service.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userData = AppDataStore().userData;
    final settings = userData?['settings'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(context, "ACCOUNT DETAILS"),
          const SizedBox(height: 16),
          _buildTextField(context, "First Name", userData?['firstName'] ?? ""),
          const SizedBox(height: 16),
          _buildTextField(context, "Last Name", userData?['lastName'] ?? ""),
          const SizedBox(height: 32),
          _buildSectionHeader(context, "APP PREFERENCES"),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            "Dark Theme",
            settings['theme'] == 'dark',
            (val) => _updateSetting('theme', val ? 'dark' : 'light'),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            context,
            "Haptic Feedback",
            settings['haptics'] ?? true,
            (val) => _updateSetting('haptics', val),
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

  Widget _buildTextField(
    BuildContext context,
    String label,
    String initialValue,
  ) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      onFieldSubmitted: (val) {
        final field = label.toLowerCase().replaceAll(" ", "");
        _updateProfile({field: val});
      },
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
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
    await _updateProfile({'settings': settings});
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.updateProfile(data);
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
