import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/patient_model.dart';
import '../../../core/utils/arabic_utils.dart';

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

  // جلب كافة المرضى للعيادة الحالية مرتبين بالأحدث تسجيلاً (مع دعم الـ Chunking لتخطي حد الـ 1000 مريض الخاص بـ PostgREST)
  Future<List<PatientModel>> getPatients(String clinicId) async {
    try {
      final List<dynamic> allPatients = [];
      int from = 0;
      const int pageSize = 1000;
      bool hasMore = true;

      while (hasMore) {
        final List<dynamic> page = await _supabase
            .from('patients')
            .select('*')
            .eq('clinic_id', clinicId)
            .order('created_at', ascending: false)
            .range(from, from + pageSize - 1);

        allPatients.addAll(page);

        if (page.length < pageSize) {
          hasMore = false;
        } else {
          from += pageSize;
        }
      }

      return allPatients
          .map((item) => PatientModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

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
      final trimmedName = fullName.trim();
      final trimmedPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
      final cleanPhone = trimmedPhone != null ? trimmedPhone.replaceAll(RegExp(r'\D'), '') : null;

      // 1) Duplicate check: Reject ONLY if BOTH full_name AND phone match an existing patient in the same clinic
      if (cleanPhone != null && cleanPhone.isNotEmpty && trimmedPhone != null) {
        final safePhone = trimmedPhone.replaceAll(RegExp(r'[^\d+]'), '');
        final existingBoth = await _supabase
            .from('patients')
            .select('id, full_name, phone')
            .eq('clinic_id', clinicId)
            .ilike('full_name', trimmedName)
            .or('phone.eq.$safePhone,phone.eq.$cleanPhone')
            .maybeSingle();

        if (existingBoth != null) {
          throw 'يوجد مريض آخر مسجل بنفس الاسم ونفس رقم الهاتف في هذه العيادة';
        }
      }

      // 2) Insert patient record
      final response = await _supabase
          .from('patients')
          .insert({
            'clinic_id': clinicId,
            'full_name': trimmedName,
            if (trimmedPhone != null) 'phone': trimmedPhone,
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

  // البحث عن المرضى بالاسم أو بالرقم أو العنوان مع التطبيع العربي
  Future<List<PatientModel>> searchPatients(String clinicId, String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        return getPatients(clinicId);
      }

      final allPatients = await getPatients(clinicId);
      final normQuery = ArabicUtils.normalize(trimmed);

      return allPatients.where((patient) {
        final normName = ArabicUtils.normalize(patient.fullName);
        final phone = patient.phone ?? '';
        final address = patient.address ?? '';

        return normName.contains(normQuery) ||
               ArabicUtils.tokenSimilarity(normQuery, normName) >= 0.5 ||
               phone.contains(trimmed) ||
               address.contains(trimmed);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // البحث الذكي عن المرضى المشابهين (Fuzzy Matching) للتحذير ومنع التكرار
  Future<List<PatientModel>> findSimilarPatients(String clinicId, String name, String? phone) async {
    try {
      final allPatients = await getPatients(clinicId);
      final normInputName = ArabicUtils.normalize(name);
      final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.replaceAll(RegExp(r'\D'), '') : null;

      final List<PatientModel> matches = [];

      for (var patient in allPatients) {
        final normPatientName = ArabicUtils.normalize(patient.fullName);

        // Check similarity (>= 0.65) or substring token match
        final similarity = ArabicUtils.tokenSimilarity(normInputName, normPatientName);
        final isSimilarName = similarity >= 0.65 || (normInputName.length >= 3 && (normPatientName.contains(normInputName) || normInputName.contains(normPatientName)));

        // Check phone match
        bool isPhoneMatch = false;
        if (cleanPhone != null && cleanPhone.isNotEmpty && patient.phone != null) {
          final pCleanPhone = patient.phone!.replaceAll(RegExp(r'\D'), '');
          if (pCleanPhone == cleanPhone || (cleanPhone.length >= 8 && pCleanPhone.endsWith(cleanPhone.substring(cleanPhone.length - 8)))) {
            isPhoneMatch = true;
          }
        }

        if (isSimilarName || isPhoneMatch) {
          matches.add(patient);
        }
      }

      return matches;
    } catch (e) {
      return [];
    }
  }
}
