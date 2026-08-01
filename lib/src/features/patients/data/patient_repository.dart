import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/patient_model.dart';

// مزود مستودع المرضى ليكون متاحاً عبر Riverpod
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(Supabase.instance.client);
});

// مزود لجلب قائمة جميع المرضى في العيادة الحالية تلقائياً
final patientsListProvider = FutureProvider.family<List<PatientModel>, String>((ref, clinicId) async {
  return ref.watch(patientRepositoryProvider).getPatients(clinicId);
});

class PatientRepository {
  final SupabaseClient _supabase;

  PatientRepository(this._supabase);

  // جلب كافة المرضى للعيادة الحالية مرتبين بالأحدث تسجيلاً
  Future<List<PatientModel>> getPatients(String clinicId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('patients')
          .select('*')
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false);

      return response.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // إضافة تسجيل مريض جديد في قاعدة البيانات
  Future<PatientModel> createPatient({
    required String clinicId,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? medicalHistory,
  }) async {
    try {
      final response = await _supabase
          .from('patients')
          .insert({
            'clinic_id': clinicId,
            'full_name': fullName,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            if (gender != null) 'gender': gender,
            if (birthDate != null) 'birth_date': birthDate.toIso8601String().substring(0, 10),
            if (address != null && address.isNotEmpty) 'address': address,
            if (medicalHistory != null && medicalHistory.isNotEmpty) 'medical_history': medicalHistory,
          })
          .select()
          .single();

      return PatientModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // تعديل بيانات مريض في قاعدة البيانات
  Future<PatientModel> updatePatient({
    required String id,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? birthDate,
    String? address,
    String? medicalHistory,
  }) async {
    try {
      final response = await _supabase
          .from('patients')
          .update({
            'full_name': fullName,
            'phone': (phone != null && phone.isNotEmpty) ? phone : null,
            'gender': gender,
            'birth_date': birthDate?.toIso8601String().substring(0, 10),
            'address': (address != null && address.isNotEmpty) ? address : null,
            'medical_history': (medicalHistory != null && medicalHistory.isNotEmpty) ? medicalHistory : null,
          })
          .eq('id', id)
          .select()
          .single();

      return PatientModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // حذف مريض من قاعدة البيانات (ستحذف مواعيده تلقائياً بفضل الـ Cascade)
  Future<void> deletePatient(String id) async {
    try {
      await _supabase
          .from('patients')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // البحث عن المرضى بالاسم أو بالرقم أو العنوان
  Future<List<PatientModel>> searchPatients(String clinicId, String query) async {
    try {
      if (query.trim().isEmpty) {
        return getPatients(clinicId);
      }

      final List<dynamic> response = await _supabase
          .from('patients')
          .select('*')
          .eq('clinic_id', clinicId)
          .or('full_name.ilike.%$query%,phone.ilike.%$query%')
          .order('full_name', ascending: true);

      return response.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
