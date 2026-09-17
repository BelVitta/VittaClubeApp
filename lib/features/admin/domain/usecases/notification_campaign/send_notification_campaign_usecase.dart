import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/notification_campaign_entity.dart';
import '../../repositories/notification_campaign_repository.dart';

class SendNotificationCampaignUseCase {
  final NotificationCampaignRepository repository;

  SendNotificationCampaignUseCase(this.repository);

  Future<Either<Failure, SendCampaignResult>> call({
    required String title,
    required String body,
    required String type,
    required String audience,
    String? targetUserId,
    Map<String, dynamic> data = const {},
  }) =>
      repository.send(
        title: title,
        body: body,
        type: type,
        audience: audience,
        targetUserId: targetUserId,
        data: data,
      );
}
