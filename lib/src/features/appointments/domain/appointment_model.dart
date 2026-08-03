import '../../patients/domain/patient_model.dart';

class AppointmentPatient {
  final String fullName;
  final String? phone;
  final String? address;

  AppointmentPatient({
    required this.fullName,
    this.phone,
    this.address,
  });

  factory AppointmentPatient.fromJson(Map<String, dynamic> json) {
    return AppointmentPatient(
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

// نموذج الحجز والموعد (Appointment Model)
class AppointmentModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String? appointmentTypeId; // نوع الكشف المختار
  final String? appointmentTypeName; // اسم نوع الكشف المختار
  final DateTime appointmentDate;
  final String status; // pending, confirmed, cancelled, completed
  final double? priceCharged; // السعر المسجل فعلياً للحجز لحظة إنشائه
  final AppointmentPatient patient;
  final double totalPaid; // إجمالي المدفوع (الكشف + الخدمات)
  final DateTime? updatedAt;
  final List<String>? serviceNames;

  AppointmentModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.appointmentTypeId,
    this.appointmentTypeName,
    required this.appointmentDate,
    required this.status,
    this.priceCharged,
    required this.patient,
    required this.totalPaid,
    this.updatedAt,
    this.serviceNames,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final appTypeJson = json['appointment_types'] as Map<String, dynamic>?;
    final appTypeName = appTypeJson != null ? appTypeJson['name'] as String? : null;

    final services = json['appointment_services'] as List<dynamic>?;
    double servicesTotal = 0.0;
    List<String> serviceNamesList = [];
    if (services != null) {
      for (var s in services) {
        servicesTotal += (s['price_charged'] as num? ?? 0.0).toDouble();
        if (s['services'] != null && s['services']['name'] != null) {
          serviceNamesList.add(s['services']['name'] as String);
        }
      }
    }
    final basePrice = json['price_charged'] != null ? (json['price_charged'] as num).toDouble() : 0.0;
    final updatedAtStr = json['updated_at'] as String?;

    return AppointmentModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      appointmentTypeId: json['appointment_type_id'] as String?,
      appointmentTypeName: appTypeName,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      status: json['status'] as String,
      priceCharged: basePrice,
      totalPaid: basePrice + servicesTotal,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
      serviceNames: serviceNamesList,
      // معالجة البيانات المنضمة (Join) مع جدول المرضى
      patient: json['patients'] != null
          ? AppointmentPatient.fromJson(json['patients'] as Map<String, dynamic>)
          : AppointmentPatient(fullName: 'مريض غير معروف'),
    );
  }

  PatientModel toPatientModel() {
    return PatientModel(
      id: patientId,
      clinicId: clinicId,
      fullName: patient.fullName,
      phone: patient.phone,
      address: patient.address,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'patient_id': patientId,
      'appointment_type_id': appointmentTypeId,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      'price_charged': priceCharged,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
