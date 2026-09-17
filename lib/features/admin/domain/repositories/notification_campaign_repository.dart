import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_campaign_entity.dart';

abstract class NotificationCampaignRepository {
  Future<Either<Failure, List<NotificationCampaignEntity>>> getAll();

  Future<Either<Failure, SendCampaignResult>> send({
    required String title,
    required String body,
    required String type,
    required String audience,
    String? targetUserId,
    required Map<String, dynamic> data,
  });
}
