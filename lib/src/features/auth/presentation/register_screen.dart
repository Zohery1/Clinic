import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/layout/app_stepper.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/utils/invite_utils.dart';
import '../../../core/routing/routing.dart';
import 'login_controller.dart';
import 'register/register_state.dart';
import 'register/steps/step_identity.dart';
import 'register/steps/step_credentials.dart';
import 'register/steps/step_clinic_path.dart';
import 'register/steps/step_clinic_details.dart';

/// Clinical Utility Register Screen.
class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;
  const RegisterScreen({super.key, this.initialInviteCode});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const List<AppStepperStep> _steps = [
    AppStepperStep(
      title: 'البيانات الشخصية',
      description: 'الاسم والهاتف',
      icon: Icons.person_pin_rounded,
    ),
    AppStepperStep(
      title: 'بيانات الدخول',
      description: 'البريد وكلمة المرور',
      icon: Icons.lock_person_rounded,
    ),
    AppStepperStep(
      title: 'نوع الحساب',
      description: 'تأسيس أو انضمام',
      icon: Icons.alt_route_rounded,
    ),
    AppStepperStep(
      title: 'تفاصيل العيادة',
      description: 'المعلومات والفروع',
      icon: Icons.apartment_rounded,
    ),
  ];

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _mainBranchNameController = TextEditingController(text: 'الفرع الرئيسي');
  final _inviteCodeController = TextEditingController();

  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (_bootstrapped) return;
    _bootstrapped = true;
    String? code = widget.initialInviteCode;
    if (code == null || code.trim().isEmpty) {
      code = InviteUtils.extractInviteCode();
    }
    if (code != null && code.trim().isNotEmpty) {
      final clean = code.trim();
      _inviteCodeController.text = clean;
      ref.read(registerControllerProvider.notifier).lockInviteCode(clean);
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
    super.dispose();
  }

  void _goTo(int step) {
    ref.read(registerControllerProvider.notifier).setCurrentStep(step);
  }

  void _showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.danger,
        content: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _doFinalSubmit() async {
    final state = ref.read(registerControllerProvider);
    final loginNotifier = ref.read(loginControllerProvider.notifier);
    if (ref.read(loginControllerProvider).isLoading) return;

    final isCreating = state.clinicPath == 'create';
    final List<Map<String, String>> extras = [];
    if (isCreating) {
      for (final b in state.extraBranches) {
        final name = b.nameController.text.trim();
        if (name.isNotEmpty) {
          extras.add({
            'name': name,
            'address': b.addressController.text.trim(),
            'phone': b.phoneController.text.trim(),
          });
        }
      }
    }

    final email = _emailController.text.trim();

    await loginNotifier.register(
      email: email,
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: isCreating ? 'doctor' : state.selectedRole,
      clinicName: isCreating ? _clinicNameController.text.trim() : null,
      branchName: isCreating ? _mainBranchNameController.text.trim() : null,
      extraBranches: isCreating && extras.isNotEmpty ? extras : null,
      inviteCode: !isCreating ? _inviteCodeController.text.trim() : null,
    );

    if (!mounted) return;
    final after = ref.read(loginControllerProvider);
    if (!after.isSuccess) return;
    if (after.isEmailVerificationRequired) {
      AppNavigation.toVerifyOtp(context, email: email);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _currentStepWidget() {
    final state = ref.watch(registerControllerProvider);
    switch (state.currentStep) {
      case 0:
        return StepIdentity(
          fullNameController: _fullNameController,
          phoneController: _phoneController,
          onSubmit: () {},
        );
      case 1:
        return StepCredentials(
          emailController: _emailController,
          passwordController: _passwordController,
          onSubmit: () {},
          onBack: () => _goTo(0),
        );
      case 2:
        return StepClinicPath(
          onSubmit: () {},
          onBack: () => _goTo(1),
        );
      case 3:
      default:
        final login = ref.watch(loginControllerProvider);
        return StepClinicDetails(
          clinicNameController: _clinicNameController,
          mainBranchNameController: _mainBranchNameController,
          inviteCodeController: _inviteCodeController,
          isSubmitting: login.isLoading,
          onSubmit: _doFinalSubmit,
          onBack: () => _goTo(2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        _showError(context, next.errorMessage!);
      }
    });

    final state = ref.watch(registerControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthShell(
        heroTitle: 'عيادتي',
        heroSubtitle: 'المنظومة السحابية المتكاملة لإدارة الكشوفات والملفات الطبية.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إنشاء حساب جديد',
              style: AppTypography.headingMd(AppColors.textPrimary(context)),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'ابدأ بتسجيل بياناتك الطبية وتأسيس مساحة عمل عيادتك',
              style: AppTypography.bodySm(AppColors.textSecondary(context)),
            ),
            const SizedBox(height: AppSpace.lg),
            AppStepper(
              steps: _steps,
              currentIndex: state.currentStep,
              onStepTap: _goTo,
            ),
            const SizedBox(height: AppSpace.lg),
            _currentStepWidget(),
            const SizedBox(height: AppSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لديك حساب بالفعل؟',
                  style: AppTypography.bodySm(AppColors.textSecondary(context)),
                ),
                const SizedBox(width: AppSpace.xs),
                TextButton(
                  onPressed: () => AppNavigation.toLogin(context, replace: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'تسجيل الدخول',
                    style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
