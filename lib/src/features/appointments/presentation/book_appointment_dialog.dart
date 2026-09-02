import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/ui/layout/app_stepper.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/motion.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../../reports/presentation/reports_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_type_model.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import 'widgets/book_appointment/steps/step_appointment_type.dart';
import 'widgets/book_appointment/steps/step_date_time.dart';
import 'widgets/book_appointment/steps/step_doctor_branch.dart';
import 'widgets/book_appointment/steps/step_patient.dart';
import 'widgets/book_appointment/steps/step_services.dart';
import 'widgets/book_appointment/steps/step_summary.dart';

/// Multi-step booking dialog. Uses [AppStepper] for navigation and a
/// footer with "السابق" / "التالي" buttons that becomes "تأكيد الحجز"
/// on the final step.
class BookAppointmentDialog extends ConsumerStatefulWidget {
  final String clinicId;
  final String? preselectedPatientId;

  const BookAppointmentDialog({
    super.key,
    required this.clinicId,
    this.preselectedPatientId,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String clinicId,
    String? preselectedPatientId,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'حجز موعد جديد',
      barrierColor: Colors.black.withValues(alpha: 0.40),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve =
            CurvedAnimation(parent: anim1, curve: AppMotion.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * curve.value,
            sigmaY: 8.0 * curve.value,
          ),
          child: FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => BookAppointmentDialog(
        clinicId: clinicId,
        preselectedPatientId: preselectedPatientId,
      ),
    );
  }

  @override
  ConsumerState<BookAppointmentDialog> createState() =>
      _BookAppointmentDialogState();
}

