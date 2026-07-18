import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/app_theme.dart';
import 'login_controller.dart';
import 'login_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // القراءة من الـ Query Parameter في حالة الويب لاستخراج كود الدعوة تلقائياً
    String? inviteCode = widget.initialInviteCode;
    try {
      final inviteParam = Uri.base.queryParameters['invite'];
      if (inviteParam != null && inviteParam.isNotEmpty) {
        inviteCode = inviteParam;
      }
    } catch (_) {}

    if (inviteCode != null && inviteCode.isNotEmpty) {
      _inviteCodeController.text = inviteCode;
      _selectedRole = 'secretary';
      _isInviteCodeLocked = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _inviteCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      await ref.read(loginControllerProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _fullNameController.text,
            role: _selectedRole,
            clinicName: _selectedRole == 'doctor' ? _clinicNameController.text : null,
            inviteCode: _selectedRole == 'secretary' ? _inviteCodeController.text : null,
          );

      final loginState = ref.read(loginControllerProvider);
      if (loginState.isSuccess && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final double innerPadding = mediaQuery.size.width < 400 ? 20.0 : 32.0;

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: EdgeInsets.symmetric(horizontal: innerPadding, vertical: 40),
                  decoration: AppTheme.cardDecoration(context).copyWith(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // شعار التطبيق
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'انضم لمنصة عيادتي لإدارة مركزك الطبي',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),

                        // اختيار نوع الحساب (طبيب أم سكرتير)
                        if (!_isInviteCodeLocked) ...[
                          LayoutBuilder(builder: (context, constraints) {
                            final useVertical = constraints.maxWidth < 340;
                            if (useVertical) {
                              return Column(
                                children: [
                                  _buildRoleCard('doctor', 'أنا طبيب', Icons.medical_services_outlined),
                                  const SizedBox(height: 12),
                                  _buildRoleCard('secretary', 'أنا مساعد/سكرتير', Icons.badge_outlined),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildRoleCard('doctor', 'أنا طبيب', Icons.medical_services_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildRoleCard('secretary', 'أنا مساعد/سكرتير', Icons.badge_outlined),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 20),
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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

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
                            if (value.length < 6) {
                              return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

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
                        ],

                        // حقل كود الدعوة (للسكرتيرة)
                        if (_selectedRole == 'secretary') ...[
                          TextFormField(
                            controller: _inviteCodeController,
                            enabled: !_isInviteCodeLocked,
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
                              helperText: _isInviteCodeLocked
                                  ? 'تم قفل الكود بناءً على رابط الدعوة المفتوح'
                                  : 'اطلب كود الدعوة من الطبيب للانضمام لعيادته',
                            ),
                            validator: (value) {
                              if (_selectedRole == 'secretary' && (value == null || value.trim().isEmpty)) {
                                return 'يرجى إدخال كود الدعوة للربط بالعيادة';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 28),

                        // زر إنشاء الحساب
                        ElevatedButton(
                          onPressed: loginState.isLoading ? null : _submit,
                          child: loginState.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                  ),
                                )
                              : const Text('إنشاء الحساب والبدء'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.2))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'أو سجّل عبر',
                                style: TextStyle(fontSize: 12, color: theme.hintColor),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.2))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: loginState.isLoading
                              ? null
                              : () => ref.read(loginControllerProvider.notifier).signInWithGoogle(),
                          icon: Icon(Icons.g_mobiledata_rounded, size: 32, color: theme.colorScheme.primary),
                          label: const Text('سجل حساباً باستخدام Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // رابط التوجيه لتسجيل الدخول
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(height: 8),
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
