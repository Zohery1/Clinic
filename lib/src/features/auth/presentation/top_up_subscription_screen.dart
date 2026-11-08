import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import '../../../core/routing/routing.dart';
import 'login_controller.dart';

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
  int _selectedPaymentMethod = 0;
  bool _isSubmitting = false;
  late String _inviteCode;
  bool _isLoadingCode = false;

  static const _plans = [
    {'title': 'شهر واحد', 'price': '550', 'period': 'شهرياً', 'badge': ''},
    {'title': '3 شهور', 'price': '1,600', 'period': 'كل 3 أشهر', 'badge': 'الأكثر طلباً'},
    {'title': '6 شهور', 'price': '3,200', 'period': 'كل 6 أشهر', 'badge': ''},
    {'title': 'سنة كاملة', 'price': '6,400', 'period': 'سنوياً', 'badge': 'أفضل توفير'},
  ];

  @override
  void initState() {
    super.initState();
    _inviteCode = widget.inviteCode;
    if (_inviteCode.trim().isEmpty && widget.clinicId.isNotEmpty) {
      _fetchInviteCode();
    }
  }

  Future<void> _fetchInviteCode() async {
    setState(() => _isLoadingCode = true);
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('invite_code')
          .eq('id', widget.clinicId)
          .maybeSingle();
      if (res != null && res['invite_code'] != null && mounted) {
        setState(() {
          _inviteCode = res['invite_code'] as String;
        });
      }
    } catch (_) {
      // Keep existing code if error
    } finally {
      if (mounted) setState(() => _isLoadingCode = false);
    }
  }

  void _copy(String text, String label) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: cleanText));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'تم نسخ $label: $cleanText',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  Future<void> _openWhatsApp() async {
    final plan = _plans[_selectedPlanIndex];
    final codeStr = _inviteCode.isNotEmpty ? _inviteCode : widget.inviteCode;
    final msg = Uri.encodeComponent(
      'مرحباً، أود تجديد اشتراك العيادة:\n• اسم العيادة: ${widget.clinicName}\n• كود العيادة: $codeStr\n• الخطة: ${plan['title']} (${plan['price']} ج.م)\nمرفق صورة التحويل.',
    );
    final url = Uri.parse('https://wa.me/201090671474?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmTransfer() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('subscription_end_date, subscription_status')
          .eq('id', widget.clinicId)
          .single();

      final endDateStr = res['subscription_end_date'] as String?;
      final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
      final statusStr = (res['subscription_status'] as String? ?? 'active').toLowerCase();

      final isAlreadyExpired = statusStr == 'expired' || 
          statusStr == 'pending_activation' ||
          (endDate != null && endDate.toUtc().isBefore(DateTime.now().toUtc()));

      final plan = _plans[_selectedPlanIndex];
      final priceNum = double.tryParse(plan['price']!.replaceAll(',', '').trim()) ?? 550.0;

      if (isAlreadyExpired) {
        // إذا كان الاشتراك منتهياً بالفعل، يتم التحديث بطلب تفعيل وتجديد لينتقل لشاشة الانتظار
        await Supabase.instance.client
            .from('clinics')
            .update({
              'subscription_status': 'pending_activation',
              'renewal_requested': true,
              'renewal_requested_at': DateTime.now().toIso8601String(),
              'renewal_plan': plan['title'],
              'renewal_plan_price': priceNum,
            })
            .eq('id', widget.clinicId);

        try {
          await Supabase.instance.client.rpc('request_subscription_renewal', params: {
            'p_plan': plan['title'],
            'p_price': priceNum,
          });
        } catch (_) {}

        if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
        widget.onRefresh();
      } else {
        // إذا كان الاشتراك ما زال سارياً وجدد مبكراً، نسجل طلب التجديد فوراً في قاعدة البيانات مع إبقاء العيادة شريحة نشطة
        await Supabase.instance.client
            .from('clinics')
            .update({
              'renewal_requested': true,
              'renewal_requested_at': DateTime.now().toIso8601String(),
              'renewal_plan': plan['title'],
              'renewal_plan_price': priceNum,
            })
            .eq('id', widget.clinicId);

        try {
          await Supabase.instance.client.rpc('request_subscription_renewal', params: {
            'p_plan': plan['title'],
            'p_price': priceNum,
          });
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'تم تسجيل طلب تجديد الباقة (${plan['title']}) بنجاح. جاري مراجعة التحويل وتمديد الاشتراك.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ));
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تعذر إرسال طلب التجديد حالياً، يرجى المحاولة لاحقاً أو التواصل مع الدعم الفني.', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
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
      AppNavigation.toLogin(context, clearStack: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SelectionArea(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 24 : 10,
                    vertical: isWide ? 16 : 8,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 950 : 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(),
                          const SizedBox(height: 8),

                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _plansSection()),
                                const SizedBox(width: 16),
                                Expanded(flex: 6, child: _paymentAndActions()),
                              ],
                            )
                          else ...[
                            _plansSection(),
                            const SizedBox(height: 8),
                            _paymentAndActions(),
                          ],

                          if (!Navigator.canPop(context)) ...[
                            const SizedBox(height: 6),
                            Center(
                              child: TextButton.icon(
                                onPressed: _handleLogout,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                ),
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: Text(
                                  'تسجيل الخروج',
                                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final displayCode = _inviteCode.isNotEmpty ? _inviteCode : widget.inviteCode;
    final canClose = Navigator.canPop(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.cloud_upload_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تجديد اشتراك العيادة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      'اختر الخطة المناسبة للاستمرار في خدمات العيادة',
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!canClose) ...[
                const SizedBox(width: 8),
                const ClinicSwitcherButton(isCompact: true),
              ],
              if (canClose) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'إغلاق',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.subtle(context),
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ],
          ),
          if (displayCode.isNotEmpty || _isLoadingCode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'كود العيادة:',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isLoadingCode)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  else
                    SelectableText(
                      displayCode,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  const Spacer(),
                  if (displayCode.isNotEmpty)
                    SelectionContainer.disabled(
                      child: InkWell(
                        onTap: () => _copy(displayCode, 'كود العيادة'),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'نسخ',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _plansSection() {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'اختر خطة الاشتراك:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: isMobile ? 1.7 : 1.35,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 4,
          itemBuilder: (_, i) {
            final p = _plans[i];
            final sel = _selectedPlanIndex == i;
            return InkWell(
              onTap: () => setState(() => _selectedPlanIndex = i),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primarySubtle
                      : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.borderSubtle(context),
                    width: sel ? 1.5 : 1.0,
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
                                p['title']!,
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: sel ? AppColors.primary : AppColors.textMuted(context),
                              size: 15,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                p['price']!,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p['period']!,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    if (p['badge']!.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: i == 1 ? AppColors.warning : AppColors.success,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Text(
                            p['badge']!,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 8.5,
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
        ),
      ],
    );
  }

  Widget _paymentAndActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'بيانات تحويل المبلغ:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.subtle(context),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            children: [
              Expanded(
                child: _paymentTabBtn(
                  title: 'إنستاباي (InstaPay)',
                  icon: Icons.flash_on_rounded,
                  isSelected: _selectedPaymentMethod == 0,
                  onTap: () => setState(() => _selectedPaymentMethod = 0),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _paymentTabBtn(
                  title: 'محافظ إلكترونية',
                  icon: Icons.phone_android_rounded,
                  isSelected: _selectedPaymentMethod == 1,
                  onTap: () => setState(() => _selectedPaymentMethod = 1),
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (_selectedPaymentMethod == 0)
          _paymentInfoCard(
            icon: Icons.flash_on_rounded,
            iconBg: AppColors.primarySubtle,
            iconColor: AppColors.primary,
            title: 'حساب إنستاباي (InstaPay)',
            subtitle: 'حوّل قيمة الباقة إلى حساب إنستاباي:',
            items: [
              {'number': '01090671474', 'label': 'رقم InstaPay'}
            ],
          )
        else
          _paymentInfoCard(
            icon: Icons.phone_android_rounded,
            iconBg: AppColors.successSubtle,
            iconColor: AppColors.success,
            title: 'محافظ فودافون / اتصالات / أورنج',
            subtitle: 'حوّل قيمة الباقة إلى أحد أرقام المحافظ:',
            items: [
              {'number': '01090671474', 'label': 'فودافون كاش'},
              {'number': '01107432010', 'label': 'اتصالات كاش'}
            ],
          ),

        const SizedBox(height: 8),

        // WhatsApp action box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successSubtle,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                'بعد التحويل، يرجى إرسال صورة الإيصال وكود العيادة عبر واتساب',
                style: GoogleFonts.cairo(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'إرسال إثبات التحويل عبر واتساب (01090671474)',
                      style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Submit transfer confirmation button
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _confirmTransfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.verified_rounded, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isSubmitting ? 'جاري تأكيد الطلب...' : 'تأكيد التحويل وإرسال طلب التفعيل',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentTabBtn({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMuted(context)),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final numStr = item['number']!;
            final labelStr = item['label']!;
            return Padding(
              padding: EdgeInsets.only(top: item != items.first ? 6 : 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: Border.all(
                    color: AppColors.borderSubtle(context),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        labelStr,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: SelectableText(
                          numStr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SelectionContainer.disabled(
                      child: InkWell(
                        onTap: () => _copy(numStr, labelStr),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadii.xs),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'نسخ',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
