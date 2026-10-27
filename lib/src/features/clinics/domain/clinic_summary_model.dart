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

  factory ClinicSummaryModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = Map<String, dynamic>.from(rawJson);
    List<BranchModel> parsedBranches = [];
    final rawBranches = json['branches'];
    if (rawBranches is List) {
      for (final b in rawBranches) {
        if (b is Map) {
          final branchMap = Map<String, dynamic>.from(b);
          if (branchMap['clinic_id'] == null || branchMap['clinic_id'].toString().isEmpty) {
            branchMap['clinic_id'] = json['clinic_id']?.toString() ?? '';
          }
          parsedBranches.add(BranchModel.fromJson(branchMap));
        }
      }
    }

    return ClinicSummaryModel(
      clinicId: json['clinic_id']?.toString() ?? '',
      clinicName: json['clinic_name']?.toString() ?? 'العيادة',
      role: UserRole.fromString(json['role']?.toString() ?? 'doctor'),
      isOwner: json['is_owner'] == true,
      isActive: json['is_active'] == true,
      canViewReports: json['can_view_reports'] == true,
      subscriptionStatus: json['subscription_status']?.toString() ?? 'active',
      inviteCode: json['invite_code']?.toString(),
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
