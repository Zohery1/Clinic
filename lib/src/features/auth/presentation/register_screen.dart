import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/invite_utils.dart';
import 'login_controller.dart';
import 'login_screen.dart';
import 'verify_otp_screen.dart';

class _ExtraBranchDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
  }
}

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
  final _step4FormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _mainBranchNameController = TextEditingController(text: 'الفرع الرئيسي');
  final _inviteCodeController = TextEditingController();

  final List<_ExtraBranchDraft> _extraBranches = [];

  // 0: البيانات الشخصية، 1: حساب الدخول، 2: مسار العيادة، 3: بيانات العيادة والفروع أو كود الانضمام
  int _currentStep = 0;
  String _clinicPath = 'create'; // 'create' (تأسيس عيادة) أو 'join' (الانضمام لعيادة)
  String _selectedRole = 'doctor'; // doctor or secretary
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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
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
      _clinicPath = 'join';
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
    _mainBranchNameController.dispose();
    _inviteCodeController.dispose();
    for (final branch in _extraBranches) {
      branch.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = step;
    });
  }

  void _goToStep2() {
    if (_step1FormKey.currentState!.validate()) {
      _goToStep(1);
    }
  }

  void _goToStep3() {
    if (_step2FormKey.currentState!.validate()) {
      _goToStep(2);
    }
  }

  void _goToStep4() {
    _goToStep(3);
  }

  void _addExtraBranch() {
    setState(() {
      _extraBranches.add(_ExtraBranchDraft());
    });
  }

  void _removeExtraBranch(int index) {
    setState(() {
      _extraBranches[index].dispose();
      _extraBranches.removeAt(index);
    });
  }

  void _submit() async {
    if (_step4FormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final email = _emailController.text.trim();
      final isCreating = _clinicPath == 'create';

      final List<Map<String, String>> extraBranchesData = [];
      if (isCreating) {
        for (final b in _extraBranches) {
          final name = b.nameController.text.trim();
          if (name.isNotEmpty) {
            extraBranchesData.add({
              'name': name,
              'address': b.addressController.text.trim(),
              'phone': b.phoneController.text.trim(),
            });
          }
        }
      }

      await ref.read(loginControllerProvider.notifier).register(
            email: email,
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: isCreating ? 'doctor' : _selectedRole,
            clinicName: isCreating ? _clinicNameController.text.trim() : null,
            branchName: isCreating ? _mainBranchNameController.text.trim() : null,
            extraBranches: isCreating && extraBranchesData.isNotEmpty ? extraBranchesData : null,
            inviteCode: !isCreating ? _inviteCodeController.text.trim() : null,
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
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: isMobile ? 24 : 32),
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: isMobile ? 30 : 36,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: isMobile ? 20 : 22,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'انضم لمنصة عيادتي لإدارة مركزك الطبي وفروعه بسهولة',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: isMobile ? 12 : 13.5,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // شريط التقدّم لـ 4 مراحل
                        _buildStepProgressIndicator(theme, isMobile),
                        const SizedBox(height: 20),

                        // عرض محتوى المرحلة الحالية
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildCurrentStepContent(theme, loginState, isMobile),
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

  // محتوى المرحلة الحالية
  Widget _buildCurrentStepContent(ThemeData theme, LoginState loginState, bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Form(theme, isMobile);
      case 1:
        return _buildStep2Form(theme, isMobile);
      case 2:
        return _buildStep3Form(theme, isMobile);
      case 3:
      default:
        return _buildStep4Form(theme, loginState, isMobile);
    }
  }

  // شريط التراكم للمراحل الأربعة (1، 2، 3، 4)
  Widget _buildStepProgressIndicator(ThemeData theme, bool isMobile) {
    final steps = [
      {'title': 'البيانات'},
      {'title': 'الدخول'},
      {'title': 'المسار'},
      {'title': _clinicPath == 'create' ? 'العيادة' : 'الانضمام'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepNode(i, steps[i]['title']!, theme, isMobile),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: _currentStep > i
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, String title, ThemeData theme, bool isMobile) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isDone || isActive
              ? theme.colorScheme.primary
              : theme.disabledColor.withValues(alpha: 0.25),
          child: isDone
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 10.5 : 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? theme.colorScheme.primary
                : (isDone ? theme.textTheme.bodyLarge?.color : theme.hintColor),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المرحلة 1: البيانات الشخصية ورقم الهاتف
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1Form(ThemeData theme, bool isMobile) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'البيانات الشخصية ورقم التواصل',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // حقل الاسم الكامل
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل *',
              hintText: 'مثال: د. أحمد محمد',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الاسم الكامل';
              }
              if (value.trim().length < 3) {
                return 'الاسم قصير جداً (3 أحرف على الأقل)';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // حقل رقم الهاتف الشخصي / الواتساب
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _goToStep2(),
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف (الواتساب الشخصي) *',
              hintText: '01xxxxxxxxx',
              helperText: 'سُيستخدم لتواصل الإدارة وإرسال إشعارات الحساب المهمة',
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
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('المتابعة لحساب الدخول'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المرحلة 2: بيانات تسجيل الدخول (البريد وكلمة المرور)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2Form(ThemeData theme, bool isMobile) {
    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_person_rounded, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'بيانات الدخول وحماية الحساب',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // حقل البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني *',
              hintText: 'example@clinic.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال البريد الإلكتروني';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
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
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _goToStep3(),
            decoration: InputDecoration(
              labelText: 'كلمة المرور *',
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
                return 'كلمة المرور يجب أن تحتوي على حروف وأرقام معاً';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // زر المتابعة للمرحلة الثالثة
          ElevatedButton.icon(
            onPressed: _goToStep3,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('المتابعة لمسار العيادة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // زر العودة للمرحلة الأولى
          TextButton.icon(
            onPressed: () => _goToStep(0),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('الرجوع للبيانات ورقم الهاتف'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المرحلة 3: اختيار مسار العيادة (تأسيس عيادة أم انضمام لعيادة)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep3Form(ThemeData theme, bool isMobile) {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.alt_route_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'مسار العيادة في المنصة',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'حدد ما إذا كنت تؤسس عيادتك ومركزك الطبي الخاص، أم تنضم إلى فريق عمل عيادة قائمة بكود دعوة.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 16),

        if (_isInviteCodeLocked) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade700.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم فتح الرابط بكود دعوة (${_inviteCodeController.text}). يمكنك الانضمام مباشرة للعيادة.',
                    style: TextStyle(fontSize: 11.5, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],

        // خيار 1: تأسيس عيادة جديدة
        _buildPathSelectionCard(
          path: 'create',
          title: 'تأسيس عيادة جديدة (مالك العيادة)',
          subtitle: 'أنا صاحب المركز الطبي أو العيادة، وأرغب في تأسيس حساب عيادة وإضافة فروعها وإدارة الأطباء والموظفين.',
          icon: Icons.add_business_rounded,
          tags: const ['مالك العيادة', 'إدارة الفروع', 'تقارير كاملة'],
          theme: theme,
        ),
        const SizedBox(height: 12),

        // خيار 2: الانضمام لعيادة موجودة
        _buildPathSelectionCard(
          path: 'join',
          title: 'الانضمام لعيادة موجودة (كود دعوة)',
          subtitle: 'أنا طبيب معالج أو مساعد/سكرتير، ولدي كود دعوة من مدير العيادة للانضمام إلى فريق العمل.',
          icon: Icons.group_add_rounded,
          tags: const ['طبيب معالج', 'مساعد / سكرتير', 'ربط فوري'],
          theme: theme,
        ),
        const SizedBox(height: 22),

        // زر المتابعة للمرحلة الرابعة
        ElevatedButton.icon(
          onPressed: _goToStep4,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(_clinicPath == 'create' ? 'المتابعة لإعداد بيانات العيادة' : 'المتابعة لكود الانضمام'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),

        // زر العودة للمرحلة الثانية
        TextButton.icon(
          onPressed: () => _goToStep(1),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('الرجوع لبيانات الدخول'),
        ),
      ],
    );
  }

  Widget _buildPathSelectionCard({
    required String path,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> tags,
    required ThemeData theme,
  }) {
    final isSelected = _clinicPath == path;

    return InkWell(
      onTap: () {
        setState(() {
          _clinicPath = path;
          if (path == 'create') {
            _selectedRole = 'doctor';
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.hintColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.hintColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: isSelected
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المرحلة 4: تفاصيل العيادة والفروع أو كود الانضمام
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep4Form(ThemeData theme, LoginState loginState, bool isMobile) {
    return Form(
      key: _step4FormKey,
      child: Column(
        key: const ValueKey('step4'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_clinicPath == 'create')
            _buildCreateClinicStepContent(theme, isMobile)
          else
            _buildJoinClinicStepContent(theme, isMobile),

          const SizedBox(height: 22),

          // زر الإرسال النهائي والتسجيل
          ElevatedButton(
            onPressed: loginState.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: loginState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _clinicPath == 'create'
                        ? 'إنشاء الحساب وتأسيس العيادة 🚀'
                        : 'إنشاء الحساب والانضمام للعيادة 🚀',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
          const SizedBox(height: 10),

          // زر الرجوع للمرحلة الثالثة
          TextButton.icon(
            onPressed: () => _goToStep(2),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('الرجوع لتعديل مسار العيادة'),
          ),
        ],
      ),
    );
  }

  // محتوى مسار تأسيس العيادة وفروعها
  Widget _buildCreateClinicStepContent(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.apartment_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'بيانات المركز الطبي والفروع',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // اسم العيادة
        TextFormField(
          controller: _clinicNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'اسم العيادة / المركز الطبي *',
            hintText: 'مثال: مركز النخبة التخصصي',
            prefixIcon: Icon(Icons.business_rounded, size: 20),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال اسم العيادة أو المركز الطبي';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // اسم الفرع الرئيسي
        TextFormField(
          controller: _mainBranchNameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'اسم الفرع الرئيسي *',
            hintText: 'مثال: الفرع الرئيسي - مدينة نصر',
            helperText: 'الفرع الافتراضي الذي ستبدأ به العيادة (يمكن تعديله لاحقاً)',
            prefixIcon: Icon(Icons.store_mall_directory_rounded, size: 20),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال اسم الفرع الرئيسي';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // قسم الفروع الإضافية
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.share_location_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'فروع إضافية للعيادة (اختياري)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleSmall?.color,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _addExtraBranch,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('إضافة فرع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_extraBranches.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: theme.hintColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك البدء بالفرع الرئيسي فقط الآن، وإضافة فروع أخرى في أي وقت من الإعدادات.',
                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extraBranches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final branch = _extraBranches[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الفرع الإضافي رقم (${index + 1})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          onPressed: () => _removeExtraBranch(index),
                          tooltip: 'حذف الفرع',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: branch.nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم الفرع *',
                        hintText: 'مثال: فرع المهندسين',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'يرجى إدخال اسم الفرع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: branch.addressController,
                      decoration: InputDecoration(
                        labelText: 'العنوان (اختياري)',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // محتوى مسار الانضمام لعيادة قائمة
  Widget _buildJoinClinicStepContent(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.badge_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'بيانات الانضمام للعيادة',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // اختيار الدور (طبيب معالج أو مساعد)
        Text(
          'ما هو دورك في العيادة؟',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard('doctor', 'أنا طبيب معالج', Icons.medical_services_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRoleCard('secretary', 'أنا مساعد / سكرتير', Icons.badge_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // كود الدعوة
        if (_isInviteCodeLocked) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade700.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كود الدعوة مؤكد ومفعل',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'كود: ${_inviteCodeController.text}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ] else ...[
          TextFormField(
            controller: _inviteCodeController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: const InputDecoration(
              labelText: 'كود الدعوة من مدير العيادة *',
              hintText: 'مثال: ABC123XYZ',
              helperText: 'اطلب كود الدعوة من صاحب أو مدير العيادة للانضمام إلى فريقه',
              prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال كود الدعوة للانضمام للعيادة';
              }
              return null;
            },
          ),
        ],
      ],
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
