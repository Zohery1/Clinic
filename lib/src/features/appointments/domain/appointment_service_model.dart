// نموذج الخدمات المقدمة فعلياً في زيارة المريض وسعرها المسجل تاريخياً
class AppointmentServiceModel {
  final String id;
  final String clinicId;
  final String appointmentId;
  final String? serviceId;
  final double priceCharged;
  final String? serviceName; // اسم الخدمة المنضم (للعرض)

  AppointmentServiceModel({
    required this.id,
    required this.clinicId,
    required this.appointmentId,
    this.serviceId,
    required this.priceCharged,
    this.serviceName,
  });

  factory AppointmentServiceModel.fromJson(Map<String, dynamic> json) {
    return AppointmentServiceModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      appointmentId: json['appointment_id'] as String,
      serviceId: json['service_id'] as String?,
      priceCharged: (json['price_charged'] as num).toDouble(),
      // معالجة الـ Join لجلب اسم الخدمة من جدول الخدمات الإضافية
      serviceName: json['services'] != null ? (json['services']['name'] as String?) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'appointment_id': appointmentId,
      'service_id': serviceId,
      'price_charged': priceCharged,
    };
  }
}
