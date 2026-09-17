import '../../domain/entities/notification_campaign_entity.dart';

class NotificationCampaignModel extends NotificationCampaignEntity {
  const NotificationCampaignModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    required super.audience,
    super.targetUserId,
    super.data,
    super.createdBy,
    required super.recipientCount,
    required super.createdAt,
  });

  factory NotificationCampaignModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return NotificationCampaignModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'sistema',
      audience: (json['audience'] as String?) ?? 'user',
      targetUserId: json['target_user_id'] as String?,
      data: data is Map<String, dynamic>
          ? data
          : (data is Map
              ? Map<String, dynamic>.from(data)
              : const <String, dynamic>{}),
      createdBy: json['created_by'] as String?,
      recipientCount: json['recipient_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
