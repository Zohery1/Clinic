import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'login_controller.dart';
import 'login_screen.dart';

class SubscriptionPlan {
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final String? badge;

  const SubscriptionPlan({
    required this.title,
    required this.price,
    required this.period,
    this.isPopular = false,
    this.badge,
  });
}

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
  int _selectedPlanIndex = 1; // Default to 3 months (most popular)
  bool _isSubmitting = false;

  final List<SubscriptionPlan> _plans = const [
    SubscriptionPlan(
      title: 'شهر واحد',
      price: '550',
      period: 'شهرياً',
    ),
    SubscriptionPlan(
      title: '3 شهور',
      price: '1,600',
      period: 'كل 3 أشهر',
      isPopular: true,
      badge: 'الأكثر طلباً',
    ),
    SubscriptionPlan(
      title: '6 شهور',
      price: '3,200',
      period: 'كل 6 أشهر',
    ),
    SubscriptionPlan(
      title: 'سنة كاملة',
      price: '6,400',
      period: 'سنوياً',
      badge: 'أفضل توفير',
    ),
  ];

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ $label: $text',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final selectedPlan = _plans[_selectedPlanIndex];
    final String message = Uri.encodeComponent(
      'مرحباً، أود تجديد اشتراك العيادة:\n'
      '• اسم العيادة: ${widget.clinicName}\n'
      '• كود العيادة: ${widget.inviteCode}\n'
      '• الخطة المختارة: ${selectedPlan.title} (${selectedPlan.price} ج.م)\n'
      'مرفق صورة التحويل/الفاتورة.',
    );
    final Uri url = Uri.parse('https://wa.me/201090671474?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح واتساب تلقائياً. رقم الواتساب: 01090671474',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmTransferSubmitted() async {
    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client
          .from('clinics')
          .update({'subscription_status': 'pending_activation'})
          .eq('id', widget.clinicId);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم تسليم الطلب! جاري تحويلك لشاشة الانتظار والمراجعة.',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );

        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }

      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في الاتصال، يرجى المحاولة مرة أخرى أو التواصل عبر واتساب.',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
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
              final isWide = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 1000 : 550),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── Header Card ───
                        _buildHeaderCard(theme, isDark),
                        const SizedBox(height: 20),

                        // ─── Main Content (Responsive Grid/Column) ───
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left/Right: Plans
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPlansHeader(),
                                    const SizedBox(height: 12),
                                    _buildPlansGrid(theme, isDark, isWide: true),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right/Left: Payment & Actions
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPaymentMethodsCard(theme, isDark),
                                    const SizedBox(height: 16),
                                    _buildWhatsAppInstructionsCard(theme, isDark),
                                    const SizedBox(height: 20),
                                    _buildSubmitButton(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPlansHeader(),
                              const SizedBox(height: 12),
                              _buildPlansGrid(theme, isDark, isWide: false),
                              const SizedBox(height: 20),
                              _buildPaymentMethodsCard(theme, isDark),
                              const SizedBox(height: 16),
                              _buildWhatsAppInstructionsCard(theme, isDark),
                              const SizedBox(height: 20),
                              _buildSubmitButton(),
                            ],
                          ),

                        const SizedBox(height: 16),
                        // Logout
                        Center(
                          child: TextButton.icon(
                            onPressed: _handleLogout,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  size: 30,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تجديد اشتراك العيادة (Top Up)',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      'يرجى تجديد الاشتراك للاستمرار في استخدام خدمات العيادة',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Clinic Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'كود العيادة: ',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
                SelectableText(
                  widget.inviteCode,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(widget.inviteCode, 'كود العيادة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text(
                    'نسخ الكود',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansHeader() {
    return Text(
      'اختر خطة الاشتراك المناسبة:',
      style: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPlansGrid(ThemeData theme, bool isDark, {required bool isWide}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 2,
        childAspectRatio: isWide ? 1.4 : 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        final isSelected = _selectedPlanIndex == index;

        return InkWell(
          onTap: () => setState(() => _selectedPlanIndex = index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.08)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primary : (isDark ? Colors.white10 : Colors.black12),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppTheme.primary : Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          plan.price,
                          style: GoogleFonts.cairo(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      plan.period,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (plan.badge != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: plan.isPopular ? Colors.orange.shade800 : AppTheme.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plan.badge!,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'تفاصيل وسائل الدفع والتحويل:',
                style: GoogleFonts.cairo(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Method 1: Instapay
          _buildHighContrastPaymentBox(
            icon: Icons.flash_on_rounded,
            iconColor: Colors.purple,
            title: '1- Instapay (إنستاباي)',
            number: '01090671474',
            onCopy: () => _copyToClipboard('01090671474', 'رقم إنستاباي'),
            isDark: isDark,
          ),

          const SizedBox(height: 10),

          // Method 2: Mobile Wallets (01107432010 & 01090671474)
          _buildHighContrastPaymentBox(
            icon: Icons.phone_android_rounded,
            iconColor: Colors.green.shade700,
            title: '2- محفظة إلكترونية (فودافون كاش / اتصالات / أورنج):',
            number: '01107432010',
            secondNumber: '01090671474',
            onCopy: () => _copyToClipboard('01107432010', 'رقم المحفظة (1)'),
            onCopySecond: () => _copyToClipboard('01090671474', 'رقم المحفظة (2)'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHighContrastPaymentBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String number,
    String? secondNumber,
    required VoidCallback onCopy,
    VoidCallback? onCopySecond,
    required bool isDark,
  }) {
    final boxBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final numberTextColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // First Number Row
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  number,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: numberTextColor,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onCopy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: Text(
                  'نسخ الرقم',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Optional Second Number Row
          if (secondNumber != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 8),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    secondNumber,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: numberTextColor,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onCopySecond,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: Text(
                    'نسخ الثاني',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatsAppInstructionsCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mark_chat_read_rounded, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'خطوة التحقق: يرجى إرسال صورة التحويل وكود العيادة عبر واتساب',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openWhatsApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                'إرسال الفاتورة عبر واتساب (01090671474)',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmTransferSubmitted,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified_rounded, size: 20),
        label: Text(
          _isSubmitting ? 'جاري التحويل...' : 'تم إرسال الفاتورة / الانقال للانتظار',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
