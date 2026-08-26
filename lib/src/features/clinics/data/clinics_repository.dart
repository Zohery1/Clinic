import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/branch_model.dart';
import '../domain/clinic_summary_model.dart';

final clinicsRepositoryProvider = Provider<ClinicsRepository>((ref) {
  return ClinicsRepository(Supabase.instance.client);
});

class ClinicsRepository {
  final SupabaseClient _supabase;

  ClinicsRepository(this._supabase);

  // جلب كافة العيادات التي ينتمي إليها المستخدم الحالي مع فروعها
  Future<List<ClinicSummaryModel>> getUserClinics() async {
    try {
      final response = await _supabase.rpc('get_user_clinics');
      if (response == null || response is! List) return [];
      return response
          .map((item) => ClinicSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getUserClinics error: $e');
      return [];
    }
  }

  // التبديل إلى عيادة وفرع محددين
  Future<Map<String, dynamic>> switchActiveClinic({
    required String clinicId,
    String? branchId,
  }) async {
    try {
      final response = await _supabase.rpc('switch_user_active_clinic', params: {
        'p_clinic_id': clinicId,
        'p_branch_id': branchId,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('switchActiveClinic error: $e');
      rethrow;
    }
  }

  // إنشاء عيادة جديدة إضافية للمستخدم وتعيينه كمالك
  Future<Map<String, dynamic>> createNewClinic(String clinicName) async {
    try {
      final response = await _supabase.rpc('create_additional_clinic', params: {
        'p_clinic_name': clinicName,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('createNewClinic error: $e');
      rethrow;
    }
  }

  // الانضمام إلى عيادة إضافية بكود الدعوة
  Future<Map<String, dynamic>> joinClinic(String inviteCode, {String? role}) async {
    try {
      final response = await _supabase.rpc('join_additional_clinic', params: {
        'p_invite_code': inviteCode,
        'p_role': role,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('joinClinic error: $e');
      rethrow;
    }
  }

  // جلب فروع عيادة محددة
  Future<List<BranchModel>> getClinicBranches(String clinicId) async {
    try {
      final response = await _supabase.rpc('get_clinic_branches', params: {
        'p_clinic_id': clinicId,
      });
      if (response == null || response is! List) return [];
      return response
          .map((item) => BranchModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getClinicBranches error: $e');
      return [];
    }
  }

  // إنشاء فرع جديد
  Future<Map<String, dynamic>> createBranch({
    required String clinicId,
    required String name,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    try {
      final response = await _supabase.rpc('create_clinic_branch', params: {
        'p_clinic_id': clinicId,
        'p_name': name,
        'p_address': address,
        'p_phone': phone,
        'p_is_main': isMain,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('createBranch error: $e');
      rethrow;
    }
  }

  // تحديث بيانات فرع
  Future<Map<String, dynamic>> updateBranch({
    required String branchId,
    required String name,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    try {
      final response = await _supabase.rpc('update_clinic_branch', params: {
        'p_branch_id': branchId,
        'p_name': name,
        'p_address': address,
        'p_phone': phone,
        'p_is_main': isMain,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('updateBranch error: $e');
      rethrow;
    }
  }

  // حذف فرع
  Future<Map<String, dynamic>> deleteBranch(String branchId) async {
    try {
      final response = await _supabase.rpc('delete_clinic_branch', params: {
        'p_branch_id': branchId,
      });
      return response as Map<String, dynamic>? ?? {'success': true};
    } catch (e) {
      debugPrint('deleteBranch error: $e');
      rethrow;
    }
  }
}
