import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        content: Text(
          'تم نسخ $label: $text',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif']),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى', style: TextStyle(fontFamilyFallback: ['sans-serif'])),
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
                padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 14, vertical: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 950 : 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(theme, isDark),
                        const SizedBox(height: 18),

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
                            label: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamilyFallback: ['sans-serif']),
                            ),
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
      padding: const EdgeInsets.all(16),
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
                const Text(
                  'تجديد اشتراك العيادة (Top Up)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif']),
                ),
                const Text(
                  'يرجى التجديد للاستمرار في استخدام خدمات العيادة',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontFamilyFallback: ['sans-serif']),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              const Text('كود العيادة: ', style: TextStyle(fontSize: 12.5, color: AppTheme.primary, fontFamilyFallback: ['sans-serif'])),
              SelectableText(
                widget.inviteCode,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1, fontFamilyFallback: ['monospace', 'sans-serif']),
              ),
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
        const Text('اختر الخطة المناسبة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif'])),
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
                      Expanded(child: Text(p['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif']))),
                      Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: sel ? AppTheme.primary : Colors.grey, size: 17),
                    ]),
                    const SizedBox(height: 2),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(p['price']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamilyFallback: ['monospace', 'sans-serif'])),
                      const SizedBox(width: 3),
                      const Text('ج.م', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamilyFallback: ['sans-serif'])),
                    ]),
                    Text(p['period']!, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamilyFallback: ['sans-serif'])),
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
                        child: Text(p['badge']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif'])),
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
              const Text('تفاصيل وسائل الدفع والتحويل:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif'])),
            ]),
            const SizedBox(height: 12),
            _paymentCard(
              icon: Icons.flash_on_rounded, iconColor: Colors.purple,
              title: '1- Instapay (إنستاباي)',
              items: [
                {'number': '01090671474', 'label': 'رقم إنستاباي'}
              ],
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _paymentCard(
              icon: Icons.phone_android_rounded, iconColor: Colors.green.shade700,
              title: '2- محفظة إلكترونية (فودافون كاش / اتصالات / أورنج)',
              items: [
                {'number': '01107432010', 'label': 'رقم المحفظة (1)'},
                {'number': '01090671474', 'label': 'رقم المحفظة (2)'}
              ],
              isDark: isDark,
            ),
          ]),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(
              'يرجى إرسال صورة التحويل وكود العيادة عبر واتساب',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800, fontFamilyFallback: const ['sans-serif']),
              textAlign: TextAlign.center,
            ),
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
                label: const Text('إرسال عبر واتساب (01090671474)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif'])),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

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
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Map<String, String>> items,
    required bool isDark,
  }) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final numColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamilyFallback: const ['sans-serif'],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) {
            final numStr = item['number']!;
            final labelStr = item['label']!;
            return Padding(
              padding: EdgeInsets.only(top: item != items.first ? 8 : 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    SelectableText(
                      numStr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: numColor,
                        fontFamilyFallback: const ['monospace', 'Roboto', 'sans-serif'],
                      ),
                    ),
                    const Spacer(),
                    _copyBtn(() => _copy(numStr, labelStr), 'نسخ'),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _copyBtn(VoidCallback onTap, String label) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.copy_rounded, size: 13),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamilyFallback: ['sans-serif']),
        ),
      ),
    );
  }
}
