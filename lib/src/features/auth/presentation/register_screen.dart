import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/layout/app_stepper.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/motion.dart';
import '../../../core/utils/invite_utils.dart';
import 'login_controller.dart';
import 'login_screen.dart';
import 'verify_otp_screen.dart';
import 'register/register_state.dart';
import 'register/steps/step_identity.dart';
import 'register/steps/step_credentials.dart';
import 'register/steps/step_clinic_path.dart';
import 'register/steps/step_clinic_details.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;
  const RegisterScreen({super.key, this.initialInviteCode});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const List<AppStepperStep> _steps = [
    AppStepperStep(
      title: 'البيانات',
      description: 'الاسم ورقم التواصل',
      icon: Icons.person_pin_rounded,
    ),
    AppStepperStep(
      title: 'الدخول',
      description: 'البريد وكلمة المرور',
      icon: Icons.lock_person_rounded,
    ),
    AppStepperStep(
      title: 'المسار',
      description: 'تأسيس أو انضمام',
      icon: Icons.alt_route_rounded,
    ),
    AppStepperStep(
      title: 'العيادة',
      description: 'التفاصيل والفروع',
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerifyOtpScreen(email: email)),
      );
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
    final showMobileLogo = MediaQuery.of(context).size.width < 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthShell(
        heroTitle: 'انضم إلى عيادتي',
        heroSubtitle:
            'منصة موحدة لإدارة عيادتك وفروعها وأطبائك — بتجربة استخدام احترافية وبيانات آمئة.',
        heroBullets: const [
          AuthHeroBullet(
              icon: Icons.shield_outlined,
              text: 'موثوق وآمن لتخزين بيانات المرضى'),
          AuthHeroBullet(
              icon: Icons.notifications_active_outlined,
              text: 'تذكيرات واتساب تلقائية بدون كود'),
          AuthHeroBullet(
              icon: Icons.business_rounded,
              text: 'يدعم عدة فروع وأطباء في عيادة واحدة'),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMobileLogo) ...[
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadii.brMd,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            Text(
              'إنشاء حساب جديد',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'انضم لمنصة عيادتي لإدارة مركزك الطبي وفروعه بسهولة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            AppStepper(
              steps: _steps,
              currentIndex: state.currentStep,
              onStepTap: _goTo,
            ),
            const SizedBox(height: AppSpace.xl),
            AnimatedSwitcher(
              duration: AppMotion.normal,
              switchInCurve: AppMotion.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey('step-${state.currentStep}'),
                child: _currentStepWidget(),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'لديك حساب بالفعل؟',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
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