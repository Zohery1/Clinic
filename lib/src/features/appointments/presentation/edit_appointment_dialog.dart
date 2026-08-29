import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/double_bezel_card.dart';
import '../../../core/widgets/magnetic_nested_button.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import 'widgets/appointment_doctor_branch_picker.dart';
import 'widgets/appointment_type_picker.dart';
import 'widgets/appointment_time_picker.dart';
import 'widgets/appointment_services_picker.dart';

/// حوار تعديل موعد قائم بنظام Soft Structuralism Single-Page Floating Sheet
/// مع تصميم Double-Bezel فائق الجودة وزر MagneticNestedButton الأساسي.
class EditAppointmentDialog extends ConsumerStatefulWidget {
  final String clinicId;
  final AppointmentModel appointment;

  const EditAppointmentDialog({
    super.key,
    required this.clinicId,
    required this.appointment,
  });

  /// Helper لإظهار الحوار مع تأثير ضبابي شفاف في الخلفية (Backdrop Blur)
  static Future<T?> show<T>({
    required BuildContext context,
    required String clinicId,
    required AppointmentModel appointment,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'تعديل الموعد',
      barrierColor: Colors.black.withValues(alpha: 0.40),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: AppMotion.curve);
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
      pageBuilder: (ctx, anim1, anim2) => EditAppointmentDialog(
        clinicId: clinicId,
        appointment: appointment,
      ),
    );
  }

  @override
  ConsumerState<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends ConsumerState<EditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDoctorId;
  String? _selectedBranchId;
  String? _selectedAppointmentTypeId;
  double _priceCharged = 0.0;
  final List<ServiceModel> _selectedServices = [];
  bool _isSaving = false;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.appointment.doctorId;
    _selectedBranchId = widget.appointment.branchId;
    _selectedAppointmentTypeId = widget.appointment.appointmentTypeId;
    _selectedDate = widget.appointment.appointmentDate.toLocal();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _priceCharged = widget.appointment.priceCharged ?? 0.0;
    _loadExistingServices();
  }

  Future<void> _loadExistingServices() async {
    try {
      final apptServices = await ref
          .read(appointmentRepositoryProvider)
          .getAppointmentServices(widget.appointment.id);
      if (apptServices.isNotEmpty && mounted) {
        setState(() {
          _selectedServices.addAll(
            apptServices
                .map(
                  (as) => ServiceModel(
                    id: as.serviceId ?? '',
                    clinicId: widget.clinicId,
                    name: as.serviceName ?? 'خدمة إضافية',
                    price: as.priceCharged,
                  ),
                )
                .toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to load existing services: $e');
    }
  }

  double get _totalPrice {
    final servicesTotal = _selectedServices.fold<double>(0.0, (sum, s) => sum + s.price);
    return _priceCharged + servicesTotal;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ref.read(appointmentRepositoryProvider).updateAppointment(
            appointmentId: widget.appointment.id,
            patientId: widget.appointment.patientId,
            clinicId: widget.clinicId,
            branchId: _selectedBranchId,
            doctorId: _selectedDoctorId,
            appointmentTypeId: _selectedAppointmentTypeId,
            appointmentDate: appointmentDateTime,
            priceCharged: _priceCharged,
            selectedServices: _selectedServices,
          );

      // Invalidate all 9 required providers
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
        final formattedTime = intl.DateFormat('hh:mm a', 'ar').format(appointmentDateTime);
        ref.read(notificationsProvider.notifier).sendBroadcastNotification(
          title: 'تعديل موعد',
          body: 'تم تعديل موعد المريض (${widget.appointment.patient.fullName}) إلى الساعة $formattedTime',
          targetRole: 'doctor',
          playSound: false,
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تم تحديث الموعد بنجاح',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'حدث خطأ أثناء تعديل الموعد: $e',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: theme.dividerColor.withValues(alpha: 0.4),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsForDayAsync = ref.watch(
      appointmentsForDateProvider(_selectedDate),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;

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
              maxWidth: 600,
              maxHeight: size.height * 0.90,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(3.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle on Mobile
                    if (isMobile) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],

                    // ─── Header ───
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 22,
                        isMobile ? 12 : 20,
                        isMobile ? 16 : 22,
                        isMobile ? 10 : 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  AppColors.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit_calendar_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'تعديل الموعد',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                                ),
                                Text(
                                  'المريض: ${widget.appointment.patient.fullName}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDimDark
                                    : AppColors.surfaceDimLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // ─── Scrollable Form Content (4 Sections) ───
                    Flexible(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 22,
                            16,
                            isMobile ? 16 : 22,
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // SECTION 1: بيانات المريض والعيادة
                              _buildSectionHeader(
                                icon: Icons.person_outline_rounded,
                                title: 'بيانات المريض والعيادة',
                                context: context,
                              ),
                              // Patient summary badge
                              DoubleBezelCard(
                                outerRadius: 14,
                                innerRadius: 11.5,
                                outerPadding: const EdgeInsets.all(2),
                                innerPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.appointment.patient.fullName.isNotEmpty
                                              ? widget.appointment.patient.fullName.trim().substring(0, 1)
                                              : 'م',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.appointment.patient.fullName,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                          if (widget.appointment.patient.phone != null &&
                                              widget.appointment.patient.phone!.isNotEmpty)
                                            Text(
                                              widget.appointment.patient.phone!,
                                              style: GoogleFonts.cairo(
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDimDark
                                            : AppColors.surfaceDimLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'مريض مسجل',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              AppointmentDoctorBranchPicker(
                                clinicId: widget.clinicId,
                                selectedDoctorId: _selectedDoctorId,
                                selectedBranchId: _selectedBranchId,
                                onDoctorChanged: (docId) =>
                                    setState(() => _selectedDoctorId = docId),
                                onBranchChanged: (bId) =>
                                    setState(() => _selectedBranchId = bId),
                              ),
                              const SizedBox(height: 20),

                              // SECTION 2: تفاصيل الموعد والوقت
                              _buildSectionHeader(
                                icon: Icons.access_time_filled_rounded,
                                title: 'تفاصيل الموعد والتوقيت',
                                context: context,
                              ),
                              AppointmentTypePicker(
                                selectedTypeId: _selectedAppointmentTypeId,
                                onTypeChanged: (type) {
                                  setState(() {
                                    _selectedAppointmentTypeId = type?.id;
                                    if (type != null) {
                                      _priceCharged = type.price;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 14),

                              // اختيار التاريخ بنظام Tactile Card
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        size: 15,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'تاريخ الموعد *',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
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
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDimDark
                                            : AppColors.surfaceDimLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.calendar_month_rounded,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              intl.DateFormat('EEEE، d MMMM yyyy', 'ar')
                                                  .format(_selectedDate),
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: theme.hintColor,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              AppointmentTimePicker(
                                selectedTime: _selectedTime,
                                onTimeChanged: (t) => setState(() => _selectedTime = t),
                                existingAppointments: (appointmentsForDayAsync.value ?? [])
                                    .where((a) => a.id != widget.appointment.id)
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              // SECTION 3: الخدمات الطبية الإضافية
                              _buildSectionHeader(
                                icon: Icons.medical_services_outlined,
                                title: 'الخدمات الطبية الإضافية',
                                context: context,
                              ),
                              AppointmentServicesPicker(
                                clinicId: widget.clinicId,
                                selectedServices: _selectedServices,
                                onServicesChanged: (services) {
                                  setState(() {
                                    _selectedServices.clear();
                                    _selectedServices.addAll(services);
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // SECTION 4: ملخص التكلفة والتأكيد
                              _buildSectionHeader(
                                icon: Icons.receipt_long_rounded,
                                title: 'ملخص التكلفة',
                                context: context,
                              ),
                              DoubleBezelCard(
                                outerRadius: 16,
                                innerRadius: 13.5,
                                outerPadding: const EdgeInsets.all(2),
                                innerPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'إجمالي المبلغ المستحق',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          'يشمل الكشف والخدمات الإضافية المختارة',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: isDark ? 0.25 : 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_totalPrice.toStringAsFixed(0)} ج.م',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // ─── Actions Bar with MagneticNestedButton CTA ───
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 22,
                        12,
                        isMobile ? 16 : 22,
                        isMobile ? 14 : 18,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Secondary Cancel Button
                          TextButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),

                          // Primary Magnetic Nested CTA
                          MagneticNestedButton(
                            label: 'حفظ التعديلات',
                            loadingLabel: 'جاري الحفظ...',
                            icon: Icons.check_rounded,
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _submit,
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
      ),
    );
  }
}
