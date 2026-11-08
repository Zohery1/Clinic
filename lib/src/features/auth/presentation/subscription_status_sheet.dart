import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import 'top_up_subscription_screen.dart';

class SubscriptionStatusSheet extends StatefulWidget {
  final DateTime? subscriptionEndDate;
  final String clinicName;
  final String clinicId;
  final String inviteCode;

  const SubscriptionStatusSheet({
    super.key,
    this.subscriptionEndDate,
    required this.clinicName,
    required this.clinicId,
    required this.inviteCode,
  });

  @override
  State<SubscriptionStatusSheet> createState() => _SubscriptionStatusSheetState();
}

class _SubscriptionStatusSheetState extends State<SubscriptionStatusSheet> {
  Timer? _timer;
  DateTime? _endDate;
  String _inviteCode = '';
  String _clinicName = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endDate = widget.subscriptionEndDate;
    _inviteCode = widget.inviteCode;
    _clinicName = widget.clinicName;

    if (_endDate == null && widget.clinicId.isNotEmpty) {
      _fetchClinicData();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _fetchClinicData() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('name, invite_code, subscription_end_date')
          .eq('id', widget.clinicId)
          .maybeSingle();

      if (res != null && mounted) {
        final endDateStr = res['subscription_end_date'] as String?;
        setState(() {
          if (endDateStr != null) {
            _endDate = DateTime.parse(endDateStr);
          }
          if ((res['name'] as String?)?.isNotEmpty == true) {
            _clinicName = res['name'] as String;
          }
          if ((res['invite_code'] as String?)?.isNotEmpty == true) {
            _inviteCode = res['invite_code'] as String;
          }
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endDate = _endDate ?? now.add(const Duration(days: 30));
    final diff = endDate.difference(now);

    final isExpired = diff.isNegative;
    final isExpiringSoon = !isExpired && diff.inHours <= 48;

    final daysLeft = isExpired ? 0 : diff.inDays;
    final hoursLeft = isExpired ? 0 : (diff.inHours % 24);
    final minutesLeft = isExpired ? 0 : (diff.inMinutes % 60);

    final formattedEndDate = intl.DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(endDate.toLocal());

    final statusColor = isExpired
        ? AppColors.danger
        : (isExpiringSoon ? AppColors.warning : AppColors.success);

    final statusBg = isExpired
        ? AppColors.dangerSubtle
        : (isExpiringSoon ? AppColors.warningSubtle : AppColors.successSubtle);

    final statusLabel = isExpired
        ? 'الاشتراك منتهي'
        : (isExpiringSoon ? 'ينتهي قريباً' : 'الاشتراك نشط');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar for Bottom Sheet
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الاشتراك والتجديد',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        _clinicName.isNotEmpty ? _clinicName : 'العيادة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textMuted(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Main Status Card
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpired
                                ? Icons.error_outline_rounded
                                : (isExpiringSoon ? Icons.flash_on_rounded : Icons.check_circle_rounded),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!isExpired) ...[
                      Text(
                        'الوقت المتبقي على انتهاء الفترة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeUnit(context, minutesLeft.toString().padLeft(2, '0'), 'دقيقة'),
                          _buildTimeSeparator(context),
                          _buildTimeUnit(context, hoursLeft.toString().padLeft(2, '0'), 'ساعة'),
                          _buildTimeSeparator(context),
                          _buildTimeUnit(context, daysLeft.toString(), 'يوم'),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'انتهت فترة اشتراك العيادة',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يرجى التجديد الآن لمتابعة العمل على النظام.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppColors.borderSubtle(context)),
                    const SizedBox(height: 12),

                    // Expiration Date Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_rounded, size: 14, color: AppColors.textMuted(context)),
                        const SizedBox(width: 6),
                        Text(
                          'ينتهي في: $formattedEndDate',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Clinic Invite Code Info Card
              if (_inviteCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'كود تفعيل العيادة:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const Spacer(),
                      SelectableText(
                        _inviteCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Renewal CTA Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 680),
                          child: TopUpSubscriptionScreen(
                            clinicName: _clinicName,
                            inviteCode: _inviteCode,
                            clinicId: widget.clinicId,
                            onRefresh: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'تجديد الاشتراك الآن',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  Widget _buildTimeUnit(BuildContext context, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.borderSubtle(context)),
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10.5,
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        ':',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted(context),
        ),
      ),
    );
  }
}
