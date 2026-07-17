// نموذج أنواع الكشوفات (مثل كشف، استشارة) وسعرها الافتراضي
class AppointmentTypeModel {
  final String id;
  final String clinicId;
  final String name;
  final double price;

  AppointmentTypeModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.price,
  });

  factory AppointmentTypeModel.fromJson(Map<String, dynamic> json) {
    return AppointmentTypeModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'name': name,
      'price': price,
    };
  }
}
