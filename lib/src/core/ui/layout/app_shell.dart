import 'package:flutter/material.dart';

import '../../../features/auth/domain/user_model.dart';
import '../tokens/breakpoints.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'app_scaffold.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

/// Responsive clinical shell.
///
/// >=840 keeps a persistent sidebar; 600-839 collapses it to a rail; below 600
/// the navigation becomes a bottom bar. The shell owns page padding so screens
/// never double up on insets.
class AppShell extends StatelessWidget {
  static const double kDesktopBreakpoint = AppBreakpoints.medium;

  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final UserModel user;
  final String? clinicName;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<bool>? onThemeToggle;
  final bool isDark;
  final List<Widget> actions;
  final List<AppBreadcrumbItem> breadcrumbs;
  final Widget child;
  final String title;
  final String? subtitle;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.user,
    required this.child,
    required this.title,
    this.clinicName,
    this.unreadCount = 0,
    this.onNotificationsTap,
    this.onUserTap,
    this.onSearchTap,
    this.onThemeToggle,
    this.isDark = false,
    this.actions = const <Widget>[],
    this.breadcrumbs = const <AppBreadcrumbItem>[],
    this.subtitle,
  });

  EdgeInsets _padding(double width) {
    if (width >= AppBreakpoints.large) return const EdgeInsets.all(AppSpace.xxxl);
    if (width >= AppBreakpoints.expanded) {
      return const EdgeInsets.all(AppSpace.xxl + 4);
    }
    if (width >= AppBreakpoints.medium) return const EdgeInsets.all(AppSpace.xxl);
    if (width >= AppBreakpoints.compact) return const EdgeInsets.all(AppSpace.xl);
    return const EdgeInsets.all(AppSpace.lg);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= AppBreakpoints.sidebarPanel;
        final expandedSidebar = width >= AppBreakpoints.expanded;

        final topBar = AppTopBar(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
          unreadCount: unreadCount,
          onNotificationsTap: onNotificationsTap,
          onThemeToggle: onThemeToggle,
          isDark: isDark,
          compact: width < AppBreakpoints.medium,
        );

        if (showSidebar) {
          return AppScaffold(
            sidebar: AppSidebar(
              currentRoute: currentRoute,
              onNavigate: onNavigate,
              user: user,
              clinicName: clinicName,
              unreadCount: unreadCount,
              expanded: expandedSidebar,
              onThemeToggle: onThemeToggle,
              isDark: isDark,
              onUserTap: onUserTap,
            ),
            topBar: topBar,
            body: child,
            padding: _padding(width),
          );
        }

        return AppScaffold(
          topBar: topBar,
          body: child,
          bottomBar: AppBottomNav(
            currentRoute: currentRoute,
            onNavigate: onNavigate,
            user: user,
          ),
          padding: _padding(width),
        );
      },
    );
  }
}

/// Compact bottom navigation. Up to 5 destinations, no overflow labels.
class AppBottomNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final UserModel user;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.user,
  });

  List<_BottomItem> _items() {
    return <_BottomItem>[
      const _BottomItem(
        route: '/home',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'الرئيسية',
      ),
      const _BottomItem(
        route: '/appointments',
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        label: 'المواعيد',
      ),
      const _BottomItem(
        route: '/patients',
        icon: Icons.folder_shared_outlined,
        activeIcon: Icons.folder_shared_rounded,
        label: 'المرضى',
      ),
      if (user.isOwner)
        const _BottomItem(
          route: '/reports',
          icon: Icons.query_stats_outlined,
          activeIcon: Icons.query_stats_rounded,
          label: 'التقارير',
        ),
      const _BottomItem(
        route: '/settings',
        icon: Icons.tune_outlined,
        activeIcon: Icons.tune_rounded,
        label: 'الإعدادات',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: 6,
          ),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _BottomTile(
                    item: item,
                    active: currentRoute == item.route,
                    onTap: () => onNavigate(item.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _BottomItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomTile extends StatelessWidget {
  final _BottomItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = AppColors.accent(context);
    final fg = active ? accent : AppColors.textMuted(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: isDark ? 0.16 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? item.activeIcon : item.icon, size: 21, color: fg),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
