import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.isRead,
    super.readAt,
    required super.createdAt,
    super.action,
    super.professionalId,
    super.professionalName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map<String, dynamic>
        ? data
        : (data is Map
            ? Map<String, dynamic>.from(data)
            : const <String, dynamic>{});

    return NotificationModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'sistema',
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      action: notificationActionFromString(payload['action'] as String?),
      professionalId: payload['professional_id'] as String?,
      professionalName: payload['professional_name'] as String?,
    );
  }
}
