import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/demo/demo_clinical_data.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../../main.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'login_controller.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'verify_otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  int _selectedRoleIndex = 0; // 0 = طبيب / مدير العيادة, 1 = طاقم الاستقبال

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      await ref.read(loginControllerProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      final loginState = ref.read(loginControllerProvider);
      if (mounted) {
        if (loginState.isEmailVerificationRequired) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(email: _emailController.text.trim()),
            ),
          );
        } else if (loginState.isSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
      }
    }
  }

  void _enterDemoMode() {
    ref.read(currentUserProvider.notifier).state = DemoClinicalData.doctorUser;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          clinicName: 'مستشفى وعيادات الأمل التخصصية',
          clinicId: 'demo-clinic-01',
          inviteCode: 'AMAL-2026',
          subscriptionEndDate: DateTime.now().add(const Duration(days: 365)),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(
                next.errorMessage!,
                style: GoogleFonts.cairo(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isDark = AppColors.isDark(context);

    return AuthShell(
      heroTitle: 'أهلاً بك في عيادتك',
      heroSubtitle: 'منصة إدارة العيادات الذكية — كل ما تحتاجه لإدارة مواعيدك ومرضاك وفواتيرك في مكان واحد.',
      footer: const _LoginFooter(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عنوان تسجيل الدخول
              Text(
                'تسجيل الدخول للمنظومة',
                textAlign: TextAlign.start,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'سجّل دخولك لإدارة عيادتك وطابور الكشف بكفاءة وسرعة',
                textAlign: TextAlign.start,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // محدد الدور السريري (Role Selector)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderSubtle(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleTabItem(
                        title: 'طبيب / مدير العيادة',
                        icon: Icons.medical_services_rounded,
                        isSelected: _selectedRoleIndex == 0,
                        onTap: () => setState(() => _selectedRoleIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _RoleTabItem(
                        title: 'طاقم الاستقبال',
                        icon: Icons.badge_outlined,
                        isSelected: _selectedRoleIndex == 1,
                        onTap: () => setState(() => _selectedRoleIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // حقل البريد الإلكتروني
              AppTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني المهني',
                hint: _selectedRoleIndex == 0 ? 'doctor@clinic.com' : 'reception@clinic.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.lg),

              // حقل كلمة المرور
              AppTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                obscure: !_isPasswordVisible,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                onEditingComplete: () => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                  if (value.length < 6) return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.sm),

              // نسيت كلمة المرور
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordScreen(isUpdateMode: false),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // زر تسجيل الدخول
              AppButton(
                label: 'تسجيل الدخول للعيادة',
                onPressed: loginState.isLoading ? null : _submit,
                loading: loginState.isLoading,
              ),
              const SizedBox(height: AppSpace.md),

              // فاصل أو
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderSubtle(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    child: Text(
                      'أو للمعاينة السريعة',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.borderSubtle(context))),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              // زر الدخول التجريبي الفوري (One-Click Demo Mode)
              OutlinedButton.icon(
                onPressed: _enterDemoMode,
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Color(0xFF0284C7)),
                label: Text(
                  'دخول تجريبي فوري للنظام (معاينة كاملة كمالك العيادة)',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.subtle(context),
                  side: BorderSide(color: AppColors.border(context), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTabItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textMuted(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ليس لديك حساب عيادة؟',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'تأسيس عيادة جديدة الآن',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
