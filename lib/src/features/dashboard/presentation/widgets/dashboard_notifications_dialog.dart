import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../notifications_controller.dart';

/// Modal bottom-sheet notifications dialog with a clean header and list.
/// Honors the new design tokens.
class DashboardNotificationsDialog {
  const DashboardNotificationsDialog();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 12,
              right: 12,
              bottom: media.viewInsets.bottom + 12,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.75,
                maxWidth: 540,
              ),
              child: const _NotificationsSheet(),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  String _formatTime(DateTime d) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(d);
    } catch (_) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.radiusX2l)),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: AppRadii.brSm,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    'Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª ÙˆØ§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ),
                  ),
                ),
                if (state.notifications.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => notifier.markAllAsRead(),
                    child: Text(
                      'Ù…Ø³Ø­ Ø§Ù„ÙƒÙ„',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle(context),
          ),
          Flexible(
            child: state.isLoading && state.notifications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpace.xxl),
                    child: Center(
                      child: Text(
                        'Ø¬Ø§Ø±Ù Ø§Ù„ØªØ­Ù…ÙŠÙ„â€¦',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
                  )
                : state.notifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 36,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              'Ù„Ø§ ØªÙˆØ¬Ø¯ ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹',
                              style: GoogleFonts.cairo(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle(context),
                        ),
                        itemBuilder: (context, index) {
                          final n = state.notifications[index];
                          IconData icon = Icons.notifications_rounded;
                          Color color = AppColors.primary;
                          if (n.title == 'Ø­Ø¬Ø² Ø¬Ø¯ÙŠØ¯') {
                            icon = Icons.event_available_rounded;
                            color = AppColors.primary;
                          } else if (n.title == 'Ø¥Ø¶Ø§ÙØ© Ø®Ø¯Ù…Ø© Ø·Ø¨ÙŠØ©') {
                            icon = Icons.medical_services_rounded;
                            color = AppColors.completed;
                          }
                          return InkWell(
                            onTap: () => notifier.markAsRead(n.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.lg,
                                vertical: AppSpace.md,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                                      borderRadius: AppRadii.brSm,
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary(context),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          n.body,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary(context),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatTime(n.createdAt),
                                          style: GoogleFonts.cairo(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted(context),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    notifier.markAllAsRead();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Ø¥ØºÙ„Ø§Ù‚',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}