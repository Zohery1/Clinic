import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // مؤقت فوري كل ثانية لتحديث العداد بانتظام بالوقت الحقيقي
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
    final theme = Theme.of(context);
    final now = DateTime.now();
    final endDate = _endDate ?? now.add(const Duration(days: 30));
    final diff = endDate.difference(now);

    final isExpired = diff.isNegative;
    final isExpiringSoon = !isExpired && diff.inHours <= 48;

    final daysLeft = isExpired ? 0 : diff.inDays;
    final hoursLeft = isExpired ? 0 : (diff.inHours % 24);
    final minutesLeft = isExpired ? 0 : (diff.inMinutes % 60);

    final formattedEndDate = intl.DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(endDate.toLocal());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar for Bottom Sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title with Receipt Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFFEA580C),
                    size: 24,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      Text(
                        _clinicName.isNotEmpty ? _clinicName : 'العيادة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
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
              // Main Status & Countdown Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExpired
                        ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                        : isExpiringSoon
                            ? [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]
                            : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isExpired
                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                        : isExpiringSoon
                            ? const Color(0xFFF97316).withValues(alpha: 0.4)
                            : const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpired
                                ? Icons.error_outline_rounded
                                : isExpiringSoon
                                    ? Icons.flash_on_rounded
                                    : Icons.check_circle_rounded,
                            size: 14,
                            color: isExpired
                                ? const Color(0xFFEF4444)
                                : isExpiringSoon
                                    ? const Color(0xFFF97316)
                                    : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpired
                                ? 'الاشتراك منتهي'
                                : isExpiringSoon
                                    ? 'ينتهي قريباً ⚡'
                                    : 'الاشتراك نشط وساري ✅',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isExpired
                                  ? const Color(0xFFEF4444)
                                  : isExpiringSoon
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Countdown Timer (دقيقة على اليمين - يوم على اليسار)
                    if (!isExpired) ...[
                      Text(
                        'الوقت المتبقي على انتهاء الفترة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeUnit(minutesLeft.toString().padLeft(2, '0'), 'دقيقة'),
                          _buildTimeSeparator(),
                          _buildTimeUnit(hoursLeft.toString().padLeft(2, '0'), 'ساعة'),
                          _buildTimeSeparator(),
                          _buildTimeUnit(daysLeft.toString(), 'يوم'),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'انتهت فترة اشتراك العيادة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يرجى التجديد الآن لمتابعة استغلال كافة ميزات النظام',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 12),

                    // Expiration Date Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          'ينتهي في: $formattedEndDate',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
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
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'كود تفعيل العيادة:',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      SelectableText(
                        _inviteCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Renewal CTA Button (زر التجديد)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close status sheet
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
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
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تجديد الاشتراك الآن ⚡',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
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

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10.5,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        ':',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black45,
        ),
      ),
    );
  }
}
