// نموذج الخدمات الإضافية المتاحة بالعيادة وأسعارها (مثل ليزر، خياطة جروح)
class ServiceModel {
  final String id;
  final String clinicId;
  final String name;
  final double price;

  ServiceModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
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
