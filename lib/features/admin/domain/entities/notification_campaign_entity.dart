import 'package:equatable/equatable.dart';

class NotificationCampaignEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final String audience;
  final String? targetUserId;
  final Map<String, dynamic> data;
  final String? createdBy;
  final int recipientCount;
  final DateTime createdAt;

  const NotificationCampaignEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    this.targetUserId,
    this.data = const {},
    this.createdBy,
    required this.recipientCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        audience,
        targetUserId,
        data,
        createdBy,
        recipientCount,
        createdAt,
      ];
}

class SendCampaignResult extends Equatable {
  final String campaignId;
  final int recipientCount;

  const SendCampaignResult({
    required this.campaignId,
    required this.recipientCount,
  });

  @override
  List<Object?> get props => [campaignId, recipientCount];
}
