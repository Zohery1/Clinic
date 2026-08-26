class BranchModel {
  final String id;
  final String clinicId;
  final String name;
  final String? address;
  final String? phone;
  final bool isMain;
  final DateTime? createdAt;

  BranchModel({
    required this.id,
    required this.clinicId,
    required this.name,
    this.address,
    this.phone,
    this.isMain = false,
    this.createdAt,
  });

  factory BranchModel.fromJson(Map<dynamic, dynamic> rawJson) {
    final json = Map<String, dynamic>.from(rawJson);
    return BranchModel(
      id: json['id']?.toString() ?? '',
      clinicId: json['clinic_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'الفرع الرئيسي',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      isMain: json['is_main'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'name': name,
      'address': address,
      'phone': phone,
      'is_main': isMain,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  BranchModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? address,
    String? phone,
    bool? isMain,
    DateTime? createdAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isMain: isMain ?? this.isMain,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
