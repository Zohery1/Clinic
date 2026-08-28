import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../appointments/data/visit_note_repository.dart';
import '../../../../appointments/presentation/visit_notes_dialog.dart';

/// ويدجت داخلي لعرض تقرير الزيارة الطبية وملاحظاتها
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
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
