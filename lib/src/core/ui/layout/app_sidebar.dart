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
      decoration: const BoxDecoration(
        color: AppColors.obsidianShell,
        border: Border(
          left: BorderSide(
            color: AppColors.obsidianBorder,
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
                      const SizedBox(height: AppSpace.xs + 2),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.obsidianBorder),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x4038BDF8), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3338BDF8),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'عيادتي',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0x2210B981),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0x4410B981), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4.5,
                                height: 4.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'سحابي',
                                style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF34D399),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinicName ?? 'المنظومة السريرية الذكية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
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
    final active = widget.active;
    final expanded = widget.expanded;

    final bg = active
        ? const Color(0x2238BDF8)
        : (_hovered ? const Color(0xFF141F33) : Colors.transparent);

    final borderColor = active
        ? const Color(0x6638BDF8)
        : (_hovered ? const Color(0xFF1E2E4A) : Colors.transparent);

    final iconColor = active
        ? const Color(0xFF38BDF8)
        : (_hovered ? Colors.white : const Color(0xFF8899AC));

    final textColor = active
        ? Colors.white
        : (_hovered ? Colors.white : const Color(0xFF94A3B8));

    final icon = Icon(widget.spec.icon, size: 20, color: iconColor);

    final inner = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.md,
        end: AppSpace.sm,
        top: AppSpace.sm + 2,
        bottom: AppSpace.sm + 2,
      ),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          if (active)
            PositionedDirectional(
              start: -AppSpace.md + 1,
              top: 5,
              bottom: 5,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x9938BDF8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
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
                          active ? FontWeight.w800 : FontWeight.w600,
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
        borderRadius: BorderRadius.circular(9),
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
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
        border: Border.all(color: const Color(0x6638BDF8), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1626),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2E4A), width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        user.isOwner ? 'مالك المركز · $roleLabel' : roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