class _BookAppointmentDialogState
    extends ConsumerState<BookAppointmentDialog> {
  int _step = 0;
  bool _isSaving = false;

  String? _selectedPatientId;
  TextEditingController? _autocompleteController;

  String? _selectedDoctorId;
  String? _selectedBranchId;

  String? _selectedAppointmentTypeId;
  double _basePrice = 0.0;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  final List<ServiceModel> _selectedServices = [];

  static const _steps = <AppStepperStep>[
    AppStepperStep(
      title: 'نوع الكشف',
      description: 'اختر نوع الزيارة',
      icon: Icons.medical_information_outlined,
    ),
    AppStepperStep(
      title: 'المريض',
      description: 'اختر المريض',
      icon: Icons.person_outline_rounded,
    ),
    AppStepperStep(
      title: 'الطبيب والفرع',
      description: 'تعيين الطبيب والفرع',
      icon: Icons.person_pin_outlined,
    ),
    AppStepperStep(
      title: 'الموعد',
      description: 'التاريخ والوقت',
      icon: Icons.calendar_today_rounded,
    ),
    AppStepperStep(
      title: 'الخدمات',
      description: 'خدمات إضافية',
      icon: Icons.medical_services_outlined,
    ),
    AppStepperStep(
      title: 'تأكيد',
      description: 'مراجعة وإنهاء',
      icon: Icons.check_circle_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
    }
  }

  AppointmentTypeModel? _resolveSelectedType(
      List<AppointmentTypeModel> types) {
    if (_selectedAppointmentTypeId == null) return null;
    for (final t in types) {
      if (t.id == _selectedAppointmentTypeId) return t;
    }
    return null;
  }

  bool _canAdvance() {
    switch (_step) {
      case 0:
        return _selectedAppointmentTypeId != null;
      case 1:
        return _selectedPatientId != null;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    if (_selectedPatientId == null) {
      _showError('يرجى اختيار مريض من القائمة');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await ref.read(appointmentRepositoryProvider).bookAppointment(
            clinicId: widget.clinicId,
            branchId: _selectedBranchId,
            patientId: _selectedPatientId!,
            doctorId: _selectedDoctorId,
            appointmentTypeId: _selectedAppointmentTypeId,
            appointmentDate: dt,
            priceCharged: _basePrice,
            selectedServices: _selectedServices,
          );
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(appointmentsForDateProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);
      ref.invalidate(weeklyRevenueProvider);
      ref.invalidate(sixWeeksRevenueProvider);
      ref.invalidate(monthlyStatsProvider);
      ref.invalidate(dailyStatsProvider);
      ref.invalidate(detailedReportProvider);
      try {
        final formattedTime = intl.DateFormat('hh:mm a', 'ar').format(dt);
        final patientName = _autocompleteController?.text ?? '';
        ref.read(notificationsProvider.notifier).sendBroadcastNotification(
              title: 'حجز جديد',
              body:
                  'تم إضافة حجز جديد للمريض ($patientName) الساعة $formattedTime',
              targetRole: 'doctor',
              playSound: false,
            );
      } catch (_) {}
      if (!mounted) return;
      _showSuccess('تم حجز وتأكيد الموعد بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ أثناء حجز الموعد: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStepContent() {
    final typesAsync = ref.watch(appointmentTypesProvider);
    final types = typesAsync.value ?? const <AppointmentTypeModel>[];
    final selectedType = _resolveSelectedType(types);
    switch (_step) {
      case 0:
        return StepAppointmentType(
          selectedTypeId: _selectedAppointmentTypeId,
          onChanged: (AppointmentTypeModel? t) {
            setState(() {
              _selectedAppointmentTypeId = t?.id;
              _basePrice = t?.price ?? 0.0;
            });
          },
        );
      case 1:
        return StepPatient(
          clinicId: widget.clinicId,
          selectedPatientId: _selectedPatientId,
          onChanged: (id) => setState(() => _selectedPatientId = id),
          onControllerReady: (c) => _autocompleteController = c,
        );
      case 2:
        return StepDoctorBranch(
          clinicId: widget.clinicId,
          selectedDoctorId: _selectedDoctorId,
          selectedBranchId: _selectedBranchId,
          onDoctorChanged: (id) => setState(() => _selectedDoctorId = id),
          onBranchChanged: (id) => setState(() => _selectedBranchId = id),
        );
      case 3:
        return StepDateTime(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          onTimeChanged: (t) => setState(() => _selectedTime = t),
        );
      case 4:
        return StepServices(
          clinicId: widget.clinicId,
          selectedServices: _selectedServices,
          onChanged: (list) {
            setState(() {
              _selectedServices
                ..clear()
                ..addAll(list);
            });
          },
        );
      case 5:
        return StepSummary(
          clinicId: widget.clinicId,
          patientId: _selectedPatientId,
          patientName: _autocompleteController?.text,
          doctorName: null,
          branchName: null,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedType: selectedType,
          selectedServices: _selectedServices,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 720;
    final isLast = _step == _steps.length - 1;
    final canAdvance = _canAdvance();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 16 : 28,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 880,
              maxHeight: size.height * 0.92,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppRadii.radiusXl),
                border: Border.all(color: AppColors.borderSubtle(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                  _Header(
                    title: 'حجز موعد جديد',
                    subtitle: 'أدخل بيانات الموعد وحدد التاريخ والوقت المناسب',
                    onClose: () => Navigator.pop(context),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: isMobile
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpace.lg),
                                child: AppStepper(
                                  steps: _steps,
                                  currentIndex: _step,
                                  onStepTap: (i) {
                                    if (i <= _step) {
                                      setState(() => _step = i);
                                    }
                                  },
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(AppSpace.lg),
                                  child: _buildStepContent(),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 220,
                                padding: const EdgeInsets.all(AppSpace.lg),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.borderSubtle(context),
                                    ),
                                  ),
                                ),
                                child: AppStepper(
                                  steps: _steps,
                                  currentIndex: _step,
                                  onStepTap: (i) {
                                    if (i <= _step) {
                                      setState(() => _step = i);
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(AppSpace.xl),
                                  child: _buildStepContent(),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_step > 0)
                          AppButton(
                            label: 'السابق',
                            icon: Icons.chevron_right_rounded,
                            variant: AppButtonVariant.ghost,
                            expand: false,
                            onPressed:
                                _isSaving ? null : () => setState(() => _step -= 1),
                          )
                        else
                          AppButton(
                            label: 'إلغاء',
                            variant: AppButtonVariant.ghost,
                            expand: false,
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        AppButton(
                          label: isLast ? 'تأكيد الحجز' : 'التالي',
                          icon: isLast
                              ? Icons.check_rounded
                              : Icons.chevron_left_rounded,
                          variant: AppButtonVariant.primary,
                          expand: false,
                          loading: _isSaving,
                          onPressed: (_isSaving || !canAdvance)
                              ? null
                              : () {
                                  if (isLast) {
                                    _submit();
                                  } else {
                                    setState(() => _step += 1);
                                  }
                                },
                        ),
                      ],
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

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppRadii.radiusMd),
            ),
            child: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}