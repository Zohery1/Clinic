import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/appointment_type_model.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import 'widgets/appointment_patient_picker.dart';
import 'widgets/appointment_doctor_branch_picker.dart';
import 'widgets/appointment_type_picker.dart';
import 'widgets/appointment_time_picker.dart';
import 'widgets/appointment_services_picker.dart';

/// حوار حجز موعد جديد — متوافق مع الهاتف والويب
class BookAppointmentDialog extends ConsumerStatefulWidget {
  final String clinicId;
  final String? preselectedPatientId;

  const BookAppointmentDialog({
    super.key,
    required this.clinicId,
    this.preselectedPatientId,
  });

  @override
  ConsumerState<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends ConsumerState<BookAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedDoctorId;
  String? _selectedBranchId;
  String? _selectedAppointmentTypeId;
  double _basePrice = 0.0;
  final List<ServiceModel> _selectedServices = [];
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
    }
  }

  double get _totalPrice {
    final servicesTotal = _selectedServices.fold<double>(0.0, (sum, s) => sum + s.price);
    return _basePrice + servicesTotal;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مريض من القائمة'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appointmentDateTime = DateTime(
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
            appointmentDate: appointmentDateTime,
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
        final formattedTime = intl.DateFormat('hh:mm a', 'ar').format(appointmentDateTime);
        final patientName = _autocompleteController?.text ?? '';
        ref.read(notificationsProvider.notifier).sendBroadcastNotification(
          title: 'حجز جديد',
          body: 'تم إضافة حجز جديد للمريض ($patientName) الساعة $formattedTime',
          targetRole: 'doctor',
          playSound: false,
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حجز وتأكيد الموعد بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حجز الموعد: $e'),
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
        icon: Icons.calendar_today_rounded,
        title: 'حجز موعد جديد',
        subtitle: 'أدخل بيانات الموعد وحدد التاريخ والوقت المناسب',
        maxWidth: 580,
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. اختيار المريض
                AppointmentPatientPicker(
                  clinicId: widget.clinicId,
                  selectedPatientId: _selectedPatientId,
                  onPatientSelected: (patient) {
                    setState(() {
                      _selectedPatientId = patient?.id;
                    });
                  },
                  onControllerReady: (c) => _autocompleteController = c,
                ),
                const SizedBox(height: 14),

                // 2. الطبيب والفرع
                AppointmentDoctorBranchPicker(
                  clinicId: widget.clinicId,
                  selectedDoctorId: _selectedDoctorId,
                  selectedBranchId: _selectedBranchId,
                  onDoctorChanged: (docId) => setState(() => _selectedDoctorId = docId),
                  onBranchChanged: (bId) => setState(() => _selectedBranchId = bId),
                ),
                const SizedBox(height: 14),

                // 3. نوع الكشف
                AppointmentTypePicker(
                  selectedTypeId: _selectedAppointmentTypeId,
                  onTypeChanged: (type) {
                    setState(() {
                      _selectedAppointmentTypeId = type?.id;
                      _basePrice = type?.price ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // 4. اختيار التاريخ
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
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
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

                // 5. اختيار الوقت
                AppointmentTimePicker(
                  selectedTime: _selectedTime,
                  onTimeChanged: (t) => setState(() => _selectedTime = t),
                  existingAppointments: appointmentsForDayAsync.value ?? [],
                ),
                const SizedBox(height: 14),

                // 6. الخدمات الإضافية
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

                // 7. ملخص التكلفة
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
            label: _isSaving ? 'جاري الحفظ...' : 'تأكيد الحجز',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
