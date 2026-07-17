import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../patients/data/patient_repository.dart';
import '../data/visit_note_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/service_model.dart';
import '../domain/appointment_model.dart';
import '../presentation/appointments_controller.dart';
import '../../reports/presentation/reports_controller.dart';
import 'widgets/patient_medical_sidebar.dart';
import 'widgets/examination_form.dart';

// فاصل الحقول داخل حقل notes الواحد في قاعدة البيانات
const _fieldSeparator = '\n---\n';


/// شاشة مساحة عمل الفحص الكاملة — تستبدل النافذة المنبثقة الضيقة
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
  // الحقول الثلاثة المنفصلة
  final _complaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();

  bool _initialized = false;
  bool _servicesInitialized = false;
  bool _isSaving = false;
  List<ServiceModel> _selectedServices = [];

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
  }

  /// دمج الحقول الثلاثة لحقل notes واحد للحفظ
  String _buildNotesText() {
    final complaint = _complaintController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final instructions = _instructionsController.text.trim();

    final parts = [complaint, diagnosis, instructions];
    return parts.join(_fieldSeparator);
  }

  /// حفظ التقرير دون إنهاء الكشف
  Future<void> _save({bool andComplete = false}) async {
    final text = _buildNotesText();
    final hasContent = _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _selectedServices.isNotEmpty;

    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى كتابة محتوى أو اختيار خدمة على الأقل'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // حفظ التقرير
      if (text.replaceAll(_fieldSeparator, '').trim().isNotEmpty) {
        await ref.read(visitNoteRepositoryProvider).upsertVisitNote(
              clinicId: widget.clinicId,
              appointmentId: widget.appointmentId,
              patientId: widget.patientId,
              notes: text,
            );
      }

      // إذا "حفظ وإنهاء الكشف" — نستخدم completeExamination الذري
      if (andComplete) {
        await ref.read(appointmentRepositoryProvider).completeExamination(
              clinicId: widget.clinicId,
              appointmentId: widget.appointmentId,
              selectedServices: _selectedServices,
            );
      } else {
        await ref.read(appointmentRepositoryProvider).updateAppointmentServices(
              clinicId: widget.clinicId,
              appointmentId: widget.appointmentId,
              selectedServices: _selectedServices,
            );
      }

      ref.invalidate(visitNoteProvider(widget.appointmentId));
      ref.invalidate(appointmentServicesProvider(widget.appointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(andComplete ? 'تم إنهاء الكشف وحفظ التقرير بنجاح' : 'تم حفظ التقرير بنجاح'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          content: const Text('سيتم حذف التقرير الطبي وجميع الخدمات المسجلة لهذه الجلسة.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(visitNoteRepositoryProvider).deleteVisitNote(widget.appointmentId);
      await ref.read(appointmentRepositoryProvider).updateAppointmentServices(
            clinicId: widget.clinicId,
            appointmentId: widget.appointmentId,
            selectedServices: [],
          );
      ref.invalidate(visitNoteProvider(widget.appointmentId));
      ref.invalidate(appointmentServicesProvider(widget.appointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف الجلسة'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(visitNoteProvider(widget.appointmentId));
    final appServicesAsync = ref.watch(appointmentServicesProvider(widget.appointmentId));
    final availableServicesAsync = ref.watch(availableServicesProvider(widget.clinicId));

    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
              Text(
                'جلسة فحص: ${widget.patientName}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Text(
                isDoctor ? 'الطبيب — صلاحية التحرير كاملة' : 'المساعد — عرض فقط',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
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
                            color: Theme.of(context).colorScheme.error, size: 18),
                        const SizedBox(width: 8),
                        Text('حذف الجلسة',
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: const SizedBox(height: 1),
          ),
        ),
        body: noteAsync.when(
          data: (note) {
            if (!_initialized) {
              if (note != null) _parseNotes(note.notes);
              _initialized = true;
            }

            if (isDesktop) {
              return _buildDesktopLayout(context, isDoctor, availableServicesAsync);
            } else {
              return _buildMobileLayout(context, isDoctor, availableServicesAsync);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('خطأ في تحميل التقرير: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
        bottomNavigationBar: isDoctor
            ? _buildBottomBar(context)
            : null,
      ),
    );
  }

  // ─── Desktop: عمودان ───
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDoctor,
    AsyncValue<List<ServiceModel>> availableServicesAsync,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── شريط المريض الجانبي ───
        SizedBox(
          width: 320, // Increased width for better sidebar layout
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: PatientMedicalSidebar(
              patientId: widget.patientId,
              patientName: widget.patientName,
              clinicId: widget.clinicId,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // ─── منطقة التقرير ───
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, bottom: 24, left: 24, right: 0),
            child: ExaminationForm(
              isDoctor: isDoctor,
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
      ],
    );
  }

  // ─── Mobile: عمود واحد ───
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
            patientId: widget.patientId,
            patientName: widget.patientName,
            clinicId: widget.clinicId,
          ),
          const SizedBox(height: 16),
          ExaminationForm(
            isDoctor: isDoctor,
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
  Widget _buildBottomBar(BuildContext context) {
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر حفظ بدون إنهاء
          OutlinedButton(
            onPressed: _isSaving ? null : () => _save(andComplete: false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ فقط', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          // زر حفظ وإنهاء الكشف
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _save(andComplete: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ وإنهاء الكشف',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
