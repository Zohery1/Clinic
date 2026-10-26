import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/patient_model.dart';
import '../../../core/utils/arabic_utils.dart';

import '../../auth/presentation/login_controller.dart';
import '../../clinics/presentation/clinics_controller.dart';
import '../../../core/demo/demo_clinical_data.dart';

// مزود مستودع المرضى ليكون متاحاً عبر Riverpod
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(Supabase.instance.client);
});

// مزود لجلب قائمة جميع المرضى في العيادة والفرع الحالي تلقائياً
final patientsListProvider = FutureProvider.family<List<PatientModel>, String>((ref, clinicId) async {
  if (clinicId == 'demo-clinic-01') {
    return DemoClinicalData.patients;
  }
  final user = ref.watch(currentUserProvider);
  final selectedBranchId = ref.watch(selectedBranchFilterProvider);
  // إذا حُدد فرع في الفلتر نستخدمه، وإلا إذا كان المستخدم ليس مالكاً نستخدم فرعه النشط تلقائياً
  final branchId = selectedBranchId ?? (user?.isOwner == true ? null : user?.activeBranchId);
  return ref.watch(patientRepositoryProvider).getPatients(clinicId, branchId: branchId);
});

class PatientRepository {
  final SupabaseClient _supabase;

  PatientRepository(this._supabase);

  // جلب كافة المرضى للعيادة أو الفرع الحالي
  Future<List<PatientModel>> getPatients(String clinicId, {String? branchId}) async {
    try {
      // 1) Primary: Call jsonb RPC to completely bypass PostgREST max-rows table limit
      final dynamic rpcResponse = await _supabase
          .rpc('get_all_patients_json', params: {
            'p_clinic_id': clinicId,
            if (branchId != null) 'p_branch_id': branchId,
          });

      if (rpcResponse is List && rpcResponse.isNotEmpty) {
        return rpcResponse
            .map((item) => PatientModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('getPatients RPC fallback: $e');
    }

    // 2) Fallback: Range chunking loop
    try {
      final List<dynamic> allPatients = [];
      int from = 0;
      const int pageSize = 1000;
      bool hasMore = true;

      while (hasMore) {
        var query = _supabase
            .from('patients')
            .select('*')
            .eq('clinic_id', clinicId);

        if (branchId != null && branchId.isNotEmpty) {
          query = query.eq('branch_id', branchId);
        }

        final List<dynamic> page = await query
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
    String? branchId,
  }) async {
    try {
      final trimmedName = fullName.trim();
      final trimmedPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
      final cleanPhone = trimmedPhone?.replaceAll(RegExp(r'\D'), '');

      // 1) Duplicate check: Reject ONLY if BOTH full_name AND phone match an existing patient in the same clinic
      if (cleanPhone?.isNotEmpty == true && trimmedPhone != null) {
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
            if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
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

  // البحث عن المرضى — فلترة نقية على القائمة المحمّلة في الذاكرة (صفر طلبات شبكة)
  List<PatientModel> searchPatients(List<PatientModel> allPatients, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return allPatients;
    }

    final normQuery = ArabicUtils.normalize(trimmed);
    final List<PatientModel> fastMatches = [];
    final Set<String> matchedIds = {};

    // Stage 1: مطابقة الاسم/الهاتف/العنوان مباشرة
    for (final patient in allPatients) {
      final normName = ArabicUtils.normalize(patient.fullName);
      final phone = patient.phone ?? '';
      final address = patient.address ?? '';

      if (normName.contains(normQuery) ||
          phone.contains(trimmed) ||
          (address.isNotEmpty && address.contains(trimmed))) {
        fastMatches.add(patient);
        matchedIds.add(patient.id);
      }
    }

    // Stage 2: مطابقة تقريبية (tokenSimilarity) فقط إذا كانت النتائج قليلة والاستعلام >= 3 حروف
    if (fastMatches.length < 15 && normQuery.length >= 3) {
      for (final patient in allPatients) {
        if (matchedIds.contains(patient.id)) continue;

        final normName = ArabicUtils.normalize(patient.fullName);
        if (ArabicUtils.tokenSimilarity(normQuery, normName) >= 0.5) {
          fastMatches.add(patient);
          matchedIds.add(patient.id);
          if (fastMatches.length >= 30) break;
        }
      }
    }

    return fastMatches;
  }

  // البحث الذكي عن المرضى المشابهين (Fuzzy Matching) للتحذير ومنع التكرار — فلترة نقية بدون طلبات شبكة
  List<PatientModel> findSimilarPatients(List<PatientModel> allPatients, String name, String? phone) {
    final normInputName = ArabicUtils.normalize(name);
    final cleanPhone = (phone != null && phone.trim().isNotEmpty) ? phone.replaceAll(RegExp(r'\D'), '') : null;

    final List<PatientModel> matches = [];

    for (final patient in allPatients) {
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
  }
}
