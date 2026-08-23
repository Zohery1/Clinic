import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/visit_note_model.dart';

final visitNoteRepositoryProvider = Provider<VisitNoteRepository>((ref) {
  return VisitNoteRepository(Supabase.instance.client);
});

// مزود لجلب ملاحظات موعد معين تلقائياً (مخزن في الذاكرة لتجربة سريعة)
final visitNoteProvider = FutureProvider.family<VisitNoteModel?, String>((ref, appointmentId) async {
  return ref.watch(visitNoteRepositoryProvider).getVisitNote(appointmentId);
});

// مزود لجلب كل ملاحظات المريض التاريخية (مخزن في الذاكرة)
final patientVisitNotesProvider = FutureProvider.family<List<VisitNoteModel>, String>((ref, patientId) async {
  return ref.watch(visitNoteRepositoryProvider).getPatientVisitNotes(patientId);
});

class VisitNoteRepository {
  final SupabaseClient _supabase;

  VisitNoteRepository(this._supabase);

  // جلب ملاحظات الموعد إن وجدت
  Future<VisitNoteModel?> getVisitNote(String appointmentId) async {
    try {
      final data = await _supabase
          .from('visit_notes')
          .select()
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (data == null) return null;
      return VisitNoteModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // حفظ أو تعديل ملاحظات الزيارة
  Future<VisitNoteModel> upsertVisitNote({
    required String clinicId,
    required String appointmentId,
    required String patientId,
    String? doctorId,
    required String notes,
  }) async {
    try {
      final response = await _supabase
          .from('visit_notes')
          .upsert({
            'clinic_id': clinicId,
            'appointment_id': appointmentId,
            'patient_id': patientId,
            if (doctorId != null && doctorId.isNotEmpty) 'doctor_id': doctorId,
            'notes': notes,
          }, onConflict: 'appointment_id')
          .select('*, users!doctor_id(full_name)')
          .single();

      return VisitNoteModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // حذف ملاحظات الزيارة
  Future<void> deleteVisitNote(String appointmentId) async {
    try {
      await _supabase
          .from('visit_notes')
          .delete()
          .eq('appointment_id', appointmentId);
    } catch (e) {
      rethrow;
    }
  }

  // جلب كل ملاحظات المريض التاريخية
  Future<List<VisitNoteModel>> getPatientVisitNotes(String patientId) async {
    try {
      final data = await _supabase
          .from('visit_notes')
          .select('*, users!doctor_id(full_name)')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (data as List).map((x) => VisitNoteModel.fromJson(x)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
