import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/domain/user_model.dart';
import '../primitives/app_avatar.dart';
import '../primitives/app_icon_button.dart';
import '../primitives/app_tooltip.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

class _NavItemSpec {
  final String route;
  final IconData icon;
  final String label;
  final bool badge;

  const _NavItemSpec({
    required this.route,
    required this.icon,
    required this.label,
    this.badge = false,
  });
}

class AppSidebar extends StatefulWidget {
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

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const double _kExpandedWidth = 248;
  static const double _kCollapsedWidth = 72;

  List<_NavItemSpec> _buildItems() {
    return <_NavItemSpec>[
      const _NavItemSpec(
        route: '/home',
        icon: Icons.dashboard_outlined,
        label: 'الرئيسية',
        badge: true,
      ),
      const _NavItemSpec(
        route: '/appointments',
        icon: Icons.calendar_today_outlined,
        label: 'المواعيد',
      ),
      const _NavItemSpec(
        route: '/patients',
        icon: Icons.people_alt_outlined,
        label: 'المرضى',
      ),
      if (widget.user.isOwner)
        const _NavItemSpec(
          route: '/reports',
          icon: Icons.insights_outlined,
          label: 'التقارير',
        ),
      const _NavItemSpec(
        route: '/settings',
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final width = widget.expanded ? _kExpandedWidth : _kCollapsedWidth;

    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          left: BorderSide(
            color: AppColors.borderSubtle(context),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              expanded: widget.expanded,
              clinicName: widget.clinicName,
            ),
            const SizedBox(height: AppSpace.md),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                child: Column(
                  children: [
                    for (final item in items) ...[
                      _NavTile(
                        spec: item,
                        active: widget.currentRoute == item.route,
                        expanded: widget.expanded,
                        badgeCount: item.badge ? widget.unreadCount : 0,
                        onTap: () => widget.onNavigate(item.route),
                      ),
                      const SizedBox(height: AppSpace.xs),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SidebarFooter(
              expanded: widget.expanded,
              isDark: widget.isDark,
              onThemeToggle: widget.onThemeToggle,
              user: widget.user,
              onUserTap: widget.onUserTap,
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

  const _SidebarHeader({required this.expanded, required this.clinicName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: AnimatedSize(
        duration: AppMotion.normal,
        curve: AppMotion.easeOutCubic,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: AppRadii.brSm,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.medical_services_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عيادتي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinicName ?? 'لوحة الإدارة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItemSpec spec;
  final bool active;
  final bool expanded;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavTile({
    required this.spec,
    required this.active,
    required this.expanded,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final active = widget.active;
    final expanded = widget.expanded;

    final baseBg = active
        ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10)
        : Colors.transparent;
    final hoverBg = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final bg = active
        ? baseBg
        : (_hovered ? hoverBg.withValues(alpha: 0.7) : Colors.transparent);

    final iconColor =
        active ? AppColors.primary : AppColors.textSecondary(context);
    final textColor =
        active ? AppColors.primary : AppColors.textSecondary(context);

    final icon = Icon(widget.spec.icon, size: 20, color: iconColor);

    final inner = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm + 2,
      ),
      child: Stack(
        children: [
          if (active)
            Positioned(
              right: 0,
              top: 6,
              bottom: 6,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              icon,
              if (expanded) ...[
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    widget.spec.label,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                ),
                if (widget.badgeCount > 0)
                  _BadgePill(count: widget.badgeCount),
              ],
            ],
          ),
        ],
      ),
    );

    final tappable = Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadii.brSm,
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hovered = v),
        child: inner,
      ),
    );

    if (expanded) return tappable;
    return AppTooltip(
      message: widget.spec.label,
      waitDuration: Duration.zero,
      child: tappable,
    );
  }
}

class _BadgePill extends StatelessWidget {
  final int count;
  const _BadgePill({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.onPrimary,
          height: 1.0,
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool expanded;
  final bool isDark;
  final ValueChanged<bool>? onThemeToggle;
  final UserModel user;
  final VoidCallback? onUserTap;

  const _SidebarFooter({
    required this.expanded,
    required this.isDark,
    required this.onThemeToggle,
    required this.user,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = AppIconButton(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      size: AppIconButtonSize.sm,
      tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
      onPressed: onThemeToggle == null
          ? null
          : () => onThemeToggle!(!isDark),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expanded)
            Align(alignment: AlignmentDirectional.centerStart, child: toggle)
          else
            Center(child: toggle),
          const SizedBox(height: AppSpace.sm),
          _UserRow(
            user: user,
            expanded: expanded,
            onTap: onUserTap,
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool expanded;
  final VoidCallback? onTap;

  const _UserRow({
    required this.user,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatar(name: user.fullName, size: AppAvatarSize.sm);
    final roleLabel = user.role == UserRole.doctor ? 'طبيب' : 'سكرتير';

    if (!expanded) {
      return Center(
        child: AppTooltip(
          message: '${user.fullName} · $roleLabel',
          waitDuration: Duration.zero,
      child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.brFull,
            child: avatar,
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadii.brSm,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      user.isOwner ? 'مالك · $roleLabel' : roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: AppColors.textMuted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



