import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Brand mark. Uses the shipped clinic logo and never re-draws it.
///
/// Set [showWordmark] for the sidebar/auth lockup, leave it false for compact
/// placements such as the mobile top bar.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final String? title;
  final String? subtitle;
  final bool onDark;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showWordmark = false,
    this.title,
    this.subtitle,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: onDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/brand/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!showWordmark) return mark;

    final primary = onDark ? Colors.white : AppColors.textPrimary(context);
    final secondary = onDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.textMuted(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: AppSpace.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? 'عيادتي',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  height: 1.15,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: secondary,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
