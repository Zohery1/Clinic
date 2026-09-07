import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';

class ClinicDetailsPage extends ConsumerStatefulWidget {
  const ClinicDetailsPage({super.key});

  @override
  ConsumerState<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends ConsumerState<ClinicDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _doctorNameController.addListener(_onDoctorNameChanged);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _doctorNameController.text = user.fullName;
      _loadClinicName(user.clinicId);
    }
  }

  void _onDoctorNameChanged() {
    if (mounted) setState(() {});
  }

  void _loadClinicName(String clinicId) async {
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('name')
          .eq('id', clinicId)
          .single();
      _clinicNameController.text = res['name'] as String;
    } catch (_) {}
  }

  @override
  void dispose() {
    _doctorNameController.removeListener(_onDoctorNameChanged);
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        // تحديث اسم الطبيب
        await Supabase.instance.client
            .from('users')
            .update({'full_name': _doctorNameController.text.trim()})
            .eq('id', user.id);

        // تحديث اسم العيادة (للطبيب فقط)
        if (user.role == UserRole.doctor) {
          await Supabase.instance.client
              .from('clinics')
              .update({'name': _clinicNameController.text.trim()})
              .eq('id', user.clinicId);
        }

        // تحديث بروفايل المستخدم محلياً
        final updatedUser = await ref.read(authRepositoryProvider).getUserProfile(user.id);
        ref.read(currentUserProvider.notifier).state = updatedUser;

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text('تم حفظ البيانات بنجاح', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.success,
              ),
            );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text('خطأ أثناء الحفظ: $e', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.danger,
              ),
            );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = AppColors.isDark(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'بيانات العيادة والدكتور',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // معاينة اسم الطبيب باللقب
                if (user?.role == UserRole.doctor) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المعاينة في الروشتات والنظام:',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DoctorUtils.formatTitle(
                                  _doctorNameController.text.trim().isEmpty
                                      ? 'اسم الطبيب'
                                      : _doctorNameController.text.trim(),
                                ),
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],

                TextFormField(
                  controller: _doctorNameController,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    labelText: 'اسم الطبيب / المستخدم',
                    labelStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: AppSpace.lg),
                TextFormField(
                  controller: _clinicNameController,
                  enabled: user?.role == UserRole.doctor,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    labelText: 'اسم العيادة / المركز الطبي',
                    labelStyle: GoogleFonts.cairo(fontSize: 13),
                    prefixIcon: const Icon(Icons.business_rounded, color: AppColors.primary),
                    helperText: user?.role == UserRole.secretary
                        ? 'تنبيه: السكرتير لا يمكنه تغيير اسم العيادة'
                        : null,
                    helperStyle: GoogleFonts.cairo(fontSize: 11),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال اسم العيادة' : null,
                ),
                const SizedBox(height: AppSpace.xxxl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'حفظ البيانات',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
