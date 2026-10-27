import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../primitives/app_avatar.dart';
import '../primitives/app_icon_button.dart';
import '../primitives/app_tooltip.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

class AppBreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  const AppBreadcrumbItem({required this.label, this.onTap});
}

class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<AppBreadcrumbItem> breadcrumbs;
  final List<Widget> actions;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onSearchTap;
  final String? userName;
  final bool compact;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const <AppBreadcrumbItem>[],
    this.actions = const <Widget>[],
    this.unreadCount = 0,
    this.onNotificationsTap,
    this.onUserTap,
    this.onSearchTap,
    this.userName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? AppColors.obsidianShell : AppColors.surface(context);
    final borderColor = isDark ? AppColors.obsidianBorder : AppColors.borderSubtle(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpace.lg : AppSpace.xxl,
            vertical: AppSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (breadcrumbs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _Breadcrumbs(items: breadcrumbs),
                      ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!compact && onSearchTap != null) ...[
                const SizedBox(width: AppSpace.md),
                Flexible(
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
                    child: _GlobalSearchTrigger(onTap: onSearchTap!),
                  ),
                ),
              ],
              const SizedBox(width: AppSpace.md),
              if (!compact) ...[
                const _OperationalStatusBadge(),
                const SizedBox(width: AppSpace.sm),
              ],
              if (compact && onSearchTap != null) ...[
                AppIconButton(
                  icon: Icons.search_rounded,
                  tooltip: 'بحث',
                  onPressed: onSearchTap,
                ),
                const SizedBox(width: AppSpace.xs),
              ],
              if (actions.isNotEmpty) ...[
                for (final w in actions) ...[
                  w,
                  const SizedBox(width: AppSpace.sm),
                ],
              ],
              _NotificationsButton(
                count: unreadCount,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: AppSpace.sm),
              _UserMenuButton(
                userName: userName,
                onTap: onUserTap,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchTrigger extends StatefulWidget {
  final VoidCallback onTap;
  const _GlobalSearchTrigger({required this.onTap});

  @override
  State<_GlobalSearchTrigger> createState() => _GlobalSearchTriggerState();
}

class _GlobalSearchTriggerState extends State<_GlobalSearchTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final borderColor = _hovered
        ? (isDark ? AppColors.obsidianActiveGlow : AppColors.primary)
        : (isDark ? AppColors.obsidianBorder : AppColors.borderSubtle(context));
    final bg = isDark
        ? (_hovered ? AppColors.obsidianCardHover : AppColors.obsidianCard)
        : (_hovered
            ? AppColors.subtle(context)
            : AppColors.subtle(context).withValues(alpha: 0.6));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 140, maxWidth: 280, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: _hovered && isDark
                ? [
                    BoxShadow(
                      color: AppColors.obsidianActiveGlow.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 16,
                color: _hovered
                    ? (isDark ? AppColors.obsidianActiveGlow : AppColors.primary)
                    : (isDark ? AppColors.obsidianTextSecondary : AppColors.textMuted(context)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'بحث عن مريض أو موعد...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.obsidianTextSecondary : AppColors.textMuted(context),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.obsidianBorder : AppColors.borderSubtle(context),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Ctrl+K',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.obsidianActiveGlow : AppColors.textSecondary(context),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationalStatusBadge extends StatelessWidget {
  const _OperationalStatusBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showLabel = screenWidth >= 1150;

    return Tooltip(
      message: 'نظام العيادة متصل • سحابي متزامن',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 8 : 7, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0E1626)
              : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2E4A)
                : AppColors.success.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                'نظام العيادة متصل',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.obsidianTextPrimary : AppColors.success,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'سحابي',
                  style: GoogleFonts.cairo(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.accentCyan : AppColors.primary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  final List<AppBreadcrumbItem> items;
  const _Breadcrumbs({required this.items});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;
      children.add(
        Flexible(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isLast
                        ? AppColors.textSecondary(context)
                        : AppColors.textMuted(context),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      if (!isLast) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 14,
              color: AppColors.textMuted(context),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _NotificationsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final btn = Stack(
      clipBehavior: Clip.none,
      children: [
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          size: AppIconButtonSize.md,
          tooltip: 'الإشعارات',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius:
                    BorderRadius.circular(AppRadii.radiusFull),
                border: Border.all(
                  color: AppColors.surface(context),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: GoogleFonts.cairo(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onPrimary,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
    return AppTooltip(
      message: 'الإشعارات',
      waitDuration: Duration.zero,
      child: btn,
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  final String? userName;
  final VoidCallback? onTap;
  final bool compact;

  const _UserMenuButton({
    required this.userName,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasName = userName != null && userName!.trim().isNotEmpty;

    if (!compact && hasName) {
      return AppTooltip(
        message: 'الملف الشخصي وإعدادات الحساب',
        waitDuration: Duration.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.obsidianCard : AppColors.subtle(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.obsidianBorder : AppColors.borderSubtle(context),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAvatar(name: userName, size: AppAvatarSize.sm),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                          height: 1.2,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'طبيب متصل',
                            style: GoogleFonts.cairo(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppTooltip(
      message: userName ?? 'الحساب',
      waitDuration: Duration.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadii.brFull,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.easeOutCubic,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.obsidianBorder : AppColors.borderSubtle(context),
                width: 1,
              ),
            ),
            child: AppAvatar(name: userName, size: AppAvatarSize.sm),
          ),
        ),
      ),
    );
  }
}



