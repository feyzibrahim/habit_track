import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ezucute/features/auth/auth_page.dart';
import 'package:ezucute/core/api/api_service.dart';

import 'package:ezucute/features/profile/missions_page.dart';
import 'package:ezucute/features/profile/settings_page.dart';
import 'package:ezucute/features/profile/privacy_page.dart';
import 'package:ezucute/features/profile/notifications_page.dart';
import 'package:ezucute/features/friends/friends_page.dart';
import 'package:ezucute/features/friends/leaderboard_page.dart';
import 'package:ezucute/data/app_data_store.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Account'),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ListenableBuilder(
                listenable: AppDataStore(),
                builder: (context, child) {
                  final store = AppDataStore();
                  return Column(
                    children: [
                      _buildProfileHeader(context, store),
                      const SizedBox(height: 48),
                      _buildQuickStats(context, store),
                      const SizedBox(height: 48),
                      _buildMenuSection(context),
                      const SizedBox(height: 60),
                      _buildSignOutButton(context),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    final user = store.userData;
    final fullName = (user?['firstName'] != null || user?['lastName'] != null)
        ? "${user?['firstName'] ?? ""} ${user?['lastName'] ?? ""}".trim()
        : "Guardian";

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.user, size: 48, color: Colors.white),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Icon(
                LucideIcons.contact,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user?['email'] ?? 'operator@mission.control',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AppDataStore store) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          context,
          'MISSIONS',
          store.currentGoals.length.toString(),
        ),
        Container(width: 1, height: 30, color: theme.dividerColor),
        _buildStatItem(context, 'ACTIVE', store.activeGoal != null ? '1' : '0'),
        Container(width: 1, height: 30, color: theme.dividerColor),
        _buildStatItem(context, 'LEVEL', '8'),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          LucideIcons.rocket,
          'My Missions',
          subtitle: 'Switch or manage your goals',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MissionsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          LucideIcons.settings,
          'Settings',
          subtitle: 'App preferences and theme',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          LucideIcons.users,
          'Friends',
          subtitle: 'Manage your connections',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendsPage()),
          ),
        ),
        _buildMenuItem(
          context,
          LucideIcons.trophy,
          'Leaderboard',
          subtitle: 'View friends progress and XP',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardPage()),
          ),
        ),
        _buildMenuItem(
          context,
          LucideIcons.shield,
          'Privacy',
          subtitle: 'Data and security settings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPage()),
          ),
        ),
        _buildMenuItem(
          context,
          LucideIcons.bell,
          'Notifications',
          subtitle: 'Reminder and alert configurations',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            : null,
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            ApiService.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthPage()),
              (route) => false,
            );
          },
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: const Text(
            'DEACTIVATE SESSION',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
