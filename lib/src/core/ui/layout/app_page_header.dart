import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Slim header used at the top of inner pages (e.g. "إدارة الفروع").
/// No breadcrumbs, just title + optional subtitle + a single action slot.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.lg,
        AppSpace.xxl,
        AppSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    height: 1.25,
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
          if (action != null) ...[
            const SizedBox(width: AppSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
