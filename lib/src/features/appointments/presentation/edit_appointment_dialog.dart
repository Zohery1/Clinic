import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clinic_dialog.dart';
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

/// حوار تعديل موعد قائم — متوافق مع الهاتف والويب
class EditAppointmentDialog extends ConsumerStatefulWidget {
  final String clinicId;
  final AppointmentModel appointment;

  const EditAppointmentDialog({
    super.key,
    required this.clinicId,
    required this.appointment,
  });

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
            clinicId: widget.clinicId,
            branchId: _selectedBranchId,
            doctorId: _selectedDoctorId,
            appointmentTypeId: _selectedAppointmentTypeId,
            appointmentDate: appointmentDateTime,
            priceCharged: _priceCharged,
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
          const SnackBar(
            content: Text('تم تحديث الموعد بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تعديل الموعد: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsForDayAsync = ref.watch(
      appointmentsForDateProvider(
        intl.DateFormat('yyyy-MM-dd').format(_selectedDate),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClinicDialog(
        icon: Icons.edit_calendar_rounded,
        title: 'تعديل الموعد',
        subtitle: 'المريض: ${widget.appointment.patient.fullName}',
        maxWidth: 580,
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. الطبيب والفرع
                AppointmentDoctorBranchPicker(
                  clinicId: widget.clinicId,
                  selectedDoctorId: _selectedDoctorId,
                  selectedBranchId: _selectedBranchId,
                  onDoctorChanged: (docId) => setState(() => _selectedDoctorId = docId),
                  onBranchChanged: (bId) => setState(() => _selectedBranchId = bId),
                ),
                const SizedBox(height: 14),

                // 2. نوع الكشف
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

                // 3. اختيار التاريخ
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الموعد *',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined,
                                      size: 18, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. اختيار الوقت
                AppointmentTimePicker(
                  selectedTime: _selectedTime,
                  onTimeChanged: (t) => setState(() => _selectedTime = t),
                  existingAppointments: (appointmentsForDayAsync.value ?? [])
                      .where((a) => a.id != widget.appointment.id)
                      .toList(),
                ),
                const SizedBox(height: 14),

                // 5. الخدمات الإضافية
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
                const SizedBox(height: 16),

                // 6. ملخص التكلفة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجمالي المبلغ المستحق:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ClinicSecondaryButton(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(context),
          ),
          ClinicPrimaryButton(
            label: _isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
