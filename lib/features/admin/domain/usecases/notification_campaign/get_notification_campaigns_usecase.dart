import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/notification_campaign_entity.dart';
import '../../repositories/notification_campaign_repository.dart';

class GetNotificationCampaignsUseCase {
  final NotificationCampaignRepository repository;

  GetNotificationCampaignsUseCase(this.repository);

  Future<Either<Failure, List<NotificationCampaignEntity>>> call() =>
      repository.getAll();
}
