import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
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
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    // إعادة فحص حالة العيادة تلقائياً كل 3 ثوانٍ للدخول فور تفعيل الأدمن
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        widget.onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _checkAgain() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onRefresh();

    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'طلبك ما زال قيد المراجعة والتفعيل من الإدارة. تواصل معنا عبر واتساب للمتابعة.',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber.shade900,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.inviteCode));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'تم نسخ كود العيادة (${widget.inviteCode})',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
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
    final String message = Uri.encodeComponent(
      'مرحباً، أود الاستفسار عن حالة تفعيل اشتراك العيادة:\n'
      '• اسم العيادة: ${widget.clinicName}\n'
      '• كود العيادة: ${widget.inviteCode}',
    );
    final Uri url = Uri.parse('https://wa.me/201090671474?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح واتساب تلقائياً. رقم الدعم: 01090671474',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Status Icon ───
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 42,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'جارٍ تفعيل اشتراك العيادة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.clinicName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Clinic Code Badge ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'كود العيادة: ',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          widget.inviteCode,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _copyCode,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.copy_rounded, color: Colors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      'تم استلام طلب التجديد/التسجيل بنجاح، وجارٍ مراجعة الفاتورة وتفعيل الاشتراك من قِبل الإدارة. سنقوم بتفعيل حساب العيادة فور التأكد من عملية التحويل.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        height: 1.6,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _isChecking ? 'جاري التحقق...' : 'التحقق من حالة التفعيل الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // WhatsApp Contact Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _openWhatsApp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text(
                        'تواصل مع الدعم عبر واتساب',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton.icon(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'تسجيل الخروج',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
