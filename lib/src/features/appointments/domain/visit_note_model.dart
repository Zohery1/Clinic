// نموذج التشخيص الطبي وملاحظات الزيارة (Visit Note Model)
class VisitNoteModel {
  final String id;
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String? doctorId;
  final String? doctorName;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitNoteModel({
    required this.id,
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    this.doctorId,
    this.doctorName,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitNoteModel.fromJson(Map<String, dynamic> json) {
    final doctorJson = json['users'] as Map<String, dynamic>?;
    final doctorName = doctorJson != null ? doctorJson['full_name'] as String? : null;

    return VisitNoteModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String?,
      doctorName: doctorName,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      'notes': notes,
    };
  }
}
