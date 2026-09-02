import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import 'login_controller.dart';
import 'login_screen.dart';

class PendingActivationScreen extends ConsumerStatefulWidget {
  final String clinicName;
  final String inviteCode;
  final VoidCallback onRefresh;

  const PendingActivationScreen({
    super.key,
    required this.clinicName,
    required this.inviteCode,
    required this.onRefresh,
  });

  @override
  ConsumerState<PendingActivationScreen> createState() => _PendingActivationScreenState();
}

class _PendingActivationScreenState extends ConsumerState<PendingActivationScreen> {
  bool _isChecking = false;

  Future<void> _checkAgain() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onRefresh();
    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('طلبك ما زال قيد المراجعة. تواصل معنا عبر واتساب.', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brSm),
      ));
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text('تم نسخ كود العيادة (${widget.inviteCode})', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.brSm),
    ));
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
    return AppStatusPage(
      icon: Icons.access_time_rounded,
      iconColor: AppColors.warning,
      title: 'حسابك في انتظار التفعيل',
      message: 'حسابك قيد المراجعة من إدارة عيادتي. سيتم تفعيله خلال 24 ساعة كحد أقصى.',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: AppRadii.brMd,
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.clinicName, textAlign: TextAlign.center, style: AppTypography.headingSm(AppColors.textPrimary(context))),
                const SizedBox(height: AppSpace.xs),
                const ClinicSwitcherButton(),
                const SizedBox(height: AppSpace.md),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: AppRadii.brSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: AppRadii.brSm,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: AppSpace.xs),
                        Text('كود العيادة: ', style: AppTypography.bodySm(AppColors.primary)),
                        Text(widget.inviteCode, style: AppTypography.numericMd(AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryAction: StatusAction(
        label: 'تحقُّق من حالة التفعيل الآن',
        onPressed: _isChecking ? null : _checkAgain,
        loading: _isChecking,
        icon: Icons.refresh_rounded,
      ),
      secondaryAction: StatusAction(
        label: 'تسجيل الخروج',
        onPressed: _handleLogout,
        variant: AppButtonVariant.ghost,
        icon: Icons.logout_rounded,
      ),
    );
  }
}
