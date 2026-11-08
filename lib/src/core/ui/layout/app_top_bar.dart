import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class AppBreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  const AppBreadcrumbItem({required this.label, this.onTap});
}

/// Clinical command bar.
///
/// Breadcrumb above title, actions on the trailing edge. No decorative status
/// badges, no dead search field. Height stays at 64 so it can be hosted in a
/// standard [AppBar] without reflow.
class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<AppBreadcrumbItem> breadcrumbs;
  final List<Widget> actions;
  final int unreadCount;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<bool>? onThemeToggle;
  final bool isDark;
  final bool compact;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs = const <AppBreadcrumbItem>[],
    this.actions = const <Widget>[],
    this.unreadCount = 0,
    this.onNotificationsTap,
    this.onThemeToggle,
    this.isDark = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.surface(context);
    final line = AppColors.borderSubtle(context);
    final hasCrumbs = breadcrumbs.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: line, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpace.lg : AppSpace.xxl,
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCrumbs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: _Breadcrumbs(items: breadcrumbs),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        height: 1.25,
                      ),
                    ),
                    if (!hasCrumbs &&
                        !compact &&
                        subtitle != null &&
                        subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted(context),
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: AppSpace.md),
                for (final w in actions) ...[
                  w,
                  const SizedBox(width: AppSpace.sm),
                ],
              ] else
                const SizedBox(width: AppSpace.sm),
              _TopBarAction(
                icon: Icons.notifications_none_rounded,
                tooltip: 'الإشعارات',
                onTap: onNotificationsTap,
                badge: unreadCount,
              ),
              if (onThemeToggle != null) ...[
                const SizedBox(width: AppSpace.xs),
                _TopBarAction(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                  onTap: () => onThemeToggle!(!isDark),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badge;

  const _TopBarAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor:
              AppColors.accent(context).withValues(alpha: 0.06),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: AppColors.borderSubtle(context),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: AppColors.textSecondary(context),
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints:
                          const BoxConstraints(minWidth: 15, minHeight: 15),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: AppColors.surface(context),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 11,
                color: AppColors.textMuted(context),
              ),
            ),
          InkWell(
            onTap: items[i].onTap,
            borderRadius: BorderRadius.circular(AppRadii.radiusXs),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                items[i].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: items[i].onTap != null
                      ? AppColors.accent(context)
                      : AppColors.textMuted(context),
                  fontWeight: items[i].onTap != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
