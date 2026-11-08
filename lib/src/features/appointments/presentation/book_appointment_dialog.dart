import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/motion.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../../reports/presentation/reports_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import 'widgets/appointment_doctor_branch_picker.dart';
import 'widgets/appointment_patient_picker.dart';
import 'widgets/appointment_services_picker.dart';
import 'widgets/appointment_type_picker.dart';
import 'widgets/book_appointment/book_appointment_footer.dart';
import 'widgets/book_appointment/book_appointment_header.dart';
import 'widgets/book_appointment/book_appointment_timing_section.dart';

/// نافذة حجز واستقبال المواعيد السريعة (Express Clinical Intake Workspace).
/// توفر تجربة استقبال سريرية تفاعلية متزامنة، مع دعم اختصارات لوحة المفاتيح
/// والتحصيل التلقائي، واختيار الخدمات الإضافية، وإضافة المريض لطابور اليوم فوراً.
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
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 140),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve =
            CurvedAnimation(parent: anim1, curve: AppMotion.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
            child: child,
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
  bool _isSaving = false;
  bool _isWalkInNow = true;

  String? _selectedPatientId;
  TextEditingController? _autocompleteController;

  String? _selectedDoctorId;
  String? _selectedBranchId;

  String? _selectedAppointmentTypeId;
  double _basePrice = 0.0;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<ServiceModel> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
    }
    final initialTypes = ref.read(appointmentTypesProvider).value;
    if (initialTypes != null && initialTypes.isNotEmpty) {
      _selectedAppointmentTypeId = initialTypes.first.id;
      _basePrice = initialTypes.first.price;
    }
  }

  double get _totalPrice {
    final servicesSum = _selectedServices.fold<double>(
      0.0,
      (acc, s) => acc + s.price,
    );
    return _basePrice + servicesSum;
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_selectedPatientId == null) {
      _showError('اختر المريض أولاً أو سجّل مريضاً جديداً');
      return;
    }
    if (_selectedAppointmentTypeId == null) {
      _showError('حدد نوع الكشف للمتابعة');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final dt = _isWalkInNow
          ? now
          : DateTime(
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

      // تحديث وإلغاء المزودات لمزامنة الجداول والتقارير المالية اليومية
      invalidateAppointmentsAndReports(ref, refreshFullReports: false);

      try {
        final formattedTime = intl.DateFormat('hh:mm a', 'ar').format(dt);
        final patientName = _autocompleteController?.text ?? '';
        ref.read(notificationsProvider.notifier).sendBroadcastNotification(
              title: 'حجز جديد',
              body:
                  'تم تسجيل حجز جديد للمريض ($patientName) الساعة $formattedTime',
              targetRole: 'doctor',
              playSound: false,
            );
      } catch (_) {}

      if (!mounted) return;
      _showSuccess('تم تأكيد الحجز بنجاح');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showError('تعذر تسجيل الحجز، يرجى إعادة المحاولة');
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

  Widget _buildPatientAndTypeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'بيانات المريض',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppointmentPatientPicker(
          clinicId: widget.clinicId,
          selectedPatientId: _selectedPatientId,
          onPatientSelected: (p) => setState(() => _selectedPatientId = p?.id),
          onControllerReady: (c) => _autocompleteController = c,
        ),
        const SizedBox(height: AppSpace.xl),
        Row(
          children: [
            const Icon(Icons.medical_information_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'نوع الكشف',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppointmentTypePicker(
          selectedTypeId: _selectedAppointmentTypeId,
          onTypeChanged: (t) {
            setState(() {
              _selectedAppointmentTypeId = t?.id;
              _basePrice = t?.price ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDoctorAndTimingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'الطبيب والفرع',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppointmentDoctorBranchPicker(
          clinicId: widget.clinicId,
          selectedDoctorId: _selectedDoctorId,
          selectedBranchId: _selectedBranchId,
          onDoctorChanged: (id) => setState(() => _selectedDoctorId = id),
          onBranchChanged: (id) => setState(() => _selectedBranchId = id),
        ),
        const SizedBox(height: AppSpace.xl),
        BookAppointmentTimingSection(
          isWalkInNow: _isWalkInNow,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onWalkInChanged: (val) {
            setState(() {
              _isWalkInNow = val;
              if (val) {
                _selectedDate = DateTime.now();
                _selectedTime = TimeOfDay.now();
              }
            });
          },
          onDateChanged: (dt) => setState(() => _selectedDate = dt),
          onTimeChanged: (t) => setState(() => _selectedTime = t),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'خدمات وإجراءات إضافية (اختياري)',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppointmentServicesPicker(
          clinicId: widget.clinicId,
          selectedServices: _selectedServices,
          onServicesChanged: (list) {
            setState(() {
              _selectedServices
                ..clear()
                ..addAll(list);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    // الاستماع لتحديثات أنواع الكشوفات والتحديد التلقائي
    ref.listen(appointmentTypesProvider, (prev, next) {
      next.whenData((types) {
        if (mounted && _selectedAppointmentTypeId == null && types.isNotEmpty) {
          setState(() {
            _selectedAppointmentTypeId = types.first.id;
            _basePrice = types.first.price;
          });
        }
      });
    });

    final content = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 28,
            vertical: isMobile ? 16 : 32,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 880, maxHeight: 780),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppRadii.radiusXl),
              border: Border.all(color: AppColors.borderSubtle(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BookAppointmentHeader(
                  isMobile: isMobile,
                  onClose: () => Navigator.pop(context),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.all(isMobile ? AppSpace.md : AppSpace.xl),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPatientAndTypeSection(context),
                              const SizedBox(height: AppSpace.xl),
                              _buildDoctorAndTimingSection(context),
                              const SizedBox(height: AppSpace.xl),
                              _buildServicesSection(context),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildPatientAndTypeSection(context),
                                    const SizedBox(height: AppSpace.xl),
                                    _buildServicesSection(context),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpace.xl),
                              Container(
                                width: 1,
                                height: 480,
                                color: AppColors.borderSubtle(context),
                              ),
                              const SizedBox(width: AppSpace.xl),
                              Expanded(
                                flex: 5,
                                child:
                                    _buildDoctorAndTimingSection(context),
                              ),
                            ],
                          ),
                  ),
                ),
                const Divider(height: 1),
                BookAppointmentFooter(
                  isMobile: isMobile,
                  totalPrice: _totalPrice,
                  isSaving: _isSaving,
                  onCancel: () => Navigator.pop(context),
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: content,
    );
  }
}
