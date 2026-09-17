import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_preferences_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationPreferencesUseCase {
  final NotificationsRepository repository;

  GetNotificationPreferencesUseCase(this.repository);

  Future<Either<Failure, NotificationPreferencesEntity>> call() =>
      repository.getPreferences();
}
