import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/invite_utils.dart';
import 'login_controller.dart';
import 'login_screen.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;

  const RegisterScreen({
    super.key,
    this.initialInviteCode,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  String _selectedRole = 'doctor'; // doctor or secretary
  int _currentStep = 0; // 0: البيانات الشخصية والتواصل, 1: حساب الدخول والعيادة
  bool _isPasswordVisible = false;
  bool _isInviteCodeLocked = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    String? inviteCode = widget.initialInviteCode;
    if (inviteCode == null || inviteCode.trim().isEmpty) {
      inviteCode = InviteUtils.extractInviteCode();
    }

    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      final cleanCode = inviteCode.trim();
      _inviteCodeController.text = cleanCode;
      _selectedRole = 'secretary';
      _isInviteCodeLocked = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _inviteCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_step1FormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _goToStep1() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _submit() async {
    if (_step2FormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final email = _emailController.text.trim();

      await ref.read(loginControllerProvider.notifier).register(
            email: email,
            password: _passwordController.text,
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            role: _selectedRole,
            clinicName: _selectedRole == 'doctor' ? _clinicNameController.text : null,
            inviteCode: _selectedRole == 'secretary' ? _inviteCodeController.text : null,
          );

      final loginState = ref.read(loginControllerProvider);
      if (loginState.isSuccess && mounted) {
        if (loginState.isEmailVerificationRequired) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(email: email),
            ),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;
    final double cardPadding = isMobile ? 18.0 : 32.0;

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(
                next.errorMessage!,
                style: TextStyle(color: theme.colorScheme.onError),
                textAlign: TextAlign.start,
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              physics: const ClampingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: isMobile ? 24 : 36),
                    decoration: AppTheme.cardDecoration(context).copyWith(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // شعار التطبيق
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: isMobile ? 32 : 40,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'انضم لمنصة عيادتي لإدارة مركزك الطبي بسهولة',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // شريط التقدّم والشعارات للمراحل
                        _buildStepProgressIndicator(theme),
                        const SizedBox(height: 20),

                        // عرض محتوى المرحلة الحالية
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 0
                              ? _buildStep1Form(theme, isMobile)
                              : _buildStep2Form(theme, loginState, isMobile),
                        ),

                        const SizedBox(height: 16),

                        // رابط التوجيه لتسجيل الدخول
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          ),
        ),
      ),
    );
  }

  // شريط التراكم للمرحلتين (1 و 2)
  Widget _buildStepProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepItem(0, '1. البيانات ورقم التواصل', theme),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep >= 1 ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          _buildStepItem(1, '2. الدخول والعيادة', theme),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, ThemeData theme) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone || isActive ? theme.colorScheme.primary : theme.disabledColor.withValues(alpha: 0.3),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.primary : theme.hintColor,
          ),
        ),
      ],
    );
  }

  // المرحلة 1: البيانات الشخصية ورقم الهاتف
  Widget _buildStep1Form(ThemeData theme, bool isMobile) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // إذا كان الرابط بدعوة يتم إظهار بانر تأكيد الانضمام التلقائي
          if (_isInviteCodeLocked) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل حساب مساعد / سكرتير',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تم تفعيل كود الدعوة للانضمام للعيادة تلقائياً',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _inviteCodeController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // اختيار نوع الحساب (طبيب أم سكرتير) في حال الدخول المباشر بدون رابط
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard('doctor', 'أنا طبيب', Icons.medical_services_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildRoleCard('secretary', 'أنا مساعد/سكرتير', Icons.badge_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // حقل الاسم الكامل
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الاسم الكامل';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // حقل رقم الهاتف الشخصي / الواتساب (مرحلة أساسية ومطلوبة)
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف (الواتساب الشخصي)',
              hintText: '010xxxxxxxx',
              helperText: 'سُيستخدم لتواصل الإدارة وإرسال إشعارات الحساب',
              prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال رقم الهاتف للتواصل';
              }
              if (value.trim().replaceAll(RegExp(r'[^0-9+]'), '').length < 10) {
                return 'يرجى إدخال رقم هاتف صحيح (10 أرقام على الأقل)';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // زر المتابعة للمرحلة الثانية
          ElevatedButton.icon(
            onPressed: _goToStep2,
            icon: const Icon(Icons.arrow_back_rounded, size: 18), // اتجاه السهم يسار مع الكتابة العربية
            label: const Text('المتابعة للمرحلة الثانية'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // المرحلة 2: بيانات الحساب والعيادة
  Widget _buildStep2Form(ThemeData theme, LoginState loginState, bool isMobile) {
    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // حقل البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'example@clinic.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
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
          const SizedBox(height: 14),

          // حقل كلمة المرور
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: _selectedRole == 'doctor' ? TextInputAction.next : TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              if (value.length < 8) {
                return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
              }
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
                return 'كلمة المرور ضعيفة (يجب أن تحتوي على حروف وأرقام)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // حقل اسم العيادة (للطبيب)
          if (_selectedRole == 'doctor') ...[
            TextFormField(
              controller: _clinicNameController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'اسم العيادة / المركز الطبي',
                prefixIcon: Icon(Icons.business_rounded, size: 20),
              ),
              validator: (value) {
                if (_selectedRole == 'doctor' && (value == null || value.trim().isEmpty)) {
                  return 'يرجى إدخال اسم العيادة لتأسيس النظام';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          // حقل كود الدعوة (للسكرتيرة)
          if (_selectedRole == 'secretary') ...[
            TextFormField(
              controller: _inviteCodeController,
              readOnly: _isInviteCodeLocked,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                labelText: 'كود الدعوة من الطبيب',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                suffixIcon: _isInviteCodeLocked
                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20)
                    : null,
                helperText: _isInviteCodeLocked
                    ? '✅ تم ملء كود الدعوة تلقائياً من الرابط'
                    : 'اطلب كود الدعوة من الطبيب للانضمام لعيادته',
                helperStyle: TextStyle(
                  color: _isInviteCodeLocked ? AppTheme.success : null,
                  fontWeight: _isInviteCodeLocked ? FontWeight.w600 : FontWeight.normal,
                ),
                filled: _isInviteCodeLocked,
                fillColor: _isInviteCodeLocked
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : null,
              ),
              validator: (value) {
                if (_selectedRole == 'secretary' && (value == null || value.trim().isEmpty)) {
                  return 'يرجى إدخال كود الدعوة للربط بالعيادة';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 10),

          // زر إنشاء الحساب والبدء
          ElevatedButton(
            onPressed: loginState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: loginState.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                    ),
                  )
                : const Text('إنشاء الحساب والبدء 🚀'),
          ),
          const SizedBox(height: 10),

          // زر العودة للمرحلة الأولى
          TextButton.icon(
            onPressed: _goToStep1,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('الرجوع لتعديل البيانات ورقم الهاتف'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
