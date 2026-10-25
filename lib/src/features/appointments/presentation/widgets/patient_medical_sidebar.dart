import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../patients/domain/patient_model.dart';
import '../../../patients/data/patient_repository.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../../data/visit_note_repository.dart';
import '../../domain/visit_note_model.dart';

final patientAppointmentsProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, patientId) async {
  final all = await ref.watch(appointmentRepositoryProvider).getPatientAppointments(patientId);
  return all.where((app) => app.status == 'completed').toList();
});

class PatientMedicalSidebar extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  final String clinicId;

  const PatientMedicalSidebar({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.clinicId,
  });

  @override
  ConsumerState<PatientMedicalSidebar> createState() => _PatientMedicalSidebarState();
}

class _PatientMedicalSidebarState extends ConsumerState<PatientMedicalSidebar> {
  bool _isHistoryExpanded = true;
  bool _isVisitsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final patientId = widget.patientId;
    final patientName = widget.patientName;
    final clinicId = widget.clinicId;

    final patientAsync = ref.watch(patientsListProvider(clinicId));
    final patientAppointmentsAsync = ref.watch(patientAppointmentsProvider(patientId));
    final patientNotesAsync = ref.watch(patientVisitNotesProvider(patientId));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderSubtle(context)),
      ),
      color: AppColors.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Avatar and Details ───
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patientName.isNotEmpty ? patientName[0] : '؟',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      patientAsync.when(
                        data: (patients) {
                          final sorted = List<PatientModel>.from(patients)
                            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                          final idx = sorted.indexWhere((p) => p.id == patientId);
                          final patient = idx != -1 ? sorted[idx] : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (idx != -1)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ملف #${idx + 1}',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  if (idx != -1) const SizedBox(width: 8),
                                  if (patient?.gender != null)
                                    Text(
                                      patient!.gender == 'male' ? 'ذكر' : 'أنثى',
                                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary(context)),
                                    ),
                                  if (patient?.gender != null && patient?.birthDate != null)
                                    Text(' • ', style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
                                  if (patient?.birthDate != null)
                                    Text(
                                      '${DateTime.now().year - patient!.birthDate!.year} سنة',
                                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary(context)),
                                    ),
                                ],
                              ),
                              if (patient?.phone != null && patient!.phone!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted(context)),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient.phone!,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: AppColors.textSecondary(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const SizedBox(height: 14, width: 60, child: LinearProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.borderSubtle(context)),
            const SizedBox(height: 20),

            // ─── Medical History ───
            InkWell(
              onTap: () => setState(() => _isHistoryExpanded = !_isHistoryExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'التاريخ المرضي',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isHistoryExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textMuted(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isHistoryExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        patientAsync.when(
                          data: (patients) {
                            final patient = patients.cast<PatientModel?>().firstWhere((p) => p?.id == patientId, orElse: () => null);
                            if (patient?.medicalHistory != null && patient!.medicalHistory!.isNotEmpty) {
                              final historyItems = patient.medicalHistory!
                                  .split(RegExp(r'[،,-]'))
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();
                              
                              if (historyItems.isEmpty) {
                                historyItems.add(patient.medicalHistory!.trim());
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: historyItems.map((mh) {
                                  final isAllergy = mh.contains('حساسية') ||
                                      mh.toLowerCase().contains('allergy');
                                  final itemColor = isAllergy ? AppColors.danger : AppColors.textPrimary(context);
                                  final itemBg = isAllergy
                                      ? AppColors.dangerSubtle
                                      : AppColors.subtle(context);
                                  final itemBorder = isAllergy
                                      ? AppColors.danger.withValues(alpha: 0.4)
                                      : AppColors.borderSubtle(context);

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: itemBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: itemBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAllergy) ...[
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: AppColors.danger,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          mh,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            fontWeight: isAllergy ? FontWeight.w700 : FontWeight.w600,
                                            color: itemColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.subtle(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderSubtle(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.textMuted(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'لا توجد أمراض مزمنة مسجلة.',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.borderSubtle(context)),
            const SizedBox(height: 20),

            // ─── Previous Visits ───
            InkWell(
              onTap: () => setState(() => _isVisitsExpanded = !_isVisitsExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'الزيارات السابقة',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _isVisitsExpanded = !_isVisitsExpanded),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        _isVisitsExpanded ? 'إخفاء' : 'عرض الكل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isVisitsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textMuted(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isVisitsExpanded
                  ? Column(
                      children: [
                        patientAppointmentsAsync.when(
                          data: (appts) {
                            if (appts.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.subtle(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderSubtle(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.textMuted(context)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'لا توجد زيارات سابقة.',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Sort by date descending and take top 5
                            final sorted = List.from(appts)..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
                            final recent = sorted.take(5).toList();

                            return Column(
                              children: recent.map((appt) {
                                final date = DateFormat('d MMMM yyyy', 'ar').format(appt.appointmentDate);
                                
                                // Extract full visit details from notes if available
                                String? complaint;
                                String? diagnosis;
                                String? instructions;
                                
                                final notesList = patientNotesAsync.value;
                                if (notesList != null) {
                                  VisitNoteModel? note;
                                  for (final n in notesList) {
                                    if (n.appointmentId == appt.id) {
                                      note = n;
                                      break;
                                    }
                                  }
                                  if (note != null && note.notes.isNotEmpty) {
                                    final parts = note.notes.split('\n---\n');
                                    if (parts.isNotEmpty) complaint = parts[0].trim();
                                    if (parts.length > 1) diagnosis = parts[1].trim();
                                    if (parts.length > 2) instructions = parts[2].trim();
                                  }
                                }

                                return _VisitHistoryItem(
                                  date: date,
                                  appt: appt,
                                  complaint: complaint,
                                  diagnosis: diagnosis,
                                  instructions: instructions,
                                  services: (appt.serviceNames != null && appt.serviceNames!.isNotEmpty) ? appt.serviceNames!.join('، ') : null,
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitHistoryItem extends StatefulWidget {
  final String date;
  final AppointmentModel appt;
  final String? complaint;
  final String? diagnosis;
  final String? instructions;
  final String? services;

  const _VisitHistoryItem({
    required this.date,
    required this.appt,
    this.complaint,
    this.diagnosis,
    this.instructions,
    this.services,
  });

  @override
  State<_VisitHistoryItem> createState() => _VisitHistoryItemState();
}

class _VisitHistoryItemState extends State<_VisitHistoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasDetails = (widget.complaint != null && widget.complaint!.isNotEmpty) ||
                       (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) ||
                       (widget.instructions != null && widget.instructions!.isNotEmpty) ||
                       (widget.services != null && widget.services!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: const Icon(Icons.history_rounded, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.date,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (widget.appt.appointmentTypeName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.appt.appointmentTypeName!,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (widget.appt.doctorName != null && widget.appt.doctorName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'الطبيب: ${DoctorUtils.formatTitle(widget.appt.doctorName)}',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.only(top: 12, right: 8, left: 8),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.borderSubtle(context))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.services != null && widget.services!.isNotEmpty) ...[
                              Text(
                                'الخدمات المقدمة:',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.services!,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (widget.complaint != null && widget.complaint!.isNotEmpty) ...[
                              Text(
                                'الشكوى:',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.complaint!,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) ...[
                              Text(
                                'التشخيص:',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.diagnosis!,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (widget.instructions != null && widget.instructions!.isNotEmpty) ...[
                              Text(
                                'التعليمات:',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.instructions!,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary(context),
                                  height: 1.45,
                                ),
                              ),
                            ],
                            if (!hasDetails) ...[
                              Text(
                                'لا توجد بيانات مسجلة.',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: AppColors.textMuted(context),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
