import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/shadows.dart';
import '../tokens/spacing.dart';

/// Polished card wrapper around any chart (LineChart, BarChart, ...).
/// Title + optional subtitle in the header, optional `actions` slot
/// (e.g. range tabs) on the right. Same elevation as a standard card.
class AppChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? actions;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double height;

  const AppChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
        boxShadow: AppShadows.sm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) actions!,
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: SizedBox(height: height, child: child),
          ),
        ],
      ),
    );
  }
}