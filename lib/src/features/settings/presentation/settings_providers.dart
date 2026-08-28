import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../clinics/presentation/clinics_controller.dart';

class ClinicSubscriptionInfo {
  final DateTime? endDate;
  final String status;
  final String clinicName;

  ClinicSubscriptionInfo({
    this.endDate,
    required this.status,
    required this.clinicName,
  });
}

final clinicSubscriptionProvider = FutureProvider<ClinicSubscriptionInfo>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return ClinicSubscriptionInfo(status: 'unknown', clinicName: '');
  }
  try {
    final res = await Supabase.instance.client
        .from('clinics')
        .select('name, subscription_end_date, subscription_status')
        .eq('id', user.clinicId)
        .single();

    final endDateStr = res['subscription_end_date'] as String?;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
    final status = (res['subscription_status'] as String? ?? 'active').toLowerCase();
    final clinicName = res['name'] as String? ?? 'العيادة';

    return ClinicSubscriptionInfo(
      endDate: endDate,
      status: status,
      clinicName: clinicName,
    );
  } catch (_) {
    return ClinicSubscriptionInfo(status: 'active', clinicName: 'العيادة');
  }
});

// مزود كود الدعوة
final inviteCodeProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return '';
  return ref.watch(authRepositoryProvider).getClinicInviteCode(user.clinicId);
});

// مزود قائمة الموظفين
final staffListProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final selectedBranchId = ref.watch(selectedBranchFilterProvider);
  final branchId = selectedBranchId ?? (user.isOwner ? null : user.activeBranchId);
  return ref.watch(authRepositoryProvider).getClinicStaff(user.clinicId, branchId: branchId);
});
