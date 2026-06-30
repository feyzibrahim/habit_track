import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:execut/core/api/api_service.dart';
import 'package:execut/core/theme/app_colors.dart';
import 'package:execut/data/app_data_store.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:execut/features/auth/auth_page.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final Map<String, List<dynamic>> _tabData = {
    'friends': [],
    'global': [],
    'alltime': [],
  };
  final Map<String, bool> _tabLoading = {
    'friends': true,
    'global': false,
    'alltime': false,
  };
  final Map<String, bool> _tabLoaded = {
    'friends': false,
    'global': false,
    'alltime': false,
  };
  final Map<String, int> _tabPages = {
    'friends': 1,
    'global': 1,
    'alltime': 1,
  };
  final Map<String, bool> _tabHasMore = {
    'friends': true,
    'global': true,
    'alltime': true,
  };
  final Map<String, bool> _tabLoadingMore = {
    'friends': false,
    'global': false,
    'alltime': false,
  };
  String _selectedTab = 'friends';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTab('friends');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore(_selectedTab);
    }
  }

  List<dynamic> _filterEntries(List<dynamic> entries) {
    return entries
        .where((u) => u['isGuest'] != true && u['email'] != null)
        .toList();
  }

  Future<void> _fetchTab(String tab, {bool force = false}) async {
    if (ApiService.isGuest) {
      if (mounted) {
        setState(() {
          _tabLoading[tab] = false;
        });
      }
      return;
    }
    if (_tabLoaded[tab] == true && !force) return;

    setState(() {
      _tabLoading[tab] = true;
      _tabPages[tab] = 1;
      _tabHasMore[tab] = true;
    });
    try {
      final data = await ApiService.getLeaderboard(type: tab, page: 1, limit: 20);
      final filtered = _filterEntries(data);
      if (mounted) {
        setState(() {
          _tabData[tab] = filtered;
          _tabLoading[tab] = false;
          _tabLoaded[tab] = true;
          if (filtered.length < 20) {
            _tabHasMore[tab] = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tabLoading[tab] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch leaderboard: $e')),
        );
      }
    }
  }

  Future<void> _loadMore(String tab) async {
    if (ApiService.isGuest || _tabLoadingMore[tab] == true || _tabHasMore[tab] == false) return;

    setState(() => _tabLoadingMore[tab] = true);
    final nextPage = (_tabPages[tab] ?? 1) + 1;
    try {
      final data = await ApiService.getLeaderboard(type: tab, page: nextPage, limit: 20);
      final filtered = _filterEntries(data);
      if (mounted) {
        setState(() {
          _tabData[tab]!.addAll(filtered);
          _tabPages[tab] = nextPage;
          _tabLoadingMore[tab] = false;
          if (filtered.length < 20) {
            _tabHasMore[tab] = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tabLoadingMore[tab] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more leaderboard items: $e')),
        );
      }
    }
  }

  void _onTabSelected(String tab) {
    setState(() => _selectedTab = tab);
    if (_tabLoaded[tab] != true && _tabLoading[tab] != true) {
      _fetchTab(tab);
    }
  }

  List<dynamic> get _activeList => _tabData[_selectedTab] ?? [];

  bool get _isCurrentTabLoading => _tabLoading[_selectedTab] == true;

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Leaderboard',
        style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCcw, size: 18),
          onPressed: _isCurrentTabLoading
              ? null
              : () => _fetchTab(_selectedTab, force: true),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({
    required ThemeData theme,
    required bool isDark,
    double? width,
    double height = 16,
    double radius = 8,
  }) {
    final baseColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.35)
        : const Color(0xFFE2E8F0);
    final shimmerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.7);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: shimmerColor);
  }

  Widget _buildSkeletonLoading(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Compete on consistency, not just outcome',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.2)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonBox(theme: theme, isDark: isDark, width: 140, height: 20),
                const SizedBox(height: 10),
                _buildSkeletonBox(theme: theme, isDark: isDark, width: 180, height: 12),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 72, height: 40, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(theme: theme, isDark: isDark, width: 120, height: 10),
                          const SizedBox(height: 8),
                          _buildSkeletonBox(theme: theme, isDark: isDark, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTabs(theme),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 44, height: 44, radius: 22),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 48, height: 10),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 55.w, height: 40.h, radius: 6),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 56, height: 56, radius: 28),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 52, height: 10),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 55.w, height: 60.h, radius: 6),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 40, height: 40, radius: 20),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 44, height: 10),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(theme: theme, isDark: isDark, width: 55.w, height: 28.h, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(
            5,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  _buildSkeletonBox(theme: theme, isDark: isDark, width: 20, height: 14),
                  const SizedBox(width: 12),
                  _buildSkeletonBox(theme: theme, isDark: isDark, width: 36, height: 36, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(theme: theme, isDark: isDark, width: 120, height: 12),
                        const SizedBox(height: 8),
                        _buildSkeletonBox(theme: theme, isDark: isDark, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSkeletonBox(theme: theme, isDark: isDark, width: 48, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showFriendDetails(
    BuildContext context,
    dynamic user,
    Color rankColor,
    String displayName,
  ) {
    final theme = Theme.of(context);
    final activeMissions = (user['activeMissions'] as List<dynamic>?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: rankColor, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.surface,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.star, color: rankColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Level ${(user['score'] ~/ 100) + 1} • ${user['score']} XP",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ACTIVE MISSIONS",
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (activeMissions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    "No active missions right now.",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activeMissions.length,
                                itemBuilder: (context, idx) {
                                  final mission = activeMissions[idx];
                                  final progress =
                                      (mission['progress'] as num?)?.toDouble() ??
                                      0.0;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                mission['title'] ??
                                                    'Unknown Mission',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (mission['durationDays'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "${mission['durationDays']}d",
                                                  style: TextStyle(
                                                    color:
                                                        theme.colorScheme.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(
                                                  4,
                                                ),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 8,
                                                  backgroundColor: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.1),
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                        theme.colorScheme.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "${(progress * 100).toInt()}%",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
      },
    );
  }

  Widget _buildGuestState(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.lock,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              "Account Required",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              "You need to register to see the leaderboard and invite friends.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 400.ms),
            const SizedBox(height: 40),
            ElevatedButton(
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
                      initialIsLogin: false,
                      disableToggle: true,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchTab('friends', force: true);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Create Account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ).animate().fade(delay: 600.ms).scaleY(begin: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(List<dynamic> currentList, int yourIndex, ThemeData theme, bool isDark) {
    final rankText = yourIndex != -1 ? "#${yourIndex + 1}" : "#--";

    final title = switch (_selectedTab) {
      'friends' => 'Friends Rankings',
      'alltime' => 'All Time Rankings',
      _ => 'Global Rankings',
    };
    final subtitle = switch (_selectedTab) {
      'friends' => 'This week among your friends',
      'alltime' => 'Total XP earned',
      _ => 'This week globally — updated daily',
    };
    final rankLabel = switch (_selectedTab) {
      'friends' => 'YOUR RANK AMONG FRIENDS',
      'alltime' => 'YOUR ALL-TIME RANK',
      _ => 'YOUR RANK THIS WEEK',
    };
    
    String behindText = "";
    if (currentList.isNotEmpty && yourIndex > 0) {
      final topScore = currentList[0]['score'] as int;
      final yourScore = currentList[yourIndex]['score'] as int;
      final diff = topScore - yourScore;
      behindText = "$diff XP behind #1 · You can close this today";
    } else if (yourIndex == 0) {
      behindText = "You are in the lead! Keep it up!";
    } else {
      behindText = "Compete to earn XP and rank up!";
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1A13), Color(0xFF0A1A10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                rankText,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rankLabel,
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 10.sp,
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      behindText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    Widget tabItem(String label, String value) {
      final isActive = _selectedTab == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => _onTabSelected(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? theme.colorScheme.primary : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? theme.colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'DM Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          tabItem('Friends', 'friends'),
          const SizedBox(width: 6),
          tabItem('Global', 'global'),
          const SizedBox(width: 6),
          tabItem('All Time', 'alltime'),
        ],
      ),
    );
  }

  Widget _buildPodium(List<dynamic> users, bool isDark, ThemeData theme) {
    if (users.length < 3) return const SizedBox();

    final first = users[0];
    final second = users[1];
    final third = users[2];

    Widget podiumColumn(dynamic user, int place, String medal, double barHeight, Color badgeColor, Color barColor, double avatarSize, double fontSize) {
      final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
      final displayName = name.isNotEmpty ? name : (user['email']?.toString() ?? 'Unknown');
      final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
      final xp = user['score'];
      final isYou = user['isYou'] == true || user['email'] == AppDataStore().userData?['email'];
      final rankColor = place == 1
          ? const Color(0xFFFFD700)
          : place == 2
              ? const Color(0xFFC0C0C0)
              : const Color(0xFFCD7F32);

      return Expanded(
        child: GestureDetector(
          onTap: () => _showFriendDetails(
            context,
            user,
            rankColor,
            isYou ? "You" : displayName,
          ),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(medal, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badgeColor,
                    width: 2,
                  ),
                  gradient: place == 1
                      ? const LinearGradient(
                          colors: [Color(0xFF1D9E75), Color(0xFF0A5A3F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: place != 1 ? (isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)) : null,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isYou ? "You" : displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                "$xp XP",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'DM Mono',
                  fontSize: 10,
                  color: place == 1
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: barHeight.h,
                width: 55.w,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          podiumColumn(
            second,
            2,
            '🥈',
            40.0,
            const Color(0xFFC0C0C0),
            isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            44.r,
            16.sp,
          ),
          podiumColumn(
            first,
            1,
            '🥇',
            60.0,
            const Color(0xFFFFD700),
            theme.colorScheme.primary.withValues(alpha: 0.1),
            56.r,
            20.sp,
          ),
          podiumColumn(
            third,
            3,
            '🥉',
            28.0,
            const Color(0xFFCD7F32),
            isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            40.r,
            14.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(dynamic user, int index, bool isDark, ThemeData theme) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final displayName = name.isNotEmpty ? name : (user['email']?.toString() ?? 'Unknown');
    final isYou = user['isYou'] == true || user['email'] == AppDataStore().userData?['email'];
    
    final rankText = "${index + 1}";
    final streak = user['streak'] ?? ((user['score'] as int) ~/ 200 + 3);
    final activeCount = user['activeMissions']?.length ?? 1;

    final rankColor = index == 0
        ? const Color(0xFFFFD700)
        : index == 1
            ? const Color(0xFFC0C0C0)
            : index == 2
                ? const Color(0xFFCD7F32)
                : (isDark ? Colors.white30 : Colors.black38);

    return GestureDetector(
      onTap: () => _showFriendDetails(
        context,
        user,
        index < 3 ? rankColor : theme.colorScheme.primary,
        isYou ? "You" : displayName,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isYou
              ? (isDark ? AppColors.greenDim : const Color(0xFFE8F5E9))
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isYou
                ? AppColors.greenMid
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: Text(
                  rankText,
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isYou ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isYou ? theme.colorScheme.primary : (isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
                border: Border.all(
                  color: isYou ? theme.colorScheme.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isYou ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isYou ? "You" : displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isYou ? theme.colorScheme.primary : (isDark ? Colors.white : Colors.black87),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isYou) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "YOU",
                            style: TextStyle(
                              fontFamily: 'DM Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$streak day streak · $activeCount goals active",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${user['score']} XP",
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "🔥 $streak",
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 10,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(int yourRank, dynamic user) {
    if (user == null) return const SizedBox();
    final rankSuffix = yourRank != -1 ? "globally this week" : "";
    final rankNum = yourRank != -1 ? " — #${yourRank + 1} " : " ";
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: OutlinedButton.icon(
        onPressed: () => _showShareModal(user, yourRank),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
          backgroundColor: Theme.of(context).cardTheme.color,
        ),
        icon: Icon(
          LucideIcons.share2,
          size: 14,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
        ),
        label: Text(
          "Share my rank$rankNum$rankSuffix",
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildShareCardPreview(GlobalKey boundaryKey, dynamic user, int index, bool isDark, ThemeData theme) {
    final name = "${user['firstName'] ?? ''} ${user['lastName'] ?? ''}".trim();
    final displayName = name.isNotEmpty ? name : (user['email']?.toString() ?? 'You');
    final streak = user['streak'] ?? ((user['score'] as int) ~/ 200 + 3);
    final score = user['score'];
    final rankText = "#${index + 1}";

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 300.w,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1A13), Color(0xFF050B08), Color(0xFF080808)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFF1D9E75),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.award, color: const Color(0xFF1D9E75), size: 16.sp),
                const SizedBox(width: 6),
                const Text(
                  'MISSION CONTROL',
                  style: TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFF1D9E75),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 70.r,
              height: 70.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1D9E75),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    fontSize: 26.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rankText,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1D9E75),
                height: 1.1,
              ),
            ),
            const Text(
              'WEEKLY RANK',
              style: TextStyle(
                fontFamily: 'DM Mono',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 0.5,
              color: Colors.white12,
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "$score",
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "TOTAL XP",
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 8,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "🔥 $streak",
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "STREAK",
                      style: TextStyle(
                        fontFamily: 'DM Mono',
                        fontSize: 8,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '"Compete on consistency, not just outcome"',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareModal(dynamic user, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shareKey = GlobalKey();

    final rankText = "#${index + 1}";
    final textToShare = "I am ranked $rankText this week on Mission Control! Track your consistency and compete with me.";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface2 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Share Your Rank',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preview your rank card below',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _buildShareCardPreview(shareKey, user, index, isDark, theme),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: textToShare));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message copied to clipboard!')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.clipboard, size: 16),
                      label: const Text('Copy Text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _shareWidgetAsImage(shareKey, textToShare);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.share, size: 16, color: Colors.white),
                      label: const Text(
                        'Share Image',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareWidgetAsImage(GlobalKey boundaryKey, String text) async {
    try {
      if (boundaryKey.currentContext == null) return;
      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/share_rank.png').create();
        await file.writeAsBytes(pngBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
        );
      }
    } catch (e) {
      debugPrint("Error sharing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate rank card image: $e')),
        );
      }
    }
  }

  Widget _buildEmptyFriendsState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '👥',
            style: TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'No friends added yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite friends to compete on consistency. Social pressure is your best retention tool.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showInviteFriendDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Invite a friend',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteFriendDialog() {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: const Text(
            'Invite Friend',
            style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your friend\'s email address to send a request.',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Friend\'s Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                try {
                  await ApiService.sendFriendRequest(email);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request sent!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send request: $e')),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (ApiService.isGuest) {
      return Scaffold(
        appBar: _buildAppBar(theme),
        body: _buildGuestState(context, theme, isDark),
      );
    }

    final activeList = _activeList;
    final myEmail = AppDataStore().userData?['email'];
    final myIndex = activeList.indexWhere((u) => u['email'] == myEmail);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: _isCurrentTabLoading
          ? _buildSkeletonLoading(theme, isDark)
          : RefreshIndicator(
              onRefresh: () => _fetchTab(_selectedTab, force: true),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compete on consistency, not just outcome',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeroCard(activeList, myIndex, theme, isDark),
                    _buildTabs(theme),
                    if (_selectedTab == 'friends' && activeList.isEmpty)
                      _buildEmptyFriendsState(theme, isDark)
                    else ...[
                      if (activeList.length >= 3)
                        _buildPodium(activeList, isDark, theme),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          return _buildLeaderboardRow(activeList[index], index, isDark, theme);
                        },
                      ),
                      if (_tabLoadingMore[_selectedTab] == true)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      _buildShareButton(myIndex, myIndex != -1 ? activeList[myIndex] : null),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
