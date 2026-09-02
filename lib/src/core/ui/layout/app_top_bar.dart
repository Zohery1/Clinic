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
    this.userName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.surface(context);
    final borderColor = AppColors.borderSubtle(context);

    return Container(
      height: 64,
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.2,
                        letterSpacing: -0.2,
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
              const SizedBox(width: AppSpace.lg),
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
              ),
            ],
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
  const _UserMenuButton({required this.userName, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.borderSubtle(context),
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



