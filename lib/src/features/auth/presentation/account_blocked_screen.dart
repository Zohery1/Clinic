import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'login_controller.dart';
import 'login_screen.dart';

class AccountBlockedScreen extends ConsumerStatefulWidget {
  final String userName;
  final String clinicName;
  final VoidCallback onRefresh;

  const AccountBlockedScreen({
    super.key,
    required this.userName,
    required this.clinicName,
    required this.onRefresh,
  });

  @override
  ConsumerState<AccountBlockedScreen> createState() => _AccountBlockedScreenState();
}

class _AccountBlockedScreenState extends ConsumerState<AccountBlockedScreen> {
  bool _isChecking = false;

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

  void _checkAgain() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onRefresh();
    if (mounted) {
      setState(() => _isChecking = false);
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
                  // الأيقونة الرئيسية المضيئة
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      size: 42,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // العنوان الرئيسي
                  Text(
                    'تم إيقاف حسابك من قبل الطبيب',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // اسم السكرتيرة والعيادة
                  Text(
                    widget.userName.isNotEmpty
                        ? 'أهلاً بك يا ${widget.userName}'
                        : 'عزيزي المساعد / السكرتير',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // رسالة التوضيح
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 18, color: AppTheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'قام الطبيب المسؤول في عيادة «${widget.clinicName}» بإيقاف صلاحيات دخول هذا الحساب مؤقتاً.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.help_outline_rounded,
                                size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يرجى مراجعة الطبيب لإعادة تفعيل حسابك من شاشة إدارة فريق العمل داخل الإعدادات.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // أزرار التفاعل
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isChecking ? null : _checkAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                          _isChecking
                              ? 'جاري التحقق...'
                              : 'إعادة المحاولة والتحقق من التفعيل',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          'تسجيل الخروج والتغيير',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
