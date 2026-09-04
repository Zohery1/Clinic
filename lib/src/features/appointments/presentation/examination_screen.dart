import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../data/visit_note_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/service_model.dart';
import '../presentation/appointments_controller.dart';
import '../../reports/presentation/reports_controller.dart';
import 'widgets/clinical_vitals_ribbon.dart';
import 'widgets/live_queue_rail.dart';
import 'widgets/patient_medical_sidebar.dart';
import 'widgets/examination_form.dart';
import '../../dashboard/presentation/notifications_controller.dart';

// فاصل الحقول داخل حقل notes الواحد في قاعدة البيانات
const _fieldSeparator = '\n---\n';

/// شاشة مساحة عمل الفحص السريري الكاملة — قمرة قيادة الطبيب البانورامية (3-Pane Panoramic Cockpit)
class ExaminationScreen extends ConsumerStatefulWidget {
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String patientName;

  const ExaminationScreen({
    super.key,
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends ConsumerState<ExaminationScreen> {
  late String _currentAppointmentId;
  late String _currentPatientId;
  late String _currentPatientName;

  // الحقول الثلاثة المنفصلة
  final _complaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();
  ClinicalVitalsData _vitals = ClinicalVitalsData();

  bool _initialized = false;
  bool _servicesInitialized = false;
  bool _isSaving = false;
  List<ServiceModel> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _currentAppointmentId = widget.appointmentId;
    _currentPatientId = widget.patientId;
    _currentPatientName = widget.patientName;
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _diagnosisController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  /// تحويل النص المخزّن في قاعدة البيانات لحقول منفصلة
  void _parseNotes(String rawNotes) {
    final parts = rawNotes.split(_fieldSeparator);
    _complaintController.text = parts.isNotEmpty ? parts[0].trim() : '';
    _diagnosisController.text = parts.length > 1 ? parts[1].trim() : '';
    _instructionsController.text = parts.length > 2 ? parts[2].trim() : '';
    if (parts.length > 3) {
      _vitals = ClinicalVitalsData.decode(parts[3].trim());
    } else {
      _vitals = ClinicalVitalsData();
    }
  }

  /// دمج الحقول لحقل notes واحد للحفظ
  String _buildNotesText() {
    final complaint = _complaintController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final instructions = _instructionsController.text.trim();
    final vitalsEncoded = _vitals.encode();

    final parts = [complaint, diagnosis, instructions, vitalsEncoded];
    return parts.join(_fieldSeparator);
  }

  /// تبديل المريض النشط في قمرة القيادة
  void _switchAppointment(AppointmentModel appt) {
    if (appt.id == _currentAppointmentId) return;

    setState(() {
      _currentAppointmentId = appt.id;
      _currentPatientId = appt.patientId;
      _currentPatientName = appt.patient.fullName;
      _initialized = false;
      _servicesInitialized = false;
      _selectedServices.clear();
      _complaintController.clear();
      _diagnosisController.clear();
      _instructionsController.clear();
      _vitals = ClinicalVitalsData();
    });
  }

  /// استدعاء المريض التالي في الطابور
  Future<void> _callNextPatient() async {
    final appointments = ref.read(todayAppointmentsProvider).value ?? [];
    final nextWaiting = appointments.firstWhere(
      (a) => a.status == 'confirmed' && a.id != _currentAppointmentId,
      orElse: () => appointments.firstWhere(
        (a) => a.id == _currentAppointmentId,
      ),
    );

    if (nextWaiting.id.isEmpty || nextWaiting.id == _currentAppointmentId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد مرضى آخرين في طابور الانتظار حالياً'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(nextWaiting.id, 'pending');

      ref.invalidate(todayAppointmentsProvider);

      try {
        ref.read(notificationsProvider.notifier).sendBroadcastNotification(
              title: 'دخول مريض للفحص',
              body:
                  'المريض (${nextWaiting.patient.fullName}) مطلوب في غرفة الفحص الآن',
              targetRole: 'doctor',
              playSound: true,
            );
      } catch (_) {}

      _switchAppointment(nextWaiting);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('تم استدعاء: ${nextWaiting.patient.fullName}'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استدعاء المريض: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// حفظ التقرير دون إنهاء الكشف
  Future<void> _save({bool andComplete = false}) async {
    final text = _buildNotesText();
    final hasContent = _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _selectedServices.isNotEmpty ||
        _vitals.bloodPressure.isNotEmpty ||
        _vitals.temperature.isNotEmpty;

    if (!hasContent) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('يرجى كتابة محتوى أو علامات حيوية أو اختيار خدمة'),
            backgroundColor: Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (text.replaceAll(_fieldSeparator, '').trim().isNotEmpty) {
        final currentUser = ref.read(currentUserProvider);
        await ref.read(visitNoteRepositoryProvider).upsertVisitNote(
              clinicId: widget.clinicId,
              appointmentId: _currentAppointmentId,
              patientId: _currentPatientId,
              doctorId: currentUser?.id,
              notes: text,
            );
      }

      if (andComplete) {
        await ref.read(appointmentRepositoryProvider).completeExamination(
              clinicId: widget.clinicId,
              appointmentId: _currentAppointmentId,
              selectedServices: _selectedServices,
            );
      } else {
        await ref
            .read(appointmentRepositoryProvider)
            .updateAppointmentServices(
              clinicId: widget.clinicId,
              appointmentId: _currentAppointmentId,
              selectedServices: _selectedServices,
            );
      }

      ref.invalidate(visitNoteProvider(_currentAppointmentId));
      ref.invalidate(appointmentServicesProvider(_currentAppointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);

      try {
        if (_selectedServices.isNotEmpty) {
          final serviceNames = _selectedServices.map((s) => s.name).join('، ');
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'إضافة خدمة جديدة',
                body:
                    'تم إضافة خدمة ($serviceNames) للمريض ($_currentPatientName)',
                targetRole: 'secretary',
                playSound: true,
              );
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(andComplete
                  ? 'تم إنهاء الكشف وحفظ التقرير بنجاح'
                  : 'تم حفظ التقرير بنجاح'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        if (andComplete) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text('خطأ في الحفظ: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الجلسة؟'),
          content: const Text(
              'سيتم حذف التقرير الطبي وجميع الخدمات المسجلة لهذه الجلسة.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(visitNoteRepositoryProvider)
          .deleteVisitNote(_currentAppointmentId);
      await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentServices(
            clinicId: widget.clinicId,
            appointmentId: _currentAppointmentId,
            selectedServices: [],
          );
      ref.invalidate(visitNoteProvider(_currentAppointmentId));
      ref.invalidate(appointmentServicesProvider(_currentAppointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: const Text('تم حذف الجلسة'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
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
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(visitNoteProvider(_currentAppointmentId));
    final appServicesAsync =
        ref.watch(appointmentServicesProvider(_currentAppointmentId));
    final availableServicesAsync =
        ref.watch(availableServicesProvider(widget.clinicId));

    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final canEditNotes = isDoctor || (currentUser?.canEditMedicalNotes ?? false);
    final isDesktop = MediaQuery.of(context).size.width >= 1080;

    // تهيئة الخدمات
    availableServicesAsync.whenData((availableList) {
      appServicesAsync.whenData((appServicesList) {
        if (!_servicesInitialized) {
          _selectedServices = availableList
              .where((av) => appServicesList.any((as) => as.serviceId == av.id))
              .toList();
          _servicesInitialized = true;
        }
      });
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'قمرة الفحص الطبي — $_currentPatientName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Clinical Cockpit',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'فحص سريري متزامن مع طابور الانتظار والسجل التاريخي',
                style:
                    TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          actions: [
            if (isDoctor)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'delete') _deleteSession();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 18),
                        const SizedBox(width: 8),
                        Text('حذف الجلسة',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),
        body: noteAsync.when(
          data: (note) {
            if (!_initialized) {
              if (note != null) _parseNotes(note.notes);
              _initialized = true;
            }

            if (isDesktop) {
              return _buildDesktopLayout(
                  context, canEditNotes, availableServicesAsync);
            } else {
              return _buildMobileLayout(
                  context, canEditNotes, availableServicesAsync);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('خطأ في تحميل التقرير: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
        bottomNavigationBar: canEditNotes
            ? _buildBottomBar(context, isDoctor: isDoctor)
            : null,
      ),
    );
  }

  // ─── Desktop: قمرة قيادة ثلاثية الأجنحة (3-Pane Panoramic View) ───
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDoctor,
    AsyncValue<List<ServiceModel>> availableServicesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── الجناح الأيمن: شريط طابور الانتظار المباشر (290px) ───
          SizedBox(
            width: 290,
            child: LiveQueueRail(
              clinicId: widget.clinicId,
              currentAppointmentId: _currentAppointmentId,
              onSelectAppointment: _switchAppointment,
              onCallNext: _callNextPatient,
            ),
          ),
          const SizedBox(width: 16),

          // ─── الجناح الأوسط: منصة الفحص السريري والملاحظات (Expanded) ───
          Expanded(
            child: SingleChildScrollView(
              child: ExaminationForm(
                isDoctor: isDoctor,
                vitals: _vitals,
                onVitalsChanged: (v) => setState(() => _vitals = v),
                complaintController: _complaintController,
                diagnosisController: _diagnosisController,
                instructionsController: _instructionsController,
                availableServicesAsync: availableServicesAsync,
                selectedServices: _selectedServices,
                onServiceToggled: (service, selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.removeWhere((s) => s.id == service.id);
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ─── الجناح الأيسر: شريط المريض الجانبي والسجل السابق (340px) ───
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: PatientMedicalSidebar(
                patientId: _currentPatientId,
                patientName: _currentPatientName,
                clinicId: widget.clinicId,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile: عمود واحد متتابع ───
  Widget _buildMobileLayout(
    BuildContext context,
    bool isDoctor,
    AsyncValue<List<ServiceModel>> availableServicesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatientMedicalSidebar(
            patientId: _currentPatientId,
            patientName: _currentPatientName,
            clinicId: widget.clinicId,
          ),
          const SizedBox(height: 16),
          ExaminationForm(
            isDoctor: isDoctor,
            vitals: _vitals,
            onVitalsChanged: (v) => setState(() => _vitals = v),
            complaintController: _complaintController,
            diagnosisController: _diagnosisController,
            instructionsController: _instructionsController,
            availableServicesAsync: availableServicesAsync,
            selectedServices: _selectedServices,
            onServiceToggled: (service, selected) {
              setState(() {
                if (selected) {
                  _selectedServices.add(service);
                } else {
                  _selectedServices.removeWhere((s) => s.id == service.id);
                }
              });
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── شريط الحفظ السفلي ───
  Widget _buildBottomBar(BuildContext context, {required bool isDoctor}) {
    if (!isDoctor) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _save(andComplete: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
              _isSaving ? 'جاري الحفظ...' : 'حفظ التقرير فقط',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر حفظ التقرير فقط (المسودة)
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _save(andComplete: false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'حفظ مسودة الكشف',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // زر إنهاء الكشف وحفظ التقرير
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _save(andComplete: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'إنهاء الكشف واعتماد التقرير',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
