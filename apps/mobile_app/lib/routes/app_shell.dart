import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ezecute/core/theme/app_colors.dart';
import 'package:ezecute/features/profile/profile_page.dart';
import 'package:ezecute/features/home/home_page.dart';
import 'package:ezecute/features/chat/chat_page.dart';
import 'package:ezecute/features/planning/arena_page.dart';
import 'package:ezecute/features/planning/planning_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavItem {
  final IconData icon;
  final String label;
  final Widget page;

  const NavItem({required this.icon, required this.label, required this.page});
}

class MainNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const MainNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isPlan = i == 2;
              if (isPlan) {
                return _PlanButton(onTap: () => onTap(i));
              }
              return _NavBarItem(
                item: items[i],
                isSelected: i == selectedIndex,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Transform.translate(
        offset: Offset(0, -12.h),
        child: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              width: 3.w,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(LucideIcons.plus, color: Colors.white, size: 24.sp),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  item.icon,
                  size: 19.sp,
                  color: isSelected ? activeColor : inactiveColor,
                )
                .animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                ),
            SizedBox(height: 4.h),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 9.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    state?._onNavTap(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<NavItem> _navItems;

  int get _stackIndex {
    if (_currentIndex == 0) return 0;
    if (_currentIndex == 1) return 1;
    if (_currentIndex == 3) return 2;
    if (_currentIndex == 4) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _navItems = const [
      NavItem(
        icon: LucideIcons.layoutGrid,
        label: 'Dashboard',
        page: HomePage(),
      ),
      NavItem(icon: LucideIcons.swords, label: 'Arena', page: ArenaPage()),
      NavItem(icon: LucideIcons.plus, label: 'Plan', page: PlanningPage()),
      NavItem(
        icon: LucideIcons.circleDot,
        label: 'Coach',
        page: AiCoachPage(),
      ),
      NavItem(
        icon: LucideIcons.user,
        label: 'Profile',
        page: ProfilePage(),
      ),
    ];
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _showPlanningSheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showPlanningSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Expanded(child: PlanningPage()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _stackIndex,
        children: [
          _navItems[0].page,
          _navItems[1].page,
          _navItems[3].page,
          _navItems[4].page,
        ],
      ),
      bottomNavigationBar: MainNavBar(
        selectedIndex: _currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}
