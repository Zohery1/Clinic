import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'login_controller.dart';
import 'login_screen.dart';

class JoinClinicScreen extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback onRefresh;

  const JoinClinicScreen({
    super.key,
    required this.userName,
    required this.onRefresh,
  });

  @override
  ConsumerState<JoinClinicScreen> createState() => _JoinClinicScreenState();
}

class _JoinClinicScreenState extends ConsumerState<JoinClinicScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
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

  void _joinClinic() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال كود العيادة الجديد (رمز الدعوة)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);
    final res = await ref.read(authRepositoryProvider).joinClinicWithInviteCode(code);
    if (mounted) {
      setState(() => _isJoining = false);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'تم الانضمام للعيادة بنجاح'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'كود العيادة غير صحيح'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // الأيقونة المضيئة للاختيار والربط بالعيادة
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // العنوان الرئيسي
                  Text(
                    'الانضمام لعيادة جديدة',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // الترحيب باسم المساعد
                  Text(
                    widget.userName.isNotEmpty
                        ? 'أهلاً بك يا ${widget.userName} 👋'
                        : 'أهلاً بك عزيزي المساعد / السكرتير 👋',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // كارت التعليمات
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
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'للبدء في استخدام النظام مع عيادتك الجديدة، يرجى كتابة كود العيادة (رمز الدعوة) المعطى لك من قبل الطبيب.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // حقل كتابة كود العيادة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كود العيادة (رمز الدعوة):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _inviteCodeController,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'أدخل الرمز هنا (مثال: CL-9X28)',
                          hintStyle: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0,
                          ),
                          prefixIcon: Icon(Icons.vpn_key_rounded,
                              color: theme.colorScheme.primary),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // أزرار الانضمام والخروج
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinClinic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: _isJoining
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded, size: 20),
                        label: Text(
                          _isJoining
                              ? 'جاري الربط بالعيادة...'
                              : 'الانضمام للعيادة والبدء',
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
                          'تسجيل الخروج من الحساب',
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
