import 'package:equatable/equatable.dart';

abstract class NotificationCampaignEvent extends Equatable {
  const NotificationCampaignEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationCampaigns extends NotificationCampaignEvent {}

class SendNotificationCampaignRequested extends NotificationCampaignEvent {
  final String title;
  final String body;
  final String type;
  final String audience;
  final String? targetUserId;
  final Map<String, dynamic> data;

  const SendNotificationCampaignRequested({
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    this.targetUserId,
    this.data = const {},
  });

  @override
  List<Object?> get props => [title, body, type, audience, targetUserId, data];
}
