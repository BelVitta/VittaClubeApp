import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_preferences_entity.dart';
import '../repositories/notifications_repository.dart';

class UpdateNotificationPreferencesUseCase {
  final NotificationsRepository repository;

  UpdateNotificationPreferencesUseCase(this.repository);

  Future<Either<Failure, NotificationPreferencesEntity>> call(
    NotificationPreferencesEntity preferences,
  ) =>
      repository.updatePreferences(preferences);
}
