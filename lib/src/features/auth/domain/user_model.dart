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
  final UserRole role;
  final String fullName;
  final bool isActive;                     // حالة نشاط الحساب (مفعل/محظور)
  final bool canDeleteAppointments;       // صلاحية حذف المواعيد
  final bool canViewReports;              // صلاحية رؤية التقارير المالية
  final bool canEditServices;             // صلاحية إدخال وتعديل الخدمات والأسعار
  final bool canViewMedicalHistory;       // صلاحية رؤية التقرير الطبي والروشتة
  final bool canCancelAppointments;       // صلاحية إلغاء المواعيد والاعتذار
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.clinicId,
    required this.role,
    required this.fullName,
    required this.isActive,
    required this.canDeleteAppointments,
    required this.canViewReports,
    this.canEditServices = false,
    this.canViewMedicalHistory = false,
    this.canCancelAppointments = true,
    required this.createdAt,
  });

  // تحويل JSON القادم من Supabase إلى Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      role: UserRole.fromString(json['role'] as String),
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      canDeleteAppointments: json['can_delete_appointments'] as bool? ?? false,
      canViewReports: json['can_view_reports'] as bool? ?? false,
      canEditServices: json['can_edit_services'] as bool? ?? false,
      canViewMedicalHistory: json['can_view_medical_history'] as bool? ?? false,
      canCancelAppointments: json['can_cancel_appointments'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // تحويل Model إلى JSON لحفظه أو إرساله
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'role': role.toShortString(),
      'full_name': fullName,
      'is_active': isActive,
      'can_delete_appointments': canDeleteAppointments,
      'can_view_reports': canViewReports,
      'can_edit_services': canEditServices,
      'can_view_medical_history': canViewMedicalHistory,
      'can_cancel_appointments': canCancelAppointments,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
