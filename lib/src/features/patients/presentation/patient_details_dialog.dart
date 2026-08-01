import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../appointments/domain/appointment_model.dart';
import '../../appointments/domain/appointment_service_model.dart';
import '../../appointments/data/visit_note_repository.dart';
import '../../appointments/presentation/visit_notes_dialog.dart';
import '../../appointments/presentation/book_appointment_dialog.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../domain/patient_model.dart';
import '../data/patient_repository.dart';

// مزود لجلب تاريخ مواعيد المريض بالكامل (منتهية فقط)
final patientAppointmentsProvider = FutureProvider.family.autoDispose<List<AppointmentModel>, String>((ref, patientId) async {
  final all = await ref.watch(appointmentRepositoryProvider).getPatientAppointments(patientId);
  return all.where((app) => app.status == 'completed').toList();
});

// مزود لجلب الخدمات الطبية الخاصة بالزيارة
final appointmentServicesProvider = FutureProvider.family.autoDispose<List<AppointmentServiceModel>, String>((ref, appointmentId) async {
  return ref.watch(appointmentRepositoryProvider).getAppointmentServices(appointmentId);
});

class PatientDetailsDialog extends ConsumerWidget {
  final String clinicId;
  final PatientModel patient;

  const PatientDetailsDialog({
    super.key,
    required this.clinicId,
    required this.patient,
  });

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _capitalizeName(String name) {
    return name;
  }



  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'مع الطبيب';
      case 'confirmed':
        return 'في الانتظار';
      case 'completed':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'في الانتظار';
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF3B82F6); // Blue (مع الطبيب)
      case 'confirmed':
        return const Color(0xFFF59E0B); // Orange (في الانتظار)
      case 'completed':
        return const Color(0xFF10B981); // Green (منتهي)
      case 'cancelled':
        return const Color(0xFFEF4444); // Red (ملغي)
      default:
        return const Color(0xFFF59E0B); // Orange (في الانتظار)
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final age = _calculateAge(patient.birthDate);

    final displayAddress = patient.address != null
        ? (patient.address!.contains('|')
            ? patient.address!.split('|').first.trim()
            : patient.address!)
        : '';
    final medicalHistory = patient.medicalHistory ??
        ((patient.address != null && patient.address!.contains('|'))
            ? patient.address!.split('|').last.trim()
            : '');

    final patientsAsync = ref.watch(patientsListProvider(clinicId));
    final fullPatients = patientsAsync.value ?? [];
    final sortedFullPatients = List<PatientModel>.from(fullPatients)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final index = sortedFullPatients.indexWhere((p) => p.id == patient.id);
    final fileNo = index != -1 ? '#${index + 1}' : '';

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return _buildMobileScreen(context, ref, appointmentsAsync, currentUser, isDoctor, age, fileNo, displayAddress, medicalHistory);
    } else {
      return _buildDesktopDialog(context, ref, appointmentsAsync, currentUser, isDoctor, age, fileNo, displayAddress, medicalHistory);
    }
  }

  Widget _buildMobileScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    UserModel? currentUser,
    bool isDoctor,
    int? age,
    String fileNo,
    String displayAddress,
    String medicalHistory,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _capitalizeName(patient.fullName),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                'ملف رقم $fileNo',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: patient.gender == 'female'
                        ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      patient.gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
                      color: patient.gender == 'female' ? const Color(0xFFEC4899) : Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeName(patient.fullName),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الملف الطبي الموحد للمريض',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildClinicalMetaItem(context, 'رقم الهاتف', patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل', Icons.phone_rounded, Colors.blue),
                      const SizedBox(width: 8),
                      _buildClinicalMetaItem(context, 'العنوان', displayAddress.isNotEmpty ? displayAddress : 'غير مسجل', Icons.location_on_outlined, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildClinicalMetaItem(context, 'العمر', age != null ? '$age سنة' : 'غير مسجل', Icons.cake_outlined, Colors.orange),
                      const SizedBox(width: 8),
                      _buildClinicalMetaItem(context, 'رقم الملف', fileNo, Icons.badge_rounded, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ─── Medical History Card ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.error, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'السجل المرضي للمريض',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          medicalHistory.isNotEmpty ? medicalHistory : 'لا يوجد سجل مرضي مسجل.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAppointmentsTimeline(context, appointmentsAsync, clinicId, patient, isDoctor),
              ),
            ),
          ],
        ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BookAppointmentDialog(
                  clinicId: clinicId,
                  preselectedPatientId: patient.id,
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add_task_rounded, size: 20),
            label: const Text('حجز موعد', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      );
  }

  Widget _buildDesktopDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    UserModel? currentUser,
    bool isDoctor,
    int? age,
    String fileNo,
    String displayAddress,
    String medicalHistory,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Dialog Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment_ind_outlined,
                              color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الملف الطبي الموحد للمريض',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تفاصيل بيانات المريض والتاريخ المرضي للزيارات',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.transparent
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7), size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ─── Dialog Content ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Patient Info & Avatar Block
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), // surface-container-low
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: patient.gender == 'female'
                                  ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              child: Icon(
                                patient.gender == 'female'
                                    ? Icons.woman_rounded
                                    : Icons.man_rounded,
                                color: patient.gender == 'female'
                                    ? const Color(0xFFEC4899)
                                    : Theme.of(context).colorScheme.primary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _capitalizeName(patient.fullName),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ملف $fileNo',
                                          style: GoogleFonts.cairo(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'الملف الطبي الموحد للمريض',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Patient Demographics Grid ───
                      Row(
                        children: [
                          _buildClinicalMetaItem(context, 'رقم الهاتف', patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل', Icons.phone_rounded, Colors.blue),
                          const SizedBox(width: 8),
                          _buildClinicalMetaItem(context, 'العنوان', displayAddress.isNotEmpty ? displayAddress : 'غير مسجل', Icons.location_on_outlined, Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildClinicalMetaItem(context, 'العمر', age != null ? '$age سنة' : 'غير مسجل', Icons.cake_outlined, Colors.orange),
                          const SizedBox(width: 8),
                          _buildClinicalMetaItem(context, 'رقم الملف', fileNo, Icons.badge_rounded, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ─── Medical History Card ───
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.error, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'السجل المرضي للمريض / ملاحظات هامة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              medicalHistory.isNotEmpty ? medicalHistory : 'لا يوجد سجل مرضي مسجل لهذا المريض.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Visits Title & Timeline ───
                      Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'سجل الزيارات والتشخيص الطبي للمريض',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 350,
                        child: _buildAppointmentsTimeline(context, appointmentsAsync, clinicId, patient, isDoctor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Footer close button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق الملف', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalMetaItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTimeline(BuildContext context, AsyncValue<List<AppointmentModel>> appointmentsAsync, String clinicId, PatientModel patient, bool isDoctor) {
    final currentUser = ProviderScope.containerOf(context).read(currentUserProvider);
    if (currentUser != null && currentUser.role == UserRole.secretary && !currentUser.canViewMedicalHistory) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecorationFlat(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 40, color: AppTheme.error),
              const SizedBox(height: 12),
              const Text(
                'تاريخ طبي محجوب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'ليس لديك صلاحية لمشاهدة الروشتات والتاريخ الطبي له، يرجى مراجعة الطبيب.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Text(
              'لا توجد زيارات سابقة مسجلة للمريض',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          itemCount: appointments.length,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            final app = appointments[index];
            final date = intl.DateFormat('yyyy/MM/dd', 'ar').format(app.appointmentDate.toLocal());
            final time = intl.DateFormat('hh:mm a', 'ar').format(app.appointmentDate.toLocal());

            return Stack(
              children: [
                if (index != appointments.length - 1)
                  Positioned(
                    top: 14,
                    bottom: 0,
                    right: 4,
                    child: Container(
                      width: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                Positioned(
                  top: 3,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 22, bottom: 8),
                  child: _DialogTimelineAppointmentCard(
                    app: app,
                    date: date,
                    time: time,
                    clinicId: clinicId,
                    patient: patient,
                    isDoctor: isDoctor,
                    getStatusColor: _getStatusColor,
                    translateStatus: _translateStatus,
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (err, _) => Center(child: Text('خطأ: $err', style: TextStyle(color: Theme.of(context).colorScheme.error))),
    );
  }


}

// ويدجت داخلي لعرض التشخيص الخاص بالموعد
class PatientVisitNoteSection extends ConsumerWidget {
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final bool isDoctor;

  const PatientVisitNoteSection({
    super.key,
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.isDoctor,
  });

  Widget _buildNoteBox(BuildContext context, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : 'لا يوجد',
            style: TextStyle(
              fontSize: 13,
              color: content.isNotEmpty ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(visitNoteProvider(appointmentId));

    return noteAsync.when(
      data: (note) {
        final rawNotes = note?.notes ?? '';
        final hasNote = rawNotes.replaceAll('\n---\n', '').trim().isNotEmpty;
        final parts = rawNotes.split('\n---\n');
        final complaint = parts.isNotEmpty ? parts[0].trim() : '';
        final diagnosis = parts.length > 1 ? parts[1].trim() : '';
        final instructions = parts.length > 2 ? parts[2].trim() : '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'التشخيص الطبي والتعليمات:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                  if (isDoctor)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(hasNote ? Icons.edit_outlined : Icons.add_rounded, size: 14),
                      label: Text(hasNote ? 'تعديل التقرير' : 'إضافة تقرير طبي', style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => VisitNotesDialog(
                            clinicId: clinicId,
                            appointmentId: appointmentId,
                            patientId: patientId,
                            patientName: patientName,
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasNote)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'لم يتم تدوين أي تقرير طبي أو تشخيص لهذه الزيارة بعد.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                      height: 1.5,
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildNoteBox(context, 'الشكوى الرئيسية', complaint, Icons.record_voice_over_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNoteBox(context, 'التشخيص الطبي', diagnosis, Icons.medical_information_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNoteBox(context, 'تعليمات للمريض', instructions, Icons.receipt_long_outlined)),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNoteBox(context, 'الشكوى الرئيسية', complaint, Icons.record_voice_over_outlined),
                          const SizedBox(height: 12),
                          _buildNoteBox(context, 'التشخيص الطبي', diagnosis, Icons.medical_information_outlined),
                          const SizedBox(height: 12),
                          _buildNoteBox(context, 'تعليمات للمريض', instructions, Icons.receipt_long_outlined),
                        ],
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ويدجت داخلي لعرض الخدمات المقدمة في الزيارة
class AppointmentServicesSection extends ConsumerWidget {
  final String appointmentId;

  const AppointmentServicesSection({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(appointmentServicesProvider(appointmentId));

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_information_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'الخدمات والإجراءات المقدمة:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'لا توجد خدمات مسجلة لهذه الزيارة.',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_information_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'الخدمات والإجراءات المقدمة:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.serviceName ?? 'خدمة غير معروفة',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${service.priceCharged.toStringAsFixed(0)} ج.م)',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5))),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('خطأ في تحميل الخدمات: $err', style: const TextStyle(color: Colors.red, fontSize: 11)),
      ),
    );
  }
}

class _DialogTimelineAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel app;
  final String date;
  final String time;
  final String clinicId;
  final PatientModel patient;
  final bool isDoctor;
  final Color Function(BuildContext, String) getStatusColor;
  final String Function(String) translateStatus;

  const _DialogTimelineAppointmentCard({
    required this.app,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.patient,
    required this.isDoctor,
    required this.getStatusColor,
    required this.translateStatus,
  });

  @override
  ConsumerState<_DialogTimelineAppointmentCard> createState() => _DialogTimelineAppointmentCardState();
}

class _DialogTimelineAppointmentCardState extends ConsumerState<_DialogTimelineAppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(widget.date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(width: 8),
                      Text(widget.time, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.getStatusColor(context, widget.app.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.translateStatus(widget.app.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.getStatusColor(context, widget.app.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      AppointmentServicesSection(appointmentId: widget.app.id),
                      PatientVisitNoteSection(
                        clinicId: widget.clinicId,
                        appointmentId: widget.app.id,
                        patientId: widget.patient.id,
                        patientName: widget.patient.fullName,
                        isDoctor: widget.isDoctor,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


