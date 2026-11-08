import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../../core/routing/routing.dart';
import '../../clinics/presentation/clinics_controller.dart';
import '../../patients/data/patient_repository.dart';
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
import 'widgets/examination_bottom_bar.dart';
import '../../dashboard/presentation/notifications_controller.dart';

const _fieldSeparator = '\n---\n';

/// شاشة مساحة عمل الفحص الطبي — قمرة قيادة الطبيب (Clinical Examination Workspace)
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

  String _buildNotesText() {
    final complaint = _complaintController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final instructions = _instructionsController.text.trim();
    final vitalsEncoded = _vitals.encode();

    final parts = [complaint, diagnosis, instructions, vitalsEncoded];
    return parts.join(_fieldSeparator);
  }

  bool get _hasUnsavedChanges {
    return _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _vitals.bloodPressure.isNotEmpty ||
        _vitals.temperature.isNotEmpty ||
        _selectedServices.isNotEmpty;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderSubtle(ctx)),
          ),
          title: Text(
            'مغادرة الفحص دون حفظ؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'توجد بيانات فحص سريري غير محفوظة. هل تريد الخروج وتجاهل التغييرات؟',
            style: GoogleFonts.cairo(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'متابعة الفحص',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(ctx),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'مغادرة دون حفظ',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

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

  Future<void> _callNextPatient() async {
    final appointments = ref.read(todayAppointmentsProvider).value ?? [];
    final waitingAppointments = appointments
        .where((a) => a.status == 'confirmed' && a.id != _currentAppointmentId)
        .toList();

    if (waitingAppointments.isEmpty) {
      ClinicToast.showWarning(
        context,
        'لا يوجد مرضى آخرون في صالة الانتظار حالياً',
      );
      return;
    }

    final nextWaiting = waitingAppointments.first;

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
        ClinicToast.showSuccess(context, 'تم استدعاء: ${nextWaiting.patient.fullName}');
      }
    } catch (_) {
      if (mounted) ClinicToast.showError(context, 'تعذر استدعاء المريض حالياً');
    }
  }

  Future<void> _sharePrescriptionViaWhatsApp() async {
    String? patientPhone;
    try {
      final patients = await ref.read(patientRepositoryProvider).getPatients(widget.clinicId);
      for (final p in patients) {
        if (p.id == _currentPatientId && p.phone != null && p.phone!.isNotEmpty) {
          patientPhone = p.phone;
          break;
        }
      }
    } catch (_) {}

    final user = ref.read(currentUserProvider);
    final activeClinic = ref.read(activeClinicSummaryProvider);
    final clinicName = activeClinic?.clinicName ?? 'العيادة';
    final doctorName = user?.fullName ?? 'الطبيب المعالج';

    final text = StringBuffer();
    text.writeln('🏥 $clinicName');
    text.writeln('👨‍⚕️ د. $doctorName');
    text.writeln('━━━━━━━━━━━━━━━━━━━━');
    text.writeln('👤 المريض: $_currentPatientName');
    final nowStr = intl.DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());
    text.writeln('📅 التاريخ: $nowStr');
    text.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (_diagnosisController.text.trim().isNotEmpty) {
      text.writeln('🩺 التشخيص:');
      text.writeln(_diagnosisController.text.trim());
      text.writeln('');
    }

    if (_instructionsController.text.trim().isNotEmpty) {
      text.writeln('💊 الروشتة والعلاج:');
      text.writeln(_instructionsController.text.trim());
      text.writeln('');
    }

    if (_selectedServices.isNotEmpty) {
      text.writeln('📋 الخدمات:');
      text.writeln(_selectedServices.map((s) => s.name).join('، '));
      text.writeln('');
    }

    text.writeln('مع تمنياتنا لكم بالشفاء العاجل 🌿');

    if (!mounted) return;
    AppNavigation.showWhatsApp(
      context,
      phone: patientPhone ?? '',
      patientName: _currentPatientName,
      initialMessage: text.toString(),
    );
  }

  Future<void> _save({bool andComplete = false}) async {
    final text = _buildNotesText();
    final hasContent = _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _selectedServices.isNotEmpty ||
        _vitals.bloodPressure.isNotEmpty ||
        _vitals.temperature.isNotEmpty;

    if (!hasContent) {
      ClinicToast.showWarning(
        context,
        'أدخل شكوى المريض أو التشخيص أو العلامات الحيوية قبل الحفظ',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(currentUserProvider);

      if (_currentAppointmentId.isEmpty || _currentAppointmentId.length < 30) {
        final walkIn = await ref.read(appointmentRepositoryProvider).createWalkInAppointment(
              clinicId: widget.clinicId,
              patientId: _currentPatientId,
              doctorId: currentUser?.id,
              branchId: currentUser?.activeBranchId,
            );
        _currentAppointmentId = walkIn.id;
      }

      if (text.replaceAll(_fieldSeparator, '').trim().isNotEmpty) {
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
        ClinicToast.showSuccess(
          context,
          andComplete ? 'تم إنهاء الكشف وحفظ السجل الطبي.' : 'تم حفظ بيانات الكشف كمسودة.',
        );
        if (andComplete) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      if (mounted) ClinicToast.showError(context, 'تعذر حفظ بيانات الفحص الطبي');
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
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'حذف جلسة الكشف؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            'سيتم حذف التقرير الطبي والخدمات المسجلة لهذا الكشف نهائياً.',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger),
              child: Text(
                'حذف الجلسة',
                style: GoogleFonts.cairo(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        ClinicToast.showInfo(context, 'تم حذف جلسة الكشف');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) ClinicToast.showError(context, 'تعذر حذف جلسة الكشف');
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

    if (!_servicesInitialized &&
        availableServicesAsync.hasValue &&
        appServicesAsync.hasValue) {
      final availableList = availableServicesAsync.value ?? [];
      final appServicesList = appServicesAsync.value ?? [];
      _selectedServices = availableList
          .where((av) => appServicesList.any((as) => as.serviceId == av.id))
          .toList();
      _servicesInitialized = true;
    }

    // Deep-link guard: without an appointment context the note provider spins
    // forever (observed on the web build via #/examination with no args).
    if (_currentAppointmentId.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppStatusPage(
          icon: Icons.medical_information_outlined,
          iconColor: AppColors.info,
          title: 'لا توجد جلسة كشف مفتوحة',
          message: 'افتح الكشف من قائمة مواعيد اليوم أو الطابور لبدء جلسة تسجيل.',
          primaryAction: StatusAction(
            label: 'العودة للوحة التحكم',
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _confirmDiscardChanges();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.canvas(context),
          appBar: AppBar(
            backgroundColor: AppColors.surface(context),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: BackButton(
              color: AppColors.textPrimary(context),
              onPressed: () async {
                final shouldPop = await _confirmDiscardChanges();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'كشف: $_currentPatientName',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'جلسة نشطة',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  'الملف الطبي والفحص',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
            actions: [
              if (isDesktop)
                FilledButton.tonalIcon(
                  onPressed: _sharePrescriptionViaWhatsApp,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.12),
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: Text(
                    'إرسال الروشتة بالواتساب',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                IconButton.filledTonal(
                  onPressed: _sharePrescriptionViaWhatsApp,
                  tooltip: 'إرسال الروشتة بالواتساب',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.12),
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                ),
              const SizedBox(width: 8),
              if (isDoctor)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: AppColors.textPrimary(context)),
                  color: AppColors.surface(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.borderSubtle(context)),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') _deleteSession();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'حذف الجلسة',
                            style: GoogleFonts.cairo(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.borderSubtle(context)),
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
              child: Text(
                'تعذر تحميل التقرير الطبي، يرجى إعادة المحاولة',
                style: GoogleFonts.cairo(color: AppColors.danger),
              ),
            ),
          ),
          bottomNavigationBar: canEditNotes
              ? ExaminationBottomBar(
                  isDoctor: isDoctor,
                  isSaving: _isSaving,
                  onSaveDraft: () => _save(andComplete: false),
                  onCompleteAndSave: () => _save(andComplete: true),
                  onSharePrescription: _sharePrescriptionViaWhatsApp,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDoctor,
    AsyncValue<List<ServiceModel>> availableServicesAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUltraWide = constraints.maxWidth >= 1400;
        final queueWidth = isUltraWide ? 280.0 : 240.0;
        final sidebarWidth = isUltraWide ? 320.0 : 280.0;
        final gap = isUltraWide ? 16.0 : 12.0;

        return Padding(
          padding: EdgeInsets.all(gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: queueWidth,
                child: LiveQueueRail(
                  clinicId: widget.clinicId,
                  currentAppointmentId: _currentAppointmentId,
                  onSelectAppointment: _switchAppointment,
                  onCallNext: _callNextPatient,
                ),
              ),
              SizedBox(width: gap),
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
              SizedBox(width: gap),
              SizedBox(
                width: sidebarWidth,
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
      },
    );
  }

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
}
