import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/ui/tokens/colors.dart';
import '../../../core/widgets/send_whatsapp_dialog.dart';
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

  /// فحص وجود تعديلات غير محفوظة
  bool get _hasUnsavedChanges {
    return _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _vitals.bloodPressure.isNotEmpty ||
        _vitals.temperature.isNotEmpty ||
        _selectedServices.isNotEmpty;
  }

  /// حوار تأكيد الخروج عند وجود تعديلات غير محفوظة
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
            'تراجع عن التعديلات؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(
            'يوجد بيانات مدخلة في الفحص الطبي لم يتم حفظها. هل أنت متأكد من رغبتك في الخروج وتجاهلها؟',
            style: GoogleFonts.cairo(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'البقاء في الفحص',
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
                'الخروج وتجاهل التعديلات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
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
    final waitingAppointments = appointments
        .where((a) => a.status == 'confirmed' && a.id != _currentAppointmentId)
        .toList();

    if (waitingAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد مرضى آخرين في طابور الانتظار حالياً',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تم استدعاء: ${nextWaiting.patient.fullName}',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في استدعاء المريض: $e',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// مشاركة الروشتة والتعليمات الطبية عبر واتساب المريض
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
      text.writeln('🩺 التشخيص الطبي:');
      text.writeln(_diagnosisController.text.trim());
      text.writeln('');
    }

    if (_instructionsController.text.trim().isNotEmpty) {
      text.writeln('💊 الروشتة وخطة العلاج:');
      text.writeln(_instructionsController.text.trim());
      text.writeln('');
    }

    if (_selectedServices.isNotEmpty) {
      text.writeln('📋 الخدمات والإجراءات:');
      text.writeln(_selectedServices.map((s) => s.name).join('، '));
      text.writeln('');
    }

    text.writeln('مع تمنياتنا لكم بالشفاء العاجل ودوام الصحة والعافية 🌿');

    if (!mounted) return;
    showSendWhatsAppDialog(
      context,
      ref,
      phone: patientPhone ?? '',
      patientName: _currentPatientName,
      initialMessage: text.toString(),
    );
  }

  /// حفظ التقرير دون إنهاء الكشف
  Future<void> _save({bool andComplete = false}) async {
    debugPrint('[Examination] START SAVE: apptId=$_currentAppointmentId, patientId=$_currentPatientId, clinicId=${widget.clinicId}');
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
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              'يرجى كتابة محتوى أو علامات حيوية أو اختيار خدمة',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(currentUserProvider);

      // إذا فُتحت شاشة الفحص مباشرة دون حجز مسبق، يتم إنشاء جلسة كشف فورية بالعيادة
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
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                andComplete
                    ? 'تم إنهاء الكشف وحفظ التقرير بنجاح'
                    : 'تم حفظ التقرير بنجاح',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.success,
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
              content: Text(
                'خطأ في الحفظ: $e',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.danger,
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
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'حذف الجلسة؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            'سيتم حذف التقرير الطبي وجميع الخدمات المسجلة لهذه الجلسة.',
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
                'حذف',
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
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                'تم حذف الجلسة',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.danger,
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
              content: Text(
                'خطأ في الحذف: $e',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.danger,
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

    // تهيئة الخدمات بأمان دون تعديل الـ State أثناء البناء
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
            children: [
              Row(
                children: [
                  Text(
                    'جلسة الفحص الطبي — $_currentPatientName',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
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
                'الملف الطبي والكشف السريري المباشر',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton.tonalIcon(
              onPressed: _sharePrescriptionViaWhatsApp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                foregroundColor: const Color(0xFF10B981),
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
              'خطأ في تحميل التقرير: $err',
              style: GoogleFonts.cairo(color: AppColors.danger),
            ),
          ),
        ),
        bottomNavigationBar: canEditNotes
            ? _buildBottomBar(context, isDoctor: isDoctor)
            : null,
        ),
      ),
    );
  }

  // ─── Desktop: قمرة قيادة ثلاثية الأجنحة (3-Pane Panoramic View) ───
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
              // ─── الجناح الأيمن: شريط طابور الانتظار المباشر ───
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
              SizedBox(width: gap),

              // ─── الجناح الأيسر: شريط المريض الجانبي والسجل السابق ───
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    if (!isDoctor) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
              backgroundColor: AppColors.primary,
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
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
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
        bottom: 12 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر إرسال الروشتة بالواتساب للمريض
          IconButton.filledTonal(
            onPressed: _sharePrescriptionViaWhatsApp,
            tooltip: 'إرسال الروشتة بالواتساب',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.share_rounded, size: 20),
          ),
          const SizedBox(width: 10),

          // زر حفظ التقرير فقط (المسودة)
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _save(andComplete: false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.save_outlined, size: 18, color: AppColors.primary),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'حفظ مسودة الكشف',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.primary,
                  ),
                ),
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
                backgroundColor: AppColors.success,
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
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isSaving ? 'جاري الحفظ...' : 'إنهاء الكشف واعتماد التقرير',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
