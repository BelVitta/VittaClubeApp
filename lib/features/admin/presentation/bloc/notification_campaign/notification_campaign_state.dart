import 'package:equatable/equatable.dart';

import '../../../domain/entities/notification_campaign_entity.dart';

enum NotificationCampaignStatus {
  initial,
  loading,
  loaded,
  sending,
  sent,
  failure,
}

class NotificationCampaignState extends Equatable {
  final NotificationCampaignStatus status;
  final List<NotificationCampaignEntity> items;
  final String? errorMessage;
  final int? lastRecipientCount;

  const NotificationCampaignState({
    this.status = NotificationCampaignStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.lastRecipientCount,
  });

  NotificationCampaignState copyWith({
    NotificationCampaignStatus? status,
    List<NotificationCampaignEntity>? items,
    String? errorMessage,
    int? lastRecipientCount,
  }) {
    return NotificationCampaignState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      lastRecipientCount: lastRecipientCount ?? this.lastRecipientCount,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, lastRecipientCount];
}
