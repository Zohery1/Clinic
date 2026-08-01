class NotificationModel {
  final String id;
  final String clinicId;
  final String title;
  final String body;
  final bool isRead;
  final String? targetRole;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.body,
    required this.isRead,
    this.targetRole,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      targetRole: json['target_role'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'title': title,
      'body': body,
      'is_read': isRead,
      'target_role': targetRole,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? clinicId,
    String? title,
    String? body,
    bool? isRead,
    String? targetRole,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      targetRole: targetRole ?? this.targetRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
