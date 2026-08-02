import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../patients/data/patient_repository.dart';
import '../../patients/domain/patient_model.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/appointment_type_model.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../../core/widgets/clinic_dialog.dart';

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
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => Theme.of(context).textTheme.bodyLarge?.color ?? (_isDark ? Colors.white : const Color(0xFF1E293B));
  Color get _textSecColor => Theme.of(context).textTheme.bodySmall?.color ?? (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
  Color get _borderCol => Colors.transparent;
  Color get _inputFillCol => Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
  Color get _surfaceCol => Theme.of(context).colorScheme.surface;
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _errorColor => Theme.of(context).colorScheme.error;

  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedAppointmentTypeId;
  double _priceCharged = 0.0;
  final List<ServiceModel> _selectedServices = [];
  bool _isSaving = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0); // Default to 6:00 PM

  TextEditingController? _autocompleteController;
  final _customTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
    }
    _customTimeController.text = _formatTimeOfDay(_selectedTime);
  }

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  List<String> get _allTimeSlots {
    final List<String> slots = [];
    
    // 7:00 AM to 11:30 AM
    for (int hour = 7; hour <= 11; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00 AM');
      slots.add('${hour.toString().padLeft(2, '0')}:30 AM');
    }
    
    // 12:00 PM to 11:30 PM
    slots.add('12:00 PM');
    slots.add('12:30 PM');
    for (int hour = 1; hour <= 11; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00 PM');
      slots.add('${hour.toString().padLeft(2, '0')}:30 PM');
    }
    
    // 12:00 AM to 2:00 AM (next day early morning slots)
    slots.add('12:00 AM');
    slots.add('12:30 AM');
    slots.add('01:00 AM');
    slots.add('01:30 AM');
    slots.add('02:00 AM');
    
    return slots;
  }

  TimeOfDay _parseSlotTime(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts[1] == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isSlotBooked(String slot, List<AppointmentModel> appointments) {
    final slotTime = _parseSlotTime(slot);
    return appointments.any((app) {
      final appTime = TimeOfDay.fromDateTime(app.appointmentDate.toLocal());
      return appTime.hour == slotTime.hour && appTime.minute == slotTime.minute;
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      if (_selectedPatientId == null) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(duration: Duration(seconds: 2), 
            content: Text('يرجى اختيار مريض من القائمة'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      double basePrice = 0.0;
      if (_selectedAppointmentTypeId != null) {
        final types = ref.read(appointmentTypesProvider).value;
        if (types != null) {
          final type = types.firstWhere(
            (t) => t.id == _selectedAppointmentTypeId,
            orElse: () => AppointmentTypeModel(id: '', clinicId: '', name: '', price: 0.0),
          );
          basePrice = type.price;
        }
      }

      await ref.read(appointmentRepositoryProvider).bookAppointment(
            clinicId: widget.clinicId,
            patientId: _selectedPatientId!,
            appointmentTypeId: _selectedAppointmentTypeId,
            appointmentDate: appointmentDateTime,
            priceCharged: basePrice,
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

      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(duration: Duration(seconds: 2), 
            content: Text('تم حجز وتأكيد الموعد بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
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

  void _showAddPatientDialog(BuildContext context, String initialName, TextEditingController autocompleteController) {
    final addPatientFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final ageController = TextEditingController();
    final medicalHistoryController = TextEditingController();
    String? selectedGender;

    ClinicDialog.show(
      context: context,
      icon: Icons.person_add_alt_1_rounded,
      title: 'تسجيل مريض جديد سريع',
      subtitle: 'سيتم تسجيل المريض وتحديده تلقائياً في نافذة الحجز',
      maxWidth: 480,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: addPatientFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                ClinicFormField(
                  label: 'الاسم الكامل للمريض',
                  hint: 'مثال: محمد أحمد علي',
                  prefixIcon: Icons.person_outline,
                  controller: nameController,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'رقم الهاتف',
                  hint: 'مثال: 01012345678',
                  prefixIcon: Icons.phone_outlined,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClinicFormField(
                        label: 'العمر (بالسنوات)',
                        hint: 'مثال: 35',
                        prefixIcon: Icons.cake_outlined,
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال العمر';
                          }
                          final age = int.tryParse(val.trim());
                          if (age == null || age <= 0 || age > 150) {
                            return 'يرجى إدخال عمر صحيح';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'الجنس',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedGender = 'male'),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedGender == 'male'
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.male_rounded,
                                          size: 16,
                                          color: selectedGender == 'male'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ذكر',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selectedGender == 'male' ? FontWeight.bold : FontWeight.normal,
                                            color: selectedGender == 'male'
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedGender = 'female'),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedGender == 'female'
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.female_rounded,
                                          size: 16,
                                          color: selectedGender == 'female'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'أنثى',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selectedGender == 'female' ? FontWeight.bold : FontWeight.normal,
                                            color: selectedGender == 'female'
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).textTheme.bodyLarge?.color,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'العنوان',
                  hint: 'مثال: المعادي، القاهرة',
                  prefixIcon: Icons.location_on_outlined,
                  controller: addressController,
                  optional: true,
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'السجل المرضي والملاحظات الطبية',
                  hint: 'اكتب أي ملاحظات أو أمراض مزمنة...',
                  prefixIcon: Icons.description_outlined,
                  controller: medicalHistoryController,
                  maxLines: 2,
                  optional: true,
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (addPatientFormKey.currentState!.validate()) {
              try {
                final age = int.tryParse(ageController.text.trim());
                final birthDate = age != null ? DateTime(DateTime.now().year - age, 1, 1) : null;
                final combinedAddress = "${addressController.text.trim()}|${medicalHistoryController.text.trim()}";

                final newPatient = await ref.read(patientRepositoryProvider).createPatient(
                      clinicId: widget.clinicId,
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      gender: selectedGender,
                      address: combinedAddress,
                      birthDate: birthDate,
                    );
                ref.invalidate(patientsListProvider(widget.clinicId));
                
                // Select the newly added patient
                setState(() {
                  _selectedPatientId = newPatient.id;
                  autocompleteController.text = newPatient.fullName;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(duration: Duration(seconds: 2), 
                      content: Text('تم تسجيل المريض وتحديده بنجاح'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    SnackBar(duration: const Duration(seconds: 2), content: Text('خطأ: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            }
          },
          child: const Text('تسجيل وحفظ'),
        ),
      ],
    );
  }

  Widget _buildSlotButton(String slot, List<AppointmentModel> booked) {
    final isBooked = _isSlotBooked(slot, booked);
    final slotTime = _parseSlotTime(slot);
    final isSelected = _selectedTime.hour == slotTime.hour &&
        _selectedTime.minute == slotTime.minute;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTime = slotTime;
          _customTimeController.text = slot;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor
              : isBooked
                  ? (isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          slot,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isBooked
                    ? (isDark ? Colors.orange.shade300 : Colors.orange.shade700)
                    : _textColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider(widget.clinicId));
    final typesAsync = ref.watch(appointmentTypesProvider);
    final appointmentsAsync = ref.watch(appointmentsForDateProvider(_selectedDate));

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return _buildMobileScaffold(context, patientsAsync, typesAsync, appointmentsAsync);
    } else {
      return _buildDesktopDialog(context, patientsAsync, typesAsync, appointmentsAsync);
    }
  }

  // ═══════════════════════════════════════════════
  // ─── Desktop Layout ───
  // ═══════════════════════════════════════════════
  Widget _buildDesktopDialog(
    BuildContext context,
    AsyncValue<List<PatientModel>> patientsAsync,
    AsyncValue<List<AppointmentTypeModel>> typesAsync,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: _surfaceCol,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Divider(height: 1, color: _borderCol),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column 1: Patient Selection & Services
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPatientField(patientsAsync),
                              const SizedBox(height: 20),
                              _buildServiceField(typesAsync),
                              const SizedBox(height: 20),
                              _buildAdditionalServices(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Divider
                        Container(
                          width: 1,
                          height: 480,
                          color: _borderCol,
                        ),
                        const SizedBox(width: 24),
                        // Column 2: Date and Time Grid
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDateField(),
                              const SizedBox(height: 16),
                              appointmentsAsync.when(
                                data: (booked) => _buildInlineTimeSlotsSelector(booked),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, _) => Text('خطأ: $err', style: TextStyle(color: _errorColor)),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Mobile Layout ───
  // ═══════════════════════════════════════════════
  Widget _buildMobileScaffold(
    BuildContext context,
    AsyncValue<List<PatientModel>> patientsAsync,
    AsyncValue<List<AppointmentTypeModel>> typesAsync,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: _textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'حجز موعد جديد',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textColor),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPatientField(patientsAsync),
                      const SizedBox(height: 20),
                      _buildServiceField(typesAsync),
                      const SizedBox(height: 20),
                      _buildAdditionalServices(),
                      const SizedBox(height: 20),
                      _buildDateField(),
                      const SizedBox(height: 20),
                      appointmentsAsync.when(
                        data: (booked) => _buildInlineTimeSlotsSelector(booked),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('خطأ: $err', style: TextStyle(color: _errorColor)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Components ───
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _inputFillCol,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حجز موعد جديد',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'اختر المريض والتوقيت المناسب',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: _borderCol),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded,
                    color: _textSecColor, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientField(AsyncValue<List<PatientModel>> patientsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('اسم المريض'),
        const SizedBox(height: 6),
        patientsAsync.when(
          data: (patients) {
            return Autocomplete<PatientModel>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<PatientModel>.empty();
                }
                final matches = patients.where((PatientModel option) {
                  return option.fullName.contains(textEditingValue.text) ||
                      (option.phone != null && option.phone!.contains(textEditingValue.text));
                }).toList();

                if (matches.isEmpty) {
                  return [
                    PatientModel(
                      id: 'ADD_NEW_PATIENT',
                      clinicId: widget.clinicId,
                      fullName: textEditingValue.text,
                      createdAt: DateTime.now(),
                    )
                  ];
                }
                return matches.take(5);
              },
              displayStringForOption: (PatientModel option) => option.fullName,
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                _autocompleteController = textEditingController;
                
                // If we have a preselected patient, populate the field
                if (_selectedPatientId != null && textEditingController.text.isEmpty) {
                  final matched = patients.firstWhere(
                    (p) => p.id == _selectedPatientId,
                    orElse: () => PatientModel(id: '', clinicId: '', fullName: '', createdAt: DateTime.now()),
                  );
                  if (matched.id.isNotEmpty) {
                    textEditingController.text = matched.fullName;
                  }
                }
                
                return _buildStitchTextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  hintText: 'ابحث بالاسم أو الهاتف...',
                  icon: Icons.search_rounded,
                  validator: (val) {
                    if (_selectedPatientId == null) return 'يرجى البحث واختيار مريض';
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 8,
                    color: _surfaceCol,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: _borderCol),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: _borderCol),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final isAddNew = option.id == 'ADD_NEW_PATIENT';

                          if (isAddNew) {
                            return ListTile(
                              onTap: () {
                                onSelected(option);
                              },
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.person_add_alt_1_rounded, color: _primaryColor),
                              ),
                              title: Text(
                                'إضافة مريض جديد باسم "${option.fullName}"',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _primaryColor,
                                ),
                              ),
                            );
                          }

                          return ListTile(
                            onTap: () => onSelected(option),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _inputFillCol,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  option.fullName.isNotEmpty ? option.fullName[0] : '؟',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              option.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _textColor,
                              ),
                            ),
                            subtitle: option.phone != null
                                ? Text(
                                    option.phone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textSecColor,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (PatientModel selection) {
                if (selection.id == 'ADD_NEW_PATIENT') {
                  if (_autocompleteController != null) {
                    _showAddPatientDialog(context, selection.fullName, _autocompleteController!);
                  }
                } else {
                  setState(() {
                    _selectedPatientId = selection.id;
                  });
                }
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Text('خطأ: $err', style: TextStyle(color: _errorColor, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildServiceField(AsyncValue<List<AppointmentTypeModel>> typesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('نوع الكشف الأساسي'),
        const SizedBox(height: 6),
        typesAsync.when(
          data: (types) {
            return DropdownButtonFormField<String>(
              initialValue: _selectedAppointmentTypeId,
              style: TextStyle(color: _textColor, fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(Icons.medical_services_outlined, size: 18, color: _textSecColor),
                filled: true,
                fillColor: _inputFillCol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _borderCol),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _borderCol),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              items: types.map((t) {
                return DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(
                    '${t.name} (${t.price.toStringAsFixed(0)} ج.م)',
                    style: TextStyle(fontSize: 14, color: _textColor),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAppointmentTypeId = val;
                });
                _updatePrice();
              },
              validator: (val) => val == null ? 'يرجى تحديد الكشف' : null,
            );
          },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, _) => Text('خطأ: $err', style: TextStyle(color: _errorColor, fontSize: 11)),
          ),
        ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('تاريخ الحجز'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: _borderCol),
                  backgroundColor: _inputFillCol,
                ),
                icon: Icon(Icons.calendar_month_rounded, color: _primaryColor),
                label: Text(
                  intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
                  style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 14),
                ),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineTimeSlotsSelector(List<AppointmentModel> booked) {
    final morningSlots = _allTimeSlots.where((slot) {
      return slot.endsWith('AM') &&
          !slot.startsWith('12:') &&
          !slot.startsWith('01:') &&
          !slot.startsWith('02:');
    }).toList();

    final eveningSlots = _allTimeSlots.where((slot) {
      return !morningSlots.contains(slot);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('الوقت المتاح للحجز'),
        const SizedBox(height: 8),
        Container(
          height: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _inputFillCol,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderCol),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Morning
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'صباحاً (7:00 AM - 11:30 AM)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (morningSlots.isEmpty)
                    Text('لا توجد أوقات صباحية متاحة', style: TextStyle(fontSize: 11, color: _textSecColor))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: morningSlots.map((slot) => _buildSlotButton(slot, booked)).toList(),
                    ),

                  const SizedBox(height: 16),
                  Divider(height: 1, color: _borderCol.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),

                  // Evening
                  Row(
                    children: [
                      const Icon(Icons.nights_stay_rounded, size: 14, color: Colors.indigo),
                      const SizedBox(width: 6),
                      Text(
                        'مساءً (12:00 PM - 2:00 AM)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (eveningSlots.isEmpty)
                    Text('لا توجد أوقات مسائية متاحة', style: TextStyle(fontSize: 11, color: _textSecColor))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: eveningSlots.map((slot) => _buildSlotButton(slot, booked)).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (picked != null) {
              setState(() {
                _selectedTime = picked;
                _customTimeController.text = _formatTimeOfDay(picked);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _inputFillCol,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderCol),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_calendar_rounded, size: 16, color: _textSecColor),
                const SizedBox(width: 8),
                Text(
                  'أو اختر وقتاً دقيقاً بالدقيقة: ${_formatTimeOfDay(_selectedTime)}',
                  style: TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down_rounded, color: _textSecColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalServices() {
    return ref.watch(availableServicesProvider(widget.clinicId)).when(
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderCol),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'إرفاق خدمات إضافية',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              children: [
                Divider(height: 1, color: _borderCol),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: _borderCol),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final isSelected = _selectedServices.any((s) => s.id == service.id);

                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(
                        service.name,
                        style: TextStyle(fontSize: 14, color: _textColor),
                      ),
                      subtitle: Text(
                        '+ ${service.price.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.removeWhere((s) => s.id == service.id);
                          }
                        });
                        _updatePrice();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: _surfaceCol,
        border: Border(
          top: BorderSide(color: _borderCol),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Price summary
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'السعر الإجمالي المطلوب',
                style: TextStyle(color: _textSecColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${_priceCharged.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(
                  color: _primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cancel
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderCol),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        color: _textSecColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Confirm
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _submit,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isSaving ? Colors.grey : _primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _isSaving ? null : [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'تأكيد وحفظ الحجز',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecColor,
      ),
    );
  }

  Widget _buildStitchTextField({
    TextEditingController? controller,
    FocusNode? focusNode,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: _textColor, fontSize: 14),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: _textSecColor),
        filled: true,
        fillColor: _inputFillCol,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  void _updatePrice() {
    double total = 0.0;

    if (_selectedAppointmentTypeId != null) {
      final typesAsync = ref.read(appointmentTypesProvider);
      final types = typesAsync.value;
      if (types != null) {
        final type = types.firstWhere((t) => t.id == _selectedAppointmentTypeId);
        total += type.price;
      }
    }

    for (final service in _selectedServices) {
      total += service.price;
    }

    setState(() {
      _priceCharged = total;
    });
  }
}
