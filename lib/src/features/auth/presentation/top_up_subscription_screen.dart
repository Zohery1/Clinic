import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'login_controller.dart';
import 'login_screen.dart';

class TopUpSubscriptionScreen extends ConsumerStatefulWidget {
  final String clinicName;
  final String inviteCode;
  final String clinicId;
  final VoidCallback onRefresh;

  const TopUpSubscriptionScreen({
    super.key,
    required this.clinicName,
    required this.inviteCode,
    required this.clinicId,
    required this.onRefresh,
  });

  @override
  ConsumerState<TopUpSubscriptionScreen> createState() => _TopUpSubscriptionScreenState();
}

class _TopUpSubscriptionScreenState extends ConsumerState<TopUpSubscriptionScreen> {
  int _selectedPlanIndex = 1;
  bool _isSubmitting = false;

  static const _plans = [
    {'title': 'شهر واحد', 'price': '550', 'period': 'شهرياً', 'badge': ''},
    {'title': '3 شهور', 'price': '1,600', 'period': 'كل 3 أشهر', 'badge': 'الأكثر طلباً'},
    {'title': '6 شهور', 'price': '3,200', 'period': 'كل 6 أشهر', 'badge': ''},
    {'title': 'سنة كاملة', 'price': '6,400', 'period': 'سنوياً', 'badge': 'أفضل توفير'},
  ];

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('تم نسخ $label: $text', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
  }

  Future<void> _openWhatsApp() async {
    final plan = _plans[_selectedPlanIndex];
    final msg = Uri.encodeComponent(
      'مرحباً، أود تجديد اشتراك العيادة:\n• اسم العيادة: ${widget.clinicName}\n• كود العيادة: ${widget.inviteCode}\n• الخطة: ${plan['title']} (${plan['price']} ج.م)\nمرفق صورة التحويل.',
    );
    final url = Uri.parse('https://wa.me/201090671474?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmTransfer() async {
    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client
          .from('clinics')
          .update({'subscription_status': 'pending_activation'})
          .eq('id', widget.clinicId);
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      widget.onRefresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى', style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 16, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 900 : 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ──
                        _header(theme, isDark),
                        const SizedBox(height: 20),

                        if (isWide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _plansSection(theme, isDark)),
                                const SizedBox(width: 20),
                                Expanded(flex: 6, child: _paymentAndActions(theme, isDark)),
                              ],
                            ),
                          )
                        else ...[
                          _plansSection(theme, isDark),
                          const SizedBox(height: 16),
                          _paymentAndActions(theme, isDark),
                        ],

                        const SizedBox(height: 14),
                        Center(
                          child: TextButton.icon(
                            onPressed: _handleLogout,
                            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_rounded, size: 24, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تجديد اشتراك العيادة', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold)),
                Text('يرجى التجديد للاستمرار في استخدام خدمات العيادة',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          // Clinic code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text('كود العيادة: ', style: GoogleFonts.cairo(fontSize: 12.5, color: AppTheme.primary)),
              Text(widget.inviteCode,
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
              const Spacer(),
              _copyBtn(() => _copy(widget.inviteCode, 'كود العيادة'), 'نسخ الكود'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _plansSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('اختر الخطة المناسبة:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: 4,
          itemBuilder: (_, i) {
            final p = _plans[i];
            final sel = _selectedPlanIndex == i;
            return InkWell(
              onTap: () => setState(() => _selectedPlanIndex = i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.07) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AppTheme.primary : (isDark ? Colors.white10 : Colors.black12),
                    width: sel ? 2.5 : 1,
                  ),
                ),
                child: Stack(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      Expanded(child: Text(p['title']!, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold))),
                      Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: sel ? AppTheme.primary : Colors.grey, size: 17),
                    ]),
                    const SizedBox(height: 2),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(p['price']!, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                      const SizedBox(width: 3),
                      Text('ج.م', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ]),
                    Text(p['period']!, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
                  ]),
                  if (p['badge']!.isNotEmpty)
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: i == 1 ? Colors.orange.shade800 : AppTheme.success,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(p['badge']!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _paymentAndActions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment methods
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('تفاصيل وسائل الدفع والتحويل:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _paymentBox(
              icon: Icons.flash_on_rounded, iconColor: Colors.purple,
              title: '1- Instapay (إنستاباي)',
              numbers: [('01090671474', 'رقم إنستاباي')],
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _paymentBox(
              icon: Icons.phone_android_rounded, iconColor: Colors.green.shade700,
              title: '2- محفظة إلكترونية (فودافون كاش / اتصالات / أورنج)',
              numbers: [('01107432010', 'رقم المحفظة (1)'), ('01090671474', 'رقم المحفظة (2)')],
              isDark: isDark,
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // WhatsApp
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text('يرجى إرسال صورة التحويل وكود العيادة عبر واتساب',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 40,
              child: ElevatedButton.icon(
                onPressed: _openWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text('إرسال عبر واتساب (01090671474)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Submit
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _confirmTransfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified_rounded, size: 18),
            label: Text(
              _isSubmitting ? 'جاري التسجيل...' : 'تم إرسال الفاتورة / تأكيد التحويل',
              style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentBox({
    required IconData icon, required Color iconColor, required String title,
    required List<(String, String)> numbers, required bool isDark,
  }) {
    final numColor = isDark ? Colors.white : const Color(0xFF1E3A5F);
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        ...numbers.map((n) => Padding(
          padding: EdgeInsets.only(top: n != numbers.first ? 6 : 0),
          child: Row(children: [
            Text(n.$1, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: numColor)),
            const Spacer(),
            _copyBtn(() => _copy(n.$1, n.$2), 'نسخ'),
          ]),
        )),
      ]),
    );
  }

  Widget _copyBtn(VoidCallback onTap, String label) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: const Icon(Icons.copy_rounded, size: 13),
        label: Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
