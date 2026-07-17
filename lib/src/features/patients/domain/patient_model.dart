// نموذج المريض الخاص بالعيادة (Patient Model)
class PatientModel {
  final String id;
  final String clinicId;
  final String fullName;
  final String? phone;
  final String? gender; // 'male', 'female'
  final DateTime? birthDate;
  final String? address; // عنوان المريض
  final String? medicalHistory; // التاريخ المرضي — عمود منفصل بعد الـ migration
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.clinicId,
    required this.fullName,
    this.phone,
    this.gender,
    this.birthDate,
    this.address,
    this.medicalHistory,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // دعم legacy: إذا لم يكن العمود medical_history موجوداً بعد، نستخرج من address
    final rawAddress = json['address'] as String?;
    String? address;
    String? medicalHistory;

    if (json.containsKey('medical_history')) {
      // الحقل الجديد المنفصل (بعد الـ migration)
      address = rawAddress;
      medicalHistory = json['medical_history'] as String?;
    } else if (rawAddress != null && rawAddress.contains('|')) {
      // legacy: address|medicalHistory
      final parts = rawAddress.split('|');
      address = parts[0].trim().isEmpty ? null : parts[0].trim();
      medicalHistory = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : null;
    } else {
      address = rawAddress;
      medicalHistory = null;
    }

    return PatientModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date'] as String) : null,
      address: address,
      medicalHistory: medicalHistory,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String().substring(0, 10),
      if (address != null) 'address': address,
      if (medicalHistory != null) 'medical_history': medicalHistory,
    };
  }
}
