import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/domain/user_model.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';
import 'app_scaffold.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

/// Responsive shell. >=900px uses sidebar + top bar; <900px uses
/// top bar + bottom nav (sidebar is reserved for a later drawer phase).
class AppShell extends StatelessWidget {
  static const double kDesktopBreakpoint = 900;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

        final topBar = AppTopBar(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: actions,
          unreadCount: unreadCount,
          onNotificationsTap: onNotificationsTap,
          onUserTap: onUserTap,
          onSearchTap: onSearchTap,
          userName: user.fullName,
          compact: !isDesktop,
        );

        if (isDesktop) {
          return AppScaffold(
            sidebar: AppSidebar(
              currentRoute: currentRoute,
              onNavigate: onNavigate,
              user: user,
              clinicName: clinicName,
              unreadCount: unreadCount,
              expanded: true,
              onThemeToggle: onThemeToggle,
              isDark: isDark,
              onUserTap: onUserTap,
            ),
            topBar: topBar,
            body: child,
            padding: const EdgeInsets.all(AppSpace.xxl),
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
          padding: const EdgeInsets.all(AppSpace.lg),
        );
      },
    );
  }
}

/// Modern pill-style bottom nav (mobile only). Up to 5 items.
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
    final base = <_BottomItem>[
      const _BottomItem(
        route: '/home',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'الرئيسية',
      ),
      const _BottomItem(
        route: '/appointments',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: 'المواعيد',
      ),
      const _BottomItem(
        route: '/patients',
        icon: Icons.people_alt_outlined,
        activeIcon: Icons.people_alt_rounded,
        label: 'المرضى',
      ),
      if (user.isOwner)
        const _BottomItem(
          route: '/reports',
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights_rounded,
          label: 'التقارير',
        ),
      const _BottomItem(
        route: '/settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'الإعدادات',
      ),
    ];
    return base.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final isDark = AppColors.isDark(context);
    final bg = AppColors.surface(context);
    final border = AppColors.borderSubtle(context);

    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            Expanded(
              child: _BottomTile(
                item: item,
                active: currentRoute == item.route,
                isDark: isDark,
                onTap: () => onNavigate(item.route),
              ),
            ),
        ],
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
  final bool isDark;
  final VoidCallback onTap;

  const _BottomTile({
    required this.item,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.primary : AppColors.textSecondary(context);
    final pillBg = AppColors.primary.withValues(
      alpha: isDark ? 0.20 : 0.12,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: active ? pillBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.radiusMd),
            border: active
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size: 22,
                color: fg,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

