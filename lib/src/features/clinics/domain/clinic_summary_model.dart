import '../../auth/domain/user_model.dart';
import 'branch_model.dart';

class ClinicSummaryModel {
  final String clinicId;
  final String clinicName;
  final UserRole role;
  final bool isOwner;
  final bool isActive;
  final bool canViewReports;
  final String subscriptionStatus;
  final String? inviteCode;
  final List<BranchModel> branches;

  ClinicSummaryModel({
    required this.clinicId,
    required this.clinicName,
    required this.role,
    this.isOwner = false,
    this.isActive = true,
    this.canViewReports = false,
    this.subscriptionStatus = 'active',
    this.inviteCode,
    this.branches = const [],
  });

  BranchModel? get mainBranch {
    if (branches.isEmpty) return null;
    return branches.firstWhere(
      (b) => b.isMain,
      orElse: () => branches.first,
    );
  }

  factory ClinicSummaryModel.fromJson(Map<String, dynamic> json) {
    List<BranchModel> parsedBranches = [];
    if (json['branches'] != null && json['branches'] is List) {
      parsedBranches = (json['branches'] as List)
          .map((b) => BranchModel.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return ClinicSummaryModel(
      clinicId: json['clinic_id'] as String,
      clinicName: json['clinic_name'] as String? ?? 'العيادة',
      role: UserRole.fromString(json['role'] as String? ?? 'doctor'),
      isOwner: json['is_owner'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      canViewReports: json['can_view_reports'] as bool? ?? false,
      subscriptionStatus: json['subscription_status'] as String? ?? 'active',
      inviteCode: json['invite_code'] as String?,
      branches: parsedBranches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinic_id': clinicId,
      'clinic_name': clinicName,
      'role': role.toShortString(),
      'is_owner': isOwner,
      'is_active': isActive,
      'can_view_reports': canViewReports,
      'subscription_status': subscriptionStatus,
      'invite_code': inviteCode,
      'branches': branches.map((b) => b.toJson()).toList(),
    };
  }
}
