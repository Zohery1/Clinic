// نموذج التشخيص الطبي وملاحظات الزيارة (Visit Note Model)
class VisitNoteModel {
  final String id;
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitNoteModel({
    required this.id,
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitNoteModel.fromJson(Map<String, dynamic> json) {
    return VisitNoteModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
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
      'notes': notes,
    };
  }
}
