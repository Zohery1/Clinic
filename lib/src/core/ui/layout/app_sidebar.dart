import 'package:flutter/material.dart';

import '../../../features/auth/domain/user_model.dart';
import '../primitives/app_avatar.dart';
import '../primitives/app_logo.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

class _NavItemSpec {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemSpec({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavGroupSpec {
  final String? label;
  final List<_NavItemSpec> items;

  const _NavGroupSpec({this.label, required this.items});
}

/// Grouped clinical navigation.
///
/// Expanded (>=840) shows the full lockup and section labels. Medium widths
/// collapse to an icon rail so the clinical content keeps the room.
class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool expanded;
  final UserModel user;
  final String? clinicName;
  final int unreadCount;
  final ValueChanged<bool>? onThemeToggle;
  final bool isDark;
  final VoidCallback? onUserTap;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.user,
    this.expanded = true,
    this.clinicName,
    this.unreadCount = 0,
    this.onThemeToggle,
    this.isDark = false,
    this.onUserTap,
  });

  static const double expandedWidth = 264;
  static const double compactWidth = 236;
  static const double railWidth = 76;

  List<_NavGroupSpec> _groups() {
    return <_NavGroupSpec>[
      const _NavGroupSpec(
        items: <_NavItemSpec>[
          _NavItemSpec(
            route: '/home',
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'الرئيسية',
          ),
          _NavItemSpec(
            route: '/appointments',
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note_rounded,
            label: 'المواعيد',
          ),
        ],
      ),
      const _NavGroupSpec(
        label: 'السجلات',
        items: <_NavItemSpec>[
          _NavItemSpec(
            route: '/patients',
            icon: Icons.folder_shared_outlined,
            activeIcon: Icons.folder_shared_rounded,
            label: 'المرضى',
          ),
        ],
      ),
      _NavGroupSpec(
        label: 'الإدارة',
        items: <_NavItemSpec>[
          if (user.isOwner)
            const _NavItemSpec(
              route: '/reports',
              icon: Icons.query_stats_outlined,
              activeIcon: Icons.query_stats_rounded,
              label: 'التقارير',
            ),
          const _NavItemSpec(
            route: '/settings',
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune_rounded,
            label: 'الإعدادات',
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final width = expanded ? expandedWidth : railWidth;
    final bg = AppColors.surface(context);
    final borderColor = AppColors.borderSubtle(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              expanded: expanded,
              clinicName: clinicName,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: expanded ? AppSpace.md : AppSpace.sm,
                  vertical: AppSpace.sm,
                ),
                children: [
                  for (var g = 0; g < groups.length; g++) ...[
                    if (g > 0)
                      _GroupBreak(
                        label: groups[g].label,
                        expanded: expanded,
                      ),
                    for (final item in groups[g].items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _SidebarTile(
                          spec: item,
                          active: currentRoute == item.route,
                          expanded: expanded,
                          badge: item.route == '/home' && unreadCount > 0
                              ? unreadCount
                              : null,
                          onTap: () => onNavigate(item.route),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            _SidebarFooter(
              user: user,
              expanded: expanded,
              onUserTap: onUserTap,
              onThemeToggle: onThemeToggle,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool expanded;
  final String? clinicName;

  const _SidebarHeader({required this.expanded, this.clinicName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        expanded ? AppSpace.lg : 0,
        AppSpace.lg,
        expanded ? AppSpace.md : 0,
        AppSpace.md,
      ),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(
                  size: 38,
                  showWordmark: true,
                  title: 'عيادتي',
                  subtitle: 'نظام إدارة العيادة',
                ),
                if (clinicName != null && clinicName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: AppColors.borderSubtle(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 14,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            clinicName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )
          : const Center(child: AppLogo(size: 34)),
    );
  }
}

class _GroupBreak extends StatelessWidget {
  final String? label;
  final bool expanded;

  const _GroupBreak({required this.expanded, this.label});

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.md,
        ),
        child: Container(
          height: 1,
          color: AppColors.borderSubtle(context),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Text(
        (label ?? '').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textMuted(context),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItemSpec spec;
  final bool active;
  final bool expanded;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.spec,
    required this.active,
    required this.expanded,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = AppColors.accent(context);
    final inactiveFg = AppColors.textSecondary(context);

    final content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      height: 42,
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? AppSpace.md : 0,
      ),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: isDark ? 0.18 : 0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (expanded)
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 3,
              height: active ? 18 : 0,
              margin: const EdgeInsets.only(left: AppSpace.sm),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          Icon(
            active ? spec.activeIcon : spec.icon,
            size: 19,
            color: active ? accent : inactiveFg,
          ),
          if (expanded) ...[
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? accent : inactiveFg,
                  height: 1.2,
                ),
              ),
            ),
            if (badge != null)
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onAccent(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    final tappable = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        hoverColor: accent.withValues(alpha: isDark ? 0.10 : 0.05),
        child: content,
      ),
    );

    return expanded
        ? tappable
        : Tooltip(
            message: spec.label,
            waitDuration: const Duration(milliseconds: 400),
            child: tappable,
          );
  }
}

class _SidebarFooter extends StatelessWidget {
  final UserModel user;
  final bool expanded;
  final VoidCallback? onUserTap;
  final ValueChanged<bool>? onThemeToggle;
  final bool isDark;

  const _SidebarFooter({
    required this.user,
    required this.expanded,
    this.onUserTap,
    this.onThemeToggle,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderSubtle(context);
    final role = user.isOwner ? 'مدير العيادة' : 'فريق العيادة';

    if (!expanded) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: border)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onUserTap,
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: AppAvatar(name: user.fullName, size: AppAvatarSize.sm),
            ),
            const SizedBox(height: AppSpace.sm),
            if (onThemeToggle != null)
              IconButton(
                onPressed: () => onThemeToggle!(!isDark),
                iconSize: 17,
                visualDensity: VisualDensity.compact,
                tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: AppColors.textMuted(context),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onUserTap,
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: AppAvatar(name: user.fullName, size: AppAvatarSize.sm),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: InkWell(
              onTap: onUserTap,
              borderRadius: BorderRadius.circular(AppRadii.radiusXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName.isEmpty ? 'المستخدم' : user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                      height: 1.25,
                    ),
                  ),
                  Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onThemeToggle != null)
            IconButton(
              onPressed: () => onThemeToggle!(!isDark),
              iconSize: 17,
              visualDensity: VisualDensity.compact,
              tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: AppColors.textMuted(context),
              ),
            ),
        ],
      ),
    );
  }
}
