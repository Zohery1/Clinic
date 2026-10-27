// رتب المستخدمين المتاحة بالعيادة
enum UserRole {
  doctor,
  secretary;

  // تحويل النص البرمجي إلى رتبة enum
  static UserRole fromString(String value) {
    if (value.toLowerCase() == 'secretary') {
      return UserRole.secretary;
    }
    return UserRole.doctor;
  }

  // تحويل الـ enum لنص مخزن في قاعدة البيانات
  String toShortString() {
    return name;
  }
}

class UserModel {
  final String id;
  final String clinicId;
  final String? activeClinicId;
  final String? activeBranchId;
  final UserRole role;
  final String fullName;
  final String? phone;
  final bool isActive;                     // حالة نشاط الحساب (مفعل/محظور)
  final bool isOwner;                      // هل هو مالك ومدير العيادة؟
  final bool canDeleteAppointments;       // صلاحية حذف المواعيد
  final bool canViewReports;              // صلاحية رؤية التقارير المالية
  final bool canEditServices;             // صلاحية إدخال وتعديل الخدمات والأسعار
  final bool canViewMedicalHistory;       // صلاحية رؤية التقرير الطبي والروشتة
  final bool canEditMedicalNotes;         // صلاحية كتابة وتعديل التقرير الطبي
  final bool canCancelAppointments;       // صلاحية إلغاء المواعيد والاعتذار
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.clinicId,
    this.activeClinicId,
    this.activeBranchId,
    required this.role,
    required this.fullName,
    this.phone,
    required this.isActive,
    this.isOwner = false,
    required this.canDeleteAppointments,
    required this.canViewReports,
    this.canEditServices = false,
    this.canViewMedicalHistory = false,
    this.canEditMedicalNotes = false,
    this.canCancelAppointments = true,
    required this.createdAt,
  });

  // تحويل JSON القادم من Supabase إلى Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      activeClinicId: json['active_clinic_id'] as String? ?? json['clinic_id'] as String?,
      activeBranchId: json['active_branch_id'] as String?,
      role: UserRole.fromString(json['role'] as String),
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isOwner: json['is_owner'] as bool? ?? false,
      canDeleteAppointments: json['can_delete_appointments'] as bool? ?? false,
      canViewReports: json['can_view_reports'] as bool? ?? false,
      canEditServices: json['can_edit_services'] as bool? ?? false,
      canViewMedicalHistory: json['can_view_medical_history'] as bool? ?? false,
      canEditMedicalNotes: json['can_edit_medical_notes'] as bool? ?? false,
      canCancelAppointments: json['can_cancel_appointments'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // تحويل Model إلى JSON لحفظه أو إرساله
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'active_clinic_id': activeClinicId ?? clinicId,
      'active_branch_id': activeBranchId,
      'role': role.toShortString(),
      'full_name': fullName,
      'phone': phone,
      'is_active': isActive,
      'is_owner': isOwner,
      'can_delete_appointments': canDeleteAppointments,
      'can_view_reports': canViewReports,
      'can_edit_services': canEditServices,
      'can_view_medical_history': canViewMedicalHistory,
      'can_edit_medical_notes': canEditMedicalNotes,
      'can_cancel_appointments': canCancelAppointments,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? clinicId,
    String? activeClinicId,
    String? activeBranchId,
    UserRole? role,
    String? fullName,
    String? phone,
    bool? isActive,
    bool? isOwner,
    bool? canDeleteAppointments,
    bool? canViewReports,
    bool? canEditServices,
    bool? canViewMedicalHistory,
    bool? canEditMedicalNotes,
    bool? canCancelAppointments,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      activeClinicId: activeClinicId ?? this.activeClinicId,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      isOwner: isOwner ?? this.isOwner,
      canDeleteAppointments: canDeleteAppointments ?? this.canDeleteAppointments,
      canViewReports: canViewReports ?? this.canViewReports,
      canEditServices: canEditServices ?? this.canEditServices,
      canViewMedicalHistory: canViewMedicalHistory ?? this.canViewMedicalHistory,
      canEditMedicalNotes: canEditMedicalNotes ?? this.canEditMedicalNotes,
      canCancelAppointments: canCancelAppointments ?? this.canCancelAppointments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
