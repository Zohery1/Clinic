import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/ui/primitives/app_button.dart';
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

/// نافذة حجز المواعيد فائقة السرعة (Express Clinical Intake Workspace)
/// تستبدل معالج الـ 6 خطوات السابق بنموذج استقبال تفاعلي متزامن
/// يدعم اختصارات لوحة المفاتيح والتحصيل والحجز الفوري في طابور اليوم.
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
      transitionDuration: const Duration(milliseconds: 240),
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
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
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
      _showError('يرجى اختيار مريض من القائمة أو تسجيل مريض جديد');
      return;
    }
    if (_selectedAppointmentTypeId == null) {
      _showError('يرجى اختيار نوع الكشف والزيارة');
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
                  'تم تسجيل حجز جديد للمريض ($patientName) الساعة $formattedTime',
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    // Auto-select first appointment type if none selected
    ref.watch(appointmentTypesProvider).whenData((types) {
      if (_selectedAppointmentTypeId == null && types.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedAppointmentTypeId == null) {
            setState(() {
              _selectedAppointmentTypeId = types.first.id;
              _basePrice = types.first.price;
            });
          }
        });
      }
    });

    final content = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
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
                _buildHeader(context, isMobile),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? AppSpace.md : AppSpace.xl),
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                child: _buildDoctorAndTimingSection(context),
                              ),
                            ],
                          ),
                  ),
                ),
                const Divider(height: 1),
                _buildFooter(context, isMobile),
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

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpace.md : AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtle(context).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'حجز كشف واستقبال سريع',
                      style: GoogleFonts.cairo(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Express Intake',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'تسجيل المريض وإضافته لطابور العيادة في خطوة واحدة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'إغلاق (Esc)',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary(context),
            ),
          ),
        ],
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
              '1. بيانات المريض',
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
              '2. نوع الكشف والزيارة',
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
    final formattedDate =
        intl.DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '3. الطبيب المعالج والفرع',
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
        Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '4. التوقيت وحالة الانتظار',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.subtle(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    _isWalkInNow = true;
                    _selectedDate = DateTime.now();
                    _selectedTime = TimeOfDay.now();
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isWalkInNow
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          size: 16,
                          color: _isWalkInNow
                              ? Colors.white
                              : AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'طابور الانتظار الآن (Walk-in)',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isWalkInNow
                                ? Colors.white
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isWalkInNow = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isWalkInNow
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: !_isWalkInNow
                              ? Colors.white
                              : AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'موعد محدد لاحقاً',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !_isWalkInNow
                                ? Colors.white
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_isWalkInNow) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.borderSubtle(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (t != null) setState(() => _selectedTime = t);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.borderSubtle(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
              'خدمات إضافية (اختياري)',
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

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpace.md : AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtle(context).withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المطلوب تحصيله: ',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.subtle(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ctrl + Enter للحفظ السريع',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
          ],
          AppButton(
            label: 'إلغاء',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: 'تأكيد الحجز فوراً',
            icon: Icons.check_rounded,
            variant: AppButtonVariant.primary,
            expand: false,
            loading: _isSaving,
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
